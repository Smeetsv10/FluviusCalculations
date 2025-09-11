from classes.myBattery import Battery
from classes.myGridData import GridData
from classes.myEliaData import EliaData
from classes.myHouse import House
from classes.mySolarPanel import SolarPanel
from classes.myFluviusData import FluviusData
import matplotlib.pyplot as plt
from helper_functions import f_normalize
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import root_mean_squared_error, accuracy_score
from sklearn.linear_model import LogisticRegression, LinearRegression
import numpy as np

START_DATE = '2024-01-01'
END_DATE = '2025-01-01'

# grid_data = GridData(file_name= 'P1e-2025-7-01-2025-8-24.csv', start_date='2025-07-01', end_date='2025-08-24')
grid_data = FluviusData(start_date=START_DATE, end_date=END_DATE)
grid_data.visualize_data()

# Kwadestraat_6 = House(location="Hoegaarden, Belgium",
#                       battery=Battery(max_capacity=7, efficiency=0.95),
#                       grid_data=grid_data)
Kwadestraat_6 = House( battery=Battery(max_capacity=0, efficiency=0.95),
                      grid_data=grid_data)

# elia_data = EliaData(start_date=START_DATE, end_date=END_DATE)
# elia_data.load_data(Kwadestraat_6.location)
# elia_data.visualize_data()
# Kwadestraat_6.elia_data = elia_data

# Simulate: no battery
import_energy_history_0, export_energy_history_0 = Kwadestraat_6.simulate_household()
Kwadestraat_6.plot_energy_history()

# Simulate: with battery (dynamic algorithm)
Kwadestraat_6.battery = Battery(max_capacity=3, efficiency=0.95)
Kwadestraat_6.battery_management_system = Kwadestraat_6.dynamic_battery_management_system
import_energy_history_10, export_energy_history_10 = Kwadestraat_6.simulate_household()
Kwadestraat_6.plot_energy_history()
Kwadestraat_6.battery.plot_SOC()

# Calculate optimal battery capacity
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