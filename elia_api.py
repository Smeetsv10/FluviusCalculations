import requests
import pandas as pd
import matplotlib.pyplot as plt

url = f"https://opendata.elia.be/api/explore/v2.1/catalog/datasets/ods087/records?group_by=datetime%2C%20region%2C%20mostrecentforecast%2C%20dayaheadforecast%2C%20weekaheadforecast&limit=1000&refine=region%3A%22Flemish-Brabant%22&refine=resolutioncode%3A%22PT15M%22&refine=datetime%3A%222025%2F09%22"

response = requests.get(url)
data = response.json()

df = pd.DataFrame(data['results'])

df['datetime'] = pd.to_datetime(df['datetime'])


# Masks
print(df['region'].unique())
region_mask = df['region'] == 'Flemish-Brabant'

# Apply masks
df = df[region_mask]
print(df.head())

# Select some numeric columns to plot
columns_to_plot = df.columns.difference(['datetime', 'region'])

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