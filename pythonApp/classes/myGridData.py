from urllib import response
import pandas as pd
import os
import matplotlib.pyplot as plt
import requests
from geopy.geocoders import Nominatim


class GridData:
    def __init__(self, file_path=None, start_date=None, end_date=None):
        if file_path is None:
            self.data_folder = os.path.join(os.getcwd(), 'Data', 'gridData')
            self.file_path = os.path.join(self.data_folder, self.file_name)
        else:
            self.file_path = file_path
            self.file_name = os.path.basename(file_path)
        
        self.start_date = start_date
        self.end_date = end_date
        
        # Generate dataframe
        self.df = pd.DataFrame() # (kWh)
        self.load_data()
        self.process_data()
        
    def load_data(self):
        """
        Load smart meter data from CSV file.
        
        Parameters:
        file_path (str, optional): Path to the CSV file. If None, uses self.file_path.
        
        Returns:
        pandas.DataFrame: Raw data from CSV file with time column converted to datetime
        """

        print(f"Loading data from: {self.file_path}")

        # Load the CSV data
        data = pd.read_csv(self.file_path, sep=',')

        # Debug: print column names
        print("Column names:", data.columns.to_list())
        
        # Convert time column to datetime for better processing
        data['datetime'] = pd.to_datetime(data['time'])
        data['datetime'] = data['datetime'].dt.tz_localize('Europe/Brussels')


        # Filter data by stored date range if provided
        if self.start_date is not None:
            data = data[data['datetime'] >= self.start_date]
        if self.end_date is not None:
            data = data[data['datetime'] <= self.end_date]
        
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
        
        # Also keep cumulative totals for comparison
        df['cumulative_import'] = df['Import T1 kWh'] + df['Import T2 kWh']
        df['cumulative_export'] = df['Export T1 kWh'] + df['Export T2 kWh']
        df['cumulative_remaining_energy'] = df['cumulative_import'] - df['cumulative_export']

        # Since values are cumulative, calculate daily differences to get actual daily consumption
        df['import_day'] = df['Import T1 kWh'].diff().fillna(df['Import T1 kWh'].iloc[0])
        df['import_night'] = df['Import T2 kWh'].diff().fillna(df['Import T2 kWh'].iloc[0])
        df['export_day'] = df['Export T1 kWh'].diff().fillna(df['Export T1 kWh'].iloc[0])
        df['export_night'] = df['Export T2 kWh'].diff().fillna(df['Export T2 kWh'].iloc[0])

        # Reset first row of daily_day_import to 0
        df.loc[0, 'import_day'] = 0
        df.loc[0, 'import_night'] = 0
        df.loc[0, 'export_day'] = 0
        df.loc[0, 'export_night'] = 0

        # Calculate total daily import and export
        df['import'] = df['import_day'] + df['import_night']
        df['export'] = df['export_day'] + df['export_night']
        df['remaining_day'] = df['import_day'] - df['export_day']
        df['remaining_night'] = df['import_night'] - df['export_night']
        df['remaining'] = df['import'] - df['export']

        time_vec = df['datetime'].diff().dt.total_seconds().bfill() / 3600
        df['import_power'] = df['import'] / time_vec
        df['export_power'] = df['export'] / time_vec
        df['remaining_power'] = df['remaining'] / time_vec

        # Also keep cumulative totals for comparison
        print("Data processing completed successfully")
        
        self.df = df
        return df

    def visualize_data(self):
        """
        Visualize the processed smart meter data.
        """
        if self.df.empty:
            raise ValueError("Dataframe is empty. Load and process data before visualization.")

        df = self.df

        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        fig.suptitle('Energy Consumption and Production Analysis', fontsize=16, fontweight='bold')

        # Plot 1: Daily Import vs Export Energy (actual daily values)
        axes[0, 0].plot(df['datetime'], df['import'], label='Import', color='blue')
        axes[0, 0].plot(df['datetime'], df['export'], label='Export', color='orange')
        axes[0, 0].set_title('Import vs Export Energy (kWh)')
        axes[0, 0].set_xlabel('Date')
        axes[0, 0].set_ylabel('Energy (kWh)')
        axes[0, 0].legend()
        axes[0, 0].grid(True)

        # Plot 2: Daily Remaining Consumption
        axes[0, 1].plot(df['datetime'], df['remaining'], label='Remaining Consumption', color='black')
        axes[0, 1].fill_between(df['datetime'], df['remaining'], 0, where=(df['remaining'] > 0), color='red', alpha=0.5, label='Excess import power')
        axes[0, 1].fill_between(df['datetime'], df['remaining'], 0, where=(df['remaining'] < 0), color='green', alpha=0.5, label='Excess export power')
        axes[0, 1].set_title('Daily Remaining Consumption (kWh)')
        axes[0, 1].set_xlabel('Date')
        axes[0, 1].set_ylabel('Remaining Consumption (kWh)')
        axes[0, 1].legend()
        axes[0, 1].grid(True)

        # Plot 3: Cumulative Import vs Export (original cumulative values)
        axes[0, 2].plot(df['datetime'], df['cumulative_import'], label='Cumulative Import', color='blue')
        axes[0, 2].plot(df['datetime'], df['cumulative_export'], label='Cumulative Export', color='orange')
        axes[0, 2].plot(df['datetime'], df['cumulative_remaining_energy'], label='Cumulative Remaining', color='green')
        axes[0, 2].set_title('Cumulative Import/Export/Remaining (kWh)')
        axes[0, 2].set_xlabel('Date')
        axes[0, 2].set_ylabel('Cumulative Energy (kWh)')
        axes[0, 2].legend()
        axes[0, 2].grid(True)

        # Plot 4: Import/Export Power
        axes[1, 0].plot(df['datetime'], df['import_power'], label='Import Power', color='blue')
        axes[1, 0].plot(df['datetime'], df['export_power'], label='Export Power', color='orange')
        axes[1, 0].plot(df['datetime'], df['remaining_power'], label='remaining Power', color='green')
        axes[1, 0].set_title('Import/Export/remaining Power')
        axes[1, 0].set_xlabel('Date')
        axes[1, 0].set_ylabel('Power (kW)')
        axes[1, 0].legend()
        axes[1, 0].grid(True)

        # Plot 5: Histogram of remaining Consumption
        axes[1, 1].hist(df['remaining'], bins=30, color='purple', alpha=0.7)
        axes[1, 1].set_title('Histogram of remaining Consumption')
        axes[1, 1].set_xlabel('remaining Consumption (kWh)')
        axes[1, 1].set_ylabel('Frequency')
        axes[1, 1].grid(True)

        # Plot 6: Summary statistics (already present)
        axes[1, 2].axis('off')
        stats_text = f"""DAILY ENERGY STATISTICS

    Average Import: {df['import'].mean():.2f} kWh
    Average Export: {df['export'].mean():.2f} kWh
    Average remaining Consumption: {df['remaining'].mean():.2f} kWh

    Max Import: {df['import'].max():.2f} kWh
    Max Export: {df['export'].max():.2f} kWh

    Min Import: {df['import'].min():.2f} kWh
    Min Export: {df['export'].min():.2f} kWh

    Total Period Import: {df['import'].sum():.2f} kWh
    Total Period Export: {df['export'].sum():.2f} kWh
    Total Period remaining Consumption: {df['remaining'].sum():.2f} kWh

    Days with remaining Import: {(df['remaining'] > 0).sum()}
    Days with remaining Export: {(df['remaining'] < 0).sum()}
    """
        axes[1, 2].text(0.1, 0.9, stats_text, transform=axes[1, 2].transAxes, 
                        fontsize=10, verticalalignment='top', fontfamily='monospace',
                        bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.5))

        plt.tight_layout()

        return fig
    