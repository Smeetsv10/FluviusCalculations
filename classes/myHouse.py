import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from classes.myBattery import Battery
from classes.mySolarPanel import SolarPanels
from classes.myEliaData import EliaData
from classes.myGridData import GridData
from classes.myClimateData import ClimateData
import cvxpy as cp
import numpy as np
from scipy.optimize import minimize

class House:
    def __init__(self, location='', battery=None, solar_panels=None, injection_price=0.04, price_per_kWh=0.35, grid_data=None, elia_data=None, climate_data=None):
        self.location = location
        self.battery = battery if battery is not None else Battery(max_capacity=10, efficiency=0.95)
        self.solar_panels = solar_panels if solar_panels is not None else SolarPanels()
        self.injection_price = injection_price # (eur/kWh)
        self.price_per_kWh = price_per_kWh # (eur/kWh)
        self.grid_data = grid_data if grid_data is not None else GridData()
        self.elia_data = elia_data if elia_data is not None else EliaData()
        self.climate_data = climate_data if climate_data is not None else ClimateData()

        # Variables
        self.import_energy_history = []
        self.export_energy_history = []
        self.import_cost = 0 # Cost for importing energy in gridData (eur)
        self.export_revenue = 0 # Revenue for exporting energy to the grid in gridData(eur)
        self.energy_cost = 0 # import_cost - export_revenue (eur)

        self.optimal_battery_capacity = 0

    def remaining_energy_history(self):
       return list(np.array(self.import_energy_history) - np.array(self.export_energy_history))

    def battery_management_system(self, remaining_energy, current_time):
        return self.dynamic_battery_management_system(remaining_energy, current_time)
        return self.greedy_battery_management_system(remaining_energy)
    
    def greedy_battery_management_system(self, remaining_energy, current_time):
        released_energy, stored_energy = 0, 0
        if remaining_energy > 0:
            # Discharge battery
            released_energy = self.battery.release_energy(remaining_energy)
        else:
            # Charge battery
            stored_energy = self.battery.store_energy(-remaining_energy)
        return released_energy, stored_energy

    def dynamic_battery_management_system(self, remaining_energy, current_time):
        # Next step: predictive control
        # Use previous day as a reference
        released_energy, stored_energy = 0, 0

        # If surplus -> charge
        if remaining_energy <= 0:
            stored_energy = self.battery.store_energy(-remaining_energy)

        # If deficit and SOC > reserve threshold -> discharge
        elif remaining_energy > 0 and self.battery.SOC > self.battery.reserve_soc(current_time):
            released_energy = self.battery.release_energy(remaining_energy)

        # If deficit and SOC ≤ reserve -> cautious strategy
        elif remaining_energy > 0 and self.battery.SOC <= self.battery.reserve_soc(current_time):
            if remaining_energy > self.battery.dynamic_threshold(self.remaining_energy_history()):
                released_energy = self.battery.release_energy(remaining_energy)
            else:
                released_energy = 0

        else:
            raise ValueError("Unhandled BMS case.")

        assert not (released_energy > 0 and stored_energy > 0), \
            "Battery released and stored energy cannot be positive at the same time."

        return released_energy, stored_energy

    def simulate_household(self):
        df = self.grid_data.df
        time_values = df['datetime'].values
        self.import_energy_history = []
        self.export_energy_history = []
        self.import_cost, self.export_revenue, self.energy_cost = 0, 0, 0
        
        for k in range(len(time_values)):
            tmp_remaining_energy = df['remaining'].values[k] # Energy required = Energy net - Energy solar (kWh)
            
            # Battery management
            remaining_required = 0
            remaining_excess = 0

            released_energy, stored_energy = self.battery_management_system(tmp_remaining_energy, time_values[k])

            if tmp_remaining_energy> 0:
                # Discharge battery
                # released_energy = self.battery.release_energy(tmp_remaining_energy)
                remaining_required = tmp_remaining_energy - released_energy
                if remaining_required < 0:
                    raise ValueError("Released energy from battery exceeds remaining required energy.")
                self.energy_cost += remaining_required*self.price_per_kWh  
                self.import_cost += remaining_required*self.price_per_kWh        
            else:
                # Charge battery
                # stored_energy = self.battery.store_energy(-tmp_remaining_energy)
                remaining_excess = -tmp_remaining_energy - stored_energy
                if remaining_excess < -1e-8:
                    raise ValueError("Stored energy exceeds remaining excess energy.")
                self.energy_cost -= remaining_excess * self.injection_price
                self.export_revenue += remaining_excess * self.injection_price
            
            # Save history
            self.import_energy_history.append(remaining_required)
            self.export_energy_history.append(remaining_excess)
            self.battery.SOC_history.append(self.battery.SOC)

        return self.import_energy_history, self.export_energy_history

    def optimize_battery_capacity(self, max_capacity_kwh=15):
        total_cost_array = []
        annualized_battery_cost_array = []
        no_points = 40
        capacity_array = np.linspace(0, max_capacity_kwh, no_points)

        df = self.grid_data.df
        time_values = df['datetime'].values
        time_span = (time_values[-1] - time_values[0]) / np.timedelta64(1, 'D')  # Time span in days
        
        for idx, capacity in enumerate(capacity_array):
            print(f"Progress: {idx+1}/{no_points} (Battery capacity: {capacity:.2f} kWh)")
            self.battery = Battery(max_capacity=capacity)
            self.simulate_household()
            annualized_energy_cost = (self.energy_cost / time_span)*365
            annualized_battery_cost = self.battery.battery_cost() / self.battery.battery_lifetime
            total_cost = annualized_energy_cost + annualized_battery_cost # total annualized cost
            total_cost_array.append(total_cost)
            annualized_battery_cost_array.append(annualized_battery_cost)           

        savings_list = -(total_cost_array - total_cost_array[0]) # Savings compared to no battery
        optimal_idx = np.argmax(savings_list)
        self.optimal_battery_capacity = capacity_array[optimal_idx]
        self.battery = Battery(max_capacity=self.optimal_battery_capacity)
        self.simulate_household()

        return capacity_array, savings_list, annualized_battery_cost_array

    def annualized_cost_function(self):
        time_span = (self.grid_data.df['datetime'].values[-1] - self.grid_data.df['datetime'].values[0]) / np.timedelta64(1, 'D')  # Time span in days
        self.energy_cost = np.sum(self.import_energy_history) * self.price_per_kWh - np.sum(self.export_energy_history) * self.injection_price
        annualized_energy_cost = (self.energy_cost / time_span)*365
        annualized_battery_cost = self.battery.battery_cost() / self.battery.battery_lifetime
        return annualized_energy_cost + annualized_battery_cost

    def optimize_battery_management(self):
        initial_battery = self.battery
        df = self.grid_data.df

        # Simulate household without battery
        self.battery = Battery(max_capacity=0)
        self.simulate_household()
        total_cost_0 = self.annualized_cost_function()
        self.plot_energy_history()
        
        # Simulate household with greedy BMS
        self.battery_management_system = self.greedy_battery_management_system
        self.battery = initial_battery
        self.simulate_household()
        total_cost_greedy = self.annualized_cost_function()
        self.plot_energy_history()
        
        # Simulate household with dynamic BMS
        self.battery_management_system = self.dynamic_battery_management_system
        self.battery = initial_battery
        self.simulate_household()
        total_cost_dynamic = self.annualized_cost_function()
        self.plot_energy_history()
        
        # Simulate household with optimized battery management using convex optimization
        self.battery = initial_battery # reset to initial battery
        time_vec = (df['datetime'] - df['datetime'].iloc[0]).dt.total_seconds().values / 3600
        dt = np.diff(time_vec).mean()

        P_load = df['remaining'].values  # kW demand
        n = len(P_load)

        # Decision variables
        P_b = cp.Variable(n)        # battery net power (discharge - charge)
        SOC = cp.Variable(n+1)      # state of charge
        P_import = cp.Variable(n, nonneg=True)
        P_export = cp.Variable(n, nonneg=True)
        P_charge = cp.Variable(n, nonneg=True)
        P_discharge = cp.Variable(n, nonneg=True)

        # Parameters
        SOC_init = self.battery.SOC
        SOC_max = 1
        P_max = self.battery.C_rate * self.battery.max_capacity

        # Constraints
        constraints = []
        constraints.append(SOC[0] == SOC_init)

        for t in range(n):
            # SOC update (DCP-compliant)
            constraints.append(SOC[t+1] == SOC[t] + (self.battery.efficiency * P_charge[t] - P_discharge[t] / self.battery.efficiency ) / self.battery.max_capacity)
            constraints.append(SOC[t+1] >= 0)
            constraints.append(SOC[t+1] <= SOC_max)
            constraints.append(P_charge[t] >= 0)
            constraints.append(P_discharge[t] >= 0)
            constraints.append(P_charge[t] <= P_max)
            constraints.append(P_discharge[t] <= P_max)
            # Link battery net power to charge/discharge
            constraints.append(P_b[t] == P_discharge[t] - P_charge[t])
            constraints.append(P_b[t] <= P_max)
            constraints.append(P_b[t] >= -P_max)
            # Import/export constraints
            constraints.append(P_import[t] - P_export[t] == P_load[t] - P_b[t])
            constraints.append(P_import[t] >= 0)
            constraints.append(P_export[t] >= 0)

        # Convex objective
        cost = cp.sum(P_import * self.price_per_kWh - P_export * self.injection_price)

        # Solve
        prob = cp.Problem(cp.Minimize(cost), constraints)
        prob.solve()

        self.import_energy_history = P_import.value
        self.export_energy_history = P_export.value
        self.battery.SOC_history = SOC.value.tolist()

        total_cost_optim = self.annualized_cost_function()
        self.plot_energy_history()
        
        return self.import_energy_history, self.export_energy_history
        

    def plot_energy_history(self):
        df = self.grid_data.df
        time = df['datetime'].values
        
        fig, axes = plt.subplots(1, 2, figsize=(16, 6))
        # Line plot
        axes[0].plot(time, self.import_energy_history, label='Import Energy (kWh)', color='red')
        axes[0].plot(time, self.export_energy_history, label='Export Energy (kWh)', color='green')
        axes[0].set_title(f'Energy History (Battery Capacity: {self.battery.max_capacity:.2f} kWh)')
        axes[0].set_xlabel('Time (hours)')
        axes[0].set_ylabel('Energy (kWh)')
        axes[0].legend()
        axes[0].grid()

        # Add price annotation (energy cost)
        price_text = f"Total Energy Cost: {self.energy_cost:.2f} EUR\nImport Cost: {self.import_cost:.2f} EUR\nExport Revenue: {self.export_revenue:.2f} EUR"
        axes[0].text(0.05, 0.95, price_text, transform=axes[0].transAxes, fontsize=10, verticalalignment='top', bbox=dict(boxstyle="round,pad=0.3", facecolor="lightyellow", alpha=0.5))

        # Histogram of simulated remaining energy
        axes[1].hist(self.remaining_energy_history(), bins=30, color='purple', alpha=0.7)
        axes[1].set_title('Histogram of Remaining Consumption')
        axes[1].set_xlabel('Remaining Consumption (kWh)')
        axes[1].set_ylabel('Frequency')
        axes[1].grid(True)

        plt.tight_layout()
        return fig
    
