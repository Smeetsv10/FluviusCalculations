import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from classes.myBattery import Battery
from classes.mySolarPanel import SolarPanels
from scipy.optimize import minimize_scalar

class House:
    def __init__(self, location='', battery=None, solar_panels=None, injection_price=0.04, price_per_kWh=0.35, grid_data=None, climate_data=None):
        self.location = location
        self.battery = battery if battery is not None else Battery(max_capacity=10, efficiency=0.95)
        self.solar_panels = solar_panels if solar_panels is not None else SolarPanels()
        self.injection_price = injection_price # (eur/kWh)
        self.price_per_kWh = price_per_kWh # (eur/kWh)
        self.grid_data = grid_data if grid_data is not None else pd.DataFrame()
        self.climate_data = climate_data if climate_data is not None else pd.DataFrame()
        
        # Variables
        self.import_energy = 0 # Energy consumed at current time instance (kWh)
        self.export_energy = 0 # Energy produced at current time instance (kWh)

        self.import_energy_history = []
        self.export_energy_history = []

        self.remaining_energy = self.calculate_remaining_energy()
        self.remaining_energy_history = self.calculate_remaining_energy_history()

        self.import_cost = 0
        self.export_revenue = 0
        self.energy_cost = 0 # (eur)

        self.optimal_battery_capacity = 0

    def calculate_remaining_energy(self):
        """
        Calculate remaining energy using current import and export energy values.
        """
        return self.import_energy - self.export_energy
    
    def calculate_remaining_energy_history(self):
        """
        Calculate remaining energy using current import and export energy values.
        """
        return list(np.array(self.import_energy_history) - np.array(self.export_energy_history))

    def simulate_household(self):
        df = self.grid_data.df
        time_values = df['time'].values
        time_hours = (time_values - time_values[0]) / np.timedelta64(1, 'h')
        
        for k in range(len(time_hours)):
            t_k = time_hours[k]

            self.import_energy = df['import'].values[k] # Energy injected from the net (kWh)
            self.export_energy = df['export'].values[k] # Energy exported to the grid (solar) (kWh)
            self.remaining_energy = df['remaining'].values[k] # Energy required = Energy net - Energy solar (kWh)
            
            # Battery management
            remaining_required = 0
            remaining_excess = 0
            if self.remaining_energy > 0:
                # Discharge battery
                released_energy = self.battery.release_energy(self.remaining_energy)
                remaining_required = self.remaining_energy - released_energy
                if remaining_required < 0:
                    raise ValueError("Released energy from battery exceeds remaining required energy.")
                self.energy_cost += remaining_required*self.price_per_kWh  
                self.import_cost += remaining_required*self.price_per_kWh        
            else:
                # Charge battery
                stored_energy = self.battery.store_energy(-self.remaining_energy)
                remaining_excess = -self.remaining_energy - stored_energy
                if remaining_excess < 0:
                    raise ValueError("Stored energy exceeds remaining excess energy.")
                self.energy_cost -= remaining_excess * self.injection_price
                self.export_revenue += remaining_excess * self.injection_price

            print('Battery State of Charge (SOC):', self.battery.SOC)
            
            # Save history
            self.import_energy_history.append(remaining_required)
            self.export_energy_history.append(remaining_excess)
            

    def optimize_battery_capacity(self, max_capacity_kwh=20):
        total_cost_array = []
        no_points = 50
        capacity_array = np.linspace(0, max_capacity_kwh, no_points)

        df = self.grid_data.df
        time_values = df['time'].values
        time_span = (time_values[-1] - time_values[0]) / np.timedelta64(1, 'D')  # Time span in days
        for capacity in capacity_array:
            self.battery = Battery(max_capacity=capacity)
            self.simulate_household()
            total_cost = (self.energy_cost/time_span)*365 + self.battery.battery_cost / self.battery.battery_lifetime
            total_cost_array.append(total_cost)

        savings_list = -(total_cost_array - total_cost_array[0])
        optimal_idx = np.argmax(savings_list)
        self.optimal_battery_capacity = capacity_array[optimal_idx]
        self.battery = Battery(max_capacity=self.optimal_battery_capacity)
        self.simulate_household()

        return savings_list

    def plot_energy_history(self):
        df = self.grid_data.df
        time_values = df['time'].values
        
        plt.figure(figsize=(12, 6))
        plt.plot(time_values,self.import_energy_history, label='Import Energy (kWh)', color='red')
        plt.plot(time_values,self.export_energy_history, label='Export Energy (kWh)', color='green')
        plt.title('Energy History')
        plt.xlabel('Time (hours)')
        plt.ylabel('Energy (kWh)')
        plt.legend()
        plt.grid()
        return
