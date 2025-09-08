from classes.myBattery import Battery
from lib.classes.myGridData import GridData
from classes.myHouse import House
from classes.mySolarPanel import SolarPanel
import matplotlib.pyplot as plt

grid_data = GridData(file_name= 'P1e-2025-7-01-2025-8-24.csv', start_date='2025-07-24', end_date='2025-08-24')
grid_data.visualize_data()

Kwadestraat_6 = House(location="Hoegaarden, Belgium",
                      battery=Battery(max_capacity=0, efficiency=0.95),
                      grid_data=grid_data)

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