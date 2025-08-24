from classes.myBattery import Battery
from classes.myGridDate import GridData
from classes.myHouse import House
from classes.mySolarPanel import SolarPanel
import matplotlib.pyplot as plt

grid_data = GridData(file_name= 'P1e-2025-7-01-2025-8-24.csv')
grid_data.visualize_data()

Kwadestraat_6 = House(location="Hoegaarden, Belgium",
                      battery=Battery(max_capacity=0, efficiency=0.95),
                      grid_data=grid_data)

# Simulate: no battery
Kwadestraat_6.simulate_household()
Kwadestraat_6.plot_energy_history()

# Simulate: with battery
Kwadestraat_6.battery = Battery(max_capacity=10, efficiency=0.95)
Kwadestraat_6.simulate_household()

# Calculate optimal battery capacity
Kwadestraat_6.battery = Battery(max_capacity=10, efficiency=0.95)
Kwadestraat_6.optimize_battery_capacity(max_capacity_kwh=20)
Kwadestraat_6.plot_energy_history()

plt.show()