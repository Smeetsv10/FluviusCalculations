from classes.myBattery import Battery
from classes.myGridData import GridData
from classes.myEliaData import EliaData
from classes.myHouse import House
from classes.mySolarPanel import SolarPanel
import matplotlib.pyplot as plt
from helper_functions import f_normalize
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import root_mean_squared_error


grid_data = GridData(file_name= 'P1e-2025-7-01-2025-8-24.csv', start_date='2025-07-24', end_date='2025-08-24')
grid_data.visualize_data()

Kwadestraat_6 = House(location="Hoegaarden, Belgium",
                      battery=Battery(max_capacity=0, efficiency=0.95),
                      grid_data=grid_data)

elia_data = EliaData(start_date='2025-07-23', end_date='2025-08-25')
elia_data.load_data(Kwadestraat_6.location)
elia_data.visualize_data()

merged_data = elia_data.combine_data(grid_data)
# Sync data timeframes
house_export = f_normalize(merged_data['export'])
grid_export = f_normalize(merged_data['mostrecentforecast'])

merged_data['hour'] = merged_data['datetime'].dt.hour
merged_data['minute'] = merged_data['datetime'].dt.minute
merged_data['day_of_year'] = merged_data['datetime'].dt.dayofyear
merged_data['weekday'] = merged_data['datetime'].dt.weekday

X = merged_data[['mostrecentforecast', 'hour', 'minute', 'day_of_year', 'weekday']]
y = merged_data['export'] 

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

y_pred = model.predict(X_test)

# Evaluate
rmse = root_mean_squared_error(y_test, y_pred)
print(f'RMSE: {rmse:.2f}')

plt.scatter(y_test, y_pred, alpha=0.5)
plt.xlabel('Actual Grid Export')
plt.ylabel('Predicted Grid Export')
plt.title('Random Forest Predictions')
plt.grid()
plt.show()


# Plot elia and grid data together
plt.figure()
plt.plot(merged_data['datetime'], house_export, label='Power out (-)', color='blue')
plt.plot(merged_data['datetime'], grid_export, label='PV Estimation (-)', color='orange')
plt.title('Grid Data and PV Estimation')
plt.xlabel('Date') 
plt.ylabel('Normalized Value (-)')
plt.legend()
plt.grid()
plt.show()

plt.figure()
plt.plot(grid_export, house_export, '.', alpha=0.5)
plt.title('Scatter Plot of ELIA vs Grid Data')
plt.xlabel('ELIA Data (Normalized)')
plt.ylabel('Grid Data (Normalized)')
plt.grid()
plt.show()

plt.figure()
plt.hist(merged_data['mostrecentforecast'] - merged_data['export'], bins=50, color='purple', alpha=0.7)

# Simulate: no battery
import_energy_history_0, export_energy_history_0 = Kwadestraat_6.simulate_household()
Kwadestraat_6.plot_energy_history()

# Simulate: with battery
Kwadestraat_6.battery = Battery(max_capacity=7.7, efficiency=0.95)
import_energy_history_10, export_energy_history_10 = Kwadestraat_6.simulate_household()
Kwadestraat_6.plot_energy_history()
Kwadestraat_6.battery.plot_SOC()

plt.show()


# Calculate optimal battery capacity
Kwadestraat_6.battery = Battery(max_capacity=10, efficiency=0.95)
capacities, savings, battery_cost = Kwadestraat_6.optimize_battery_capacity()
Kwadestraat_6.plot_energy_history()

plt.figure()
plt.plot(capacities, savings, label='Savings', color='orange')
plt.title('Savings from Battery Storage')
plt.xlabel('Battery Capacity (kWh)')
plt.ylabel('Savings (EUR)')
plt.legend()
plt.grid()
plt.show()

print('Optimal battery capacity (kWh):', Kwadestraat_6.optimal_battery_capacity)