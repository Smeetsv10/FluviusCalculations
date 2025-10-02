from urllib import response
import pandas as pd
import os
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import requests
from geopy.geocoders import Nominatim
import random
import numpy as np

class FluviusData:
    def __init__(self, file_path=None, start_date=None, end_date=None):
        if file_path is not None:
            self.file_path = file_path
            self.file_name = os.path.basename(file_path)
        
        self.flag_EV = True  # Only keep users with no Electric Vehicle (EV) charging points
        self.flag_PV = True  # Only keep users with no Photovoltaic (PV) panels
        self.EAN_ID = -1  # Specific user ID to filter data for (None means random)
        
        self.start_date = start_date
        self.end_date = end_date
        
        # Generate dataframe
        self.df = pd.DataFrame() # (kWh)
        self.df_raw = pd.DataFrame() # (kWh)
        self.df_raw_file_path = None
    
    # === Functions to load and process data ===
    def set_file_path(self, file_path):
        self.file_path = file_path
        self.file_name = os.path.basename(file_path)
        if not self.df_raw_file_path == self.file_path:
            self.df_raw_file_path = self.file_path

    def load_csv(self):
        print(f"Loading data from: {self.file_path}")
        data = pd.read_csv(self.file_path, sep=',')
        return data

    def apply_data_flags(self, data):
        # Only keep users with correct EV indicator
        data = data[data['Elektrisch_Voertuig_Indicator'] == self.flag_EV]
        # Only keep users with correct PV indicator
        data = data[data['PV_Installatie_Indicator'] == self.flag_PV]

        # Choose a  EAN_ID
        if self.EAN_ID != -1:
             chosen_ean = self.EAN_ID
        else:
            unique_ean_ids = data['EAN_ID'].unique()
            chosen_ean = random.choice(unique_ean_ids)
        print(f"Chosen EAN_ID: {chosen_ean}")
        # Filter data for the chosen EAN_ID
        data = data[data['EAN_ID'] == chosen_ean].reset_index(drop=True)

        return data
    
    def filter_data_by_date(self, data):
        # Create temporary Timestamps for filtering
        start_dt = pd.to_datetime(self.start_date).tz_localize('Europe/Brussels') if self.start_date is not None else None
        end_dt = pd.to_datetime(self.end_date).tz_localize('Europe/Brussels') if self.end_date is not None else None

        # Sort datetime for safe filtering
        data = data.sort_values('datetime').reset_index(drop=True)

        # Filter by start_date
        if start_dt is not None:
            if start_dt < data['datetime'].min() or start_dt > data['datetime'].max():
                print(f"Warning: start_date {start_dt.date()} is outside data range. Using {data['datetime'].min().date()} as start.")
                start_dt = data['datetime'].min()
                self.start_date = start_dt.date().isoformat()
            data = data[data['datetime'] >= start_dt]

        # Filter by end_date
        if end_dt is not None:
            if end_dt > data['datetime'].max() or end_dt < data['datetime'].min():
                print(f"Warning: end_date {end_dt.date()} is outside data range. Using {data['datetime'].max().date()} as end.")
                end_dt = data['datetime'].max()
                self.end_date = end_dt.date().isoformat()
            data = data[data['datetime'] <= end_dt]

        return data

    def load_data(self):
        """
        Load smart meter data from CSV file.
        
        Parameters:
        file_path (str, optional): Path to the CSV file. If None, uses self.file_path.
        
        Returns:
        pandas.DataFrame: Raw data from CSV file with time column converted to datetime
        """
        
        # Check if raw data is already loaded
        if not self.df_raw_file_path == self.file_path:
            print("Loading new raw data from file...")
            data = self.load_csv()
            self.df_raw = data
            self.df_raw_file_path = self.file_path
            print(f"Raw data loaded with {len(data)} rows.")
            
        else:
            data = self.df_raw
            print("Raw data already loaded. Skipping reload.")

        data = self.apply_data_flags(data) # Only applies for open data Fluvius
    
        # Convert time column to datetime for better processing
        data['datetime'] = pd.to_datetime(data['Datum_Startuur'])           # CET format
        data['datetime'] = data['datetime'].dt.tz_convert('Europe/Brussels')  # Convert to Brussels time

        data = self.filter_data_by_date(data)
        
        # Reset index after filtering
        data = data.reset_index(drop=True)

        self.df = data
        
        return data

    def process_data(self):
        """
        Process raw smart meter data to calculate daily consumption/production values.
        
        Parameters:
        data (pandas.DataFrame): Raw smart meter data
        
        Returns:
        pandas.DataFrame: Processed data with daily values and calculated totals
        """
        if self.df.empty:
            raise ValueError("Dataframe is empty. Load data before processing.")
        
        print("Processing smart meter data...")
        
        # Copy datastruct
        df = self.df.copy()
        
        # Remove nan rows
        df.dropna(inplace=True)

        # Sort by time and reset index
        df = df.sort_values('datetime').reset_index(drop=True)

        self.start_date = df['datetime'].min()
        self.end_date = df['datetime'].max()
        print(f"Data date range: {self.start_date} to {self.end_date}")
        
        df['import'] = df['Volume_Afname_KWh']  # Import kWh
        df['export'] = df['Volume_Injectie_KWh']  # Export kWh
        df['remaining'] = df['import'] - df['export']
        
        # Also keep cumulative totals for comparison
        df['cumulative_import'] = np.cumsum(df['import'])
        df['cumulative_export'] = np.cumsum(df['export'])
        df['cumulative_remaining_energy'] = df['cumulative_import'] - df['cumulative_export']

        time_vec = df['datetime'].diff().dt.total_seconds().bfill() / 3600
        df['import_power'] = df['import'] / time_vec
        df['export_power'] = df['export'] / time_vec
        df['remaining_power'] = df['remaining'] / time_vec

        # Also keep cumulative totals for comparison
        print("Data processing completed successfully")
        
        # Only keep relevant columns
        df = df[['datetime', 'import', 'export', 'remaining',
                 'cumulative_import', 'cumulative_export', 'cumulative_remaining_energy',
                 'import_power', 'export_power', 'remaining_power']]    
        self.df = df
        return df

    def visualize_data_all(self):
        """
        Create a Matplotlib figure for Flet web.
        Returns a Matplotlib Figure object without blocking the GUI.
        """
        if self.df.empty:
            raise ValueError("Dataframe is empty. Load and process data first.")

        df = self.df
        
        # Reduce figure size for web display
        fig, axes = plt.subplots(2, 3, figsize=(12, 8))
        fig.suptitle("Energy Consumption and Production Analysis", fontsize=14, fontweight='bold')

        # Plot 1: Daily Import vs Export
        axes[0, 0].plot(df['datetime'], df['import'], color='blue', label='Import')
        axes[0, 0].plot(df['datetime'], df['export'], color='orange', label='Export')
        axes[0, 0].set_title("Import vs Export (kWh)")
        axes[0, 0].legend()
        axes[0, 0].grid(True)

        # Plot 2: Daily Remaining
        axes[0, 1].plot(df['datetime'], df['remaining'], color='black', label='Remaining')
        axes[0, 1].fill_between(df['datetime'], df['remaining'], 0,
                                where=(df['remaining'] > 0), color='red', alpha=0.3)
        axes[0, 1].fill_between(df['datetime'], df['remaining'], 0,
                                where=(df['remaining'] < 0), color='green', alpha=0.3)
        axes[0, 1].set_title("Remaining Consumption (kWh)")
        axes[0, 1].legend()
        axes[0, 1].grid(True)

        # Plot 3: Cumulative
        axes[0, 2].plot(df['datetime'], df['cumulative_import'], color='blue', label='Cumulative Import')
        axes[0, 2].plot(df['datetime'], df['cumulative_export'], color='orange', label='Cumulative Export')
        axes[0, 2].plot(df['datetime'], df['cumulative_remaining_energy'], color='green', label='Cumulative Remaining')
        axes[0, 2].set_title("Cumulative (kWh)")
        axes[0, 2].legend()
        axes[0, 2].grid(True)

        # Plot 4: Power
        axes[1, 0].plot(df['datetime'], df['import_power'], color='blue', label='Import Power')
        axes[1, 0].plot(df['datetime'], df['export_power'], color='orange', label='Export Power')
        axes[1, 0].plot(df['datetime'], df['remaining_power'], color='green', label='Remaining Power')
        axes[1, 0].set_title("Power (kW)")
        axes[1, 0].legend()
        axes[1, 0].grid(True)

        # Plot 5: Histogram of Remaining
        axes[1, 1].hist(df['remaining'], bins=20, color='purple', alpha=0.6)
        axes[1, 1].set_title("Remaining Consumption Histogram")
        axes[1, 1].grid(True)

        # Plot 6: Summary statistics
        axes[1, 2].axis('off')
        stats_text = (
            f"Avg Import: {df['import'].mean():.2f} kWh\n"
            f"Avg Export: {df['export'].mean():.2f} kWh\n"
            f"Avg Remaining: {df['remaining'].mean():.2f} kWh\n"
            f"Max Import: {df['import'].max():.2f} kWh\n"
            f"Max Export: {df['export'].max():.2f} kWh\n"
            f"Total Import: {df['import'].sum():.2f} kWh\n"
            f"Total Export: {df['export'].sum():.2f} kWh\n"
            f"Total Remaining: {df['remaining'].sum():.2f} kWh"
        )
        axes[1, 2].text(0.1, 0.5, stats_text, fontsize=10, fontfamily='monospace', verticalalignment='center')

        plt.subplots_adjust(hspace=0.4, wspace=0.3)

        return fig

    def visualize_data(self):
        """
        Create a Matplotlib figure with two subplots:
        1. Daily Import vs Export
        2. Daily Remaining
        X-axis shows day numbers, and full date on the first day of each month.
        Vertical line at each new day.
        """
        if self.df.empty:
            raise ValueError("Dataframe is empty. Load and process data first.")

        df = self.df

        fig, axes = plt.subplots(2, 1, figsize=(12, 6), sharex=True)

        # Generate daily boundaries
        daily_boundaries = pd.date_range(start=df['datetime'].dt.floor('D').min(),
                                        end=df['datetime'].dt.floor('D').max(),
                                        freq='D')

        # --- Plot 1: Import vs Export ---
        axes[0].plot(df['datetime'], df['import'], color='blue', label='Import')
        axes[0].plot(df['datetime'], df['export'], color='orange', label='Export')
        axes[0].set_title("Import vs Export (kWh)")
        axes[0].legend()
        axes[0].grid(True, which='both', axis='both', linestyle='--', alpha=0.5)

        # --- Plot 2: Remaining ---
        axes[1].plot(df['datetime'], df['remaining'], color='black', label='Remaining')
        axes[1].fill_between(df['datetime'], df['remaining'], 0,
                            where=(df['remaining'] > 0), color='red', alpha=0.3)
        axes[1].fill_between(df['datetime'], df['remaining'], 0,
                            where=(df['remaining'] < 0), color='green', alpha=0.3)
        axes[1].set_title("Remaining Consumption (kWh)")
        axes[1].legend()
        axes[1].grid(True, which='both', axis='both', linestyle='--', alpha=0.5)

        # Add vertical lines for each day
        for day in daily_boundaries:
            axes[0].axvline(day, color='gray', linestyle='--', alpha=0.3)
            axes[1].axvline(day, color='gray', linestyle='--', alpha=0.3)

        # X-axis: day numbers and full date on first of month
        xticks = []
        xticklabels = []
        for day in daily_boundaries:
            xticks.append(day)
            if day.day == 1:
                xticklabels.append(day.strftime('%Y-%m-%d'))  # full date for first day of month
            else:
                xticklabels.append(str(day.day))  # day number for other days

        axes[1].set_xticks(xticks)
        axes[1].set_xticklabels(xticklabels, rotation=45, ha='right')

        plt.tight_layout()
        return fig