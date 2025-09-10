import requests
import pandas as pd
import matplotlib.pyplot as plt
from geopy.geocoders import Nominatim

class EliaData:
    def __init__(self, start_date=None, end_date=None):
        self.df = pd.DataFrame() # (MW)
        self.start_date = start_date
        self.end_date = end_date
        self.api_url = f"https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods087/exports/json" # Photovoltaic power production estimation and forecast on Belgian grid (Near real-time)
        self.api_url_historical = f"https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods032/exports/json?where=datetime>='{self.start_date}' AND datetime<='{self.end_date}'" # Photovoltaic power production estimation and forecast on Belgian grid (Historical)
        self.region = None
    
    def load_data(self, location_name):
        print("Retrieving data from Elia API...")  # Show wait message
        # response = requests.get(self.api_url)
        response = requests.get(self.api_url_historical)
        print("Data received, processing...")      # Show progress
        data = response.json()

        df = pd.DataFrame(data)

        df['datetime'] = pd.to_datetime(df['datetime'])
        df['datetime'] = df['datetime'].dt.tz_convert('Europe/Brussels')
        
        geolocator = Nominatim(user_agent="belgium_region_mapper")
        location = geolocator.geocode(location_name, language="en")
        if location:
            # Reverse geocode to get detailed address info
            reverse = geolocator.reverse((location.latitude, location.longitude), language="en")
            address = reverse.raw['address']

            # Extract province (state in OSM terms)
            province = address.get("state", "")
            region = address.get("region", "")
            country = address.get("country", "")

            possible_regions = list(df["region"].unique())
            print(f"\nDetected region: {region}")
            print("Possible regions in the data:")
            for idx, reg in enumerate(possible_regions, start=1):
                print(f"  {idx}. {reg}")

            user_response = input(
                f"\nDo you want to use the detected region '{region}'? [y/n] or enter the number of your choice: "
            )

            if user_response.lower() == 'y':
                region_mask = df['region'] == region
                df = df[region_mask]
                print(f"Data filtered for region: {region}")
            elif user_response.lower() == 'n':
                selection = input("Enter the number corresponding to your choice: ")
                try:
                    selected_region = possible_regions[int(selection) - 1]
                    region_mask = df['region'] == selected_region
                    df = df[region_mask]
                    print(f"Data filtered for region: {selected_region}")
                    self.region = selected_region
                except (IndexError, ValueError):
                    print("Invalid selection. No data filtered.")
                    return None
            elif user_response.isdigit():
                try:
                    selected_region = possible_regions[int(user_response) - 1]
                    region_mask = df['region'] == selected_region
                    df = df[region_mask]
                    print(f"Data filtered for region: {selected_region}")
                    self.region = selected_region
                except (IndexError, ValueError):
                    print("Invalid selection. No data filtered.")
                    return None
            else:
                print("Invalid input. No data filtered.")
                return None

            if not user_response.isdigit() and user_response.lower() == 'y':
                self.region = region
        else:
            print(f"Location '{location_name}' not found.")
            return None

        # Only keep relevant columns and sort on ascending dates
        df = df[['datetime', 'region', 'mostrecentforecast', 'dayaheadforecast', 'weekaheadforecast' ]]
        df = df.sort_values(by='datetime', ascending=True).reset_index(drop=True)
        self.df = df
        return df
    
    def combine_data(self, grid_data=None):
        if self.df.empty:
            print("Dataframe is empty. Please load data first.")
            return None
        # Further processing can be added here if needed
        if grid_data is not None:
            # Example: Merge with grid data
            merged = pd.merge(
                    self.df, 
                    grid_data.df, 
                    on='datetime', 
                    how='inner',    # ensures intersection only
                    suffixes=('_elia', '_grid')
                )
            return merged
    
    
    def visualize_data(self):
        if self.df.empty:
            print("Dataframe is empty. Please load data first.")
            return None
        
        
        plt.figure(figsize=(12,6))
        for col in self.df.columns.difference(['datetime', 'region']):
            plt.plot(self.df['datetime'], self.df[col], label=col)

        plt.xlabel('Datetime')
        plt.ylabel('Forecast')
        plt.title(f'Electricity Forecasts for {self.region}')
        plt.legend()
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()
        
        return plt.gcf()    