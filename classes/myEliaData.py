import requests
import pandas as pd
import matplotlib.pyplot as plt
from geopy.geocoders import Nominatim

class EliaData:
    def __init__(self):
        self.df = pd.DataFrame()
        self.api_url = "https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods087/exports/json"
        self.region = None
    
    def load_data(self, location_name):
        response = requests.get(self.api_url)
        data = response.json()

        df = pd.DataFrame(data)

        df['datetime'] = pd.to_datetime(df['datetime'], utc=True)
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

            user_response = input(f'Confirm region [y/n]: {region}. (Possible regions are: {df["region"].unique()})')
            if user_response.lower() == 'y':
                region_mask = df['region'] == region
                df = df[region_mask]
                print(f"Data filtered for region: {region}")
            else:
                print("Select region manually from the following options:")
                for idx, reg in enumerate(df["region"].unique(), start=1):
                    print(f"  {idx}. {reg}")
                selection = input("Enter the number corresponding to your choice: ")
                try:    
                    selected_region = df["region"].unique()[int(selection) - 1]
                    region_mask = df['region'] == selected_region
                    df = df[region_mask]
                    print(f"Data filtered for region: {selected_region}")
                except (IndexError, ValueError):
                    print("Invalid selection. No data filtered.")
                    return None
                
            self.region = region
        else:
            print(f"Location '{location_name}' not found.")
            return None

        # Only keep relevant columns
        df = df[['datetime', 'region', 'mostrecentforecast', 'dayaheadforecast', 'weekaheadforecast', 'realtime']]
        self.df = df
        return df
    
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