import requests
import pandas as pd
import matplotlib.pyplot as plt
from geopy.geocoders import Nominatim

url = f"https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods087/records?group_by=datetime%2C%20region%2C%20mostrecentforecast%2C%20dayaheadforecast%2C%20weekaheadforecast&limit=1000&refine=region%3A%22Flemish-Brabant%22&refine=resolutioncode%3A%22PT15M%22&refine=datetime%3A%222025%2F09%22"
url = f"https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods087/exports/json"

response = requests.get(url)
data = response.json()

df = pd.DataFrame(data)

df['datetime'] = pd.to_datetime(df['datetime'], utc=True)
df['datetime'] = df['datetime'].dt.tz_convert('Europe/Brussels')

# Masks
print(df['region'].unique())
region_mask = df['region'] == 'Flemish-Brabant'

# Apply masks
geolocator = Nominatim(user_agent="belgium_region_mapper")
location_name = "Hoegaarden, Belgium"
location = geolocator.geocode(location_name, language="en")
if location:
    # Reverse geocode to get detailed address info
    reverse = geolocator.reverse((location.latitude, location.longitude), language="en")
    address = reverse.raw['address']

    # Extract province (state in OSM terms)
    province = address.get("state", "")
    region = address.get("region", "")
    country = address.get("country", "")

    print("Full address:", address)
    print("Province:", province)
    print("Region:", region)
    print("Country:", country)
    
df = df[region_mask]
print(df.head())

# Select some numeric columns to plot
columns_to_plot = {'mostrecentforecast', 'dayaheadforecast', 'weekaheadforecast', 'realtime'}
columns_to_plot = {'mostrecentforecast', 'realtime'}

# Plot
plt.figure(figsize=(12,6))
for col in columns_to_plot:
    plt.plot(df['datetime'], df[col], label=col)

plt.xlabel('Datetime')
plt.ylabel('Forecast')
plt.title('Electricity Forecasts')
plt.legend()
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()