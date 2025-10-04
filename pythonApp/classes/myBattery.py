import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

class Battery:
    def __init__(self, max_capacity, efficiency=0.95, fixed_costs=1000, variable_cost=700, battery_lifetime=10, C_rate=0.25/4):
        self.max_capacity = max_capacity # (kWh)
        self.efficiency = efficiency # (-)
        self.fixed_costs = fixed_costs
        self.variable_cost = variable_cost
        self.battery_lifetime = battery_lifetime # (years)
        self.C_rate = C_rate # == (1/h)
        
        self.SOC = 0.33 # State of Charge (-)
        self.SOC_history = []
        
        assert 0 < self.efficiency <= 1, "Efficiency must be between 0 and 1"
        assert self.max_capacity >= 0, "Max capacity must be non-negative"

    def battery_cost(self):
        return self.variable_cost * self.max_capacity + self.fixed_costs

    def current_capacity(self):
        ''' Calculate current capacity of the battery (kWh)'''
        return self.SOC * self.max_capacity

    def available_capacity(self):
        ''' Calculate available capacity of the battery (kWh)'''
        return self.max_capacity - self.current_capacity()

    def max_charge_rate(self):
        return self.C_rate * self.max_capacity

    def reserve_soc(self, current_time):
        """Dynamic SOC reserve depending on time of day.
           Don’t let the battery discharge below this level, because we may need that energy later."""
        hour = pd.Timestamp(current_time).hour
        if 17 <= hour < 20:  # evening peak
            return 0.5      
        elif 0 <= hour < 6:  # night + morning peak
            return 0.25    
        else:                # daytime -> battery will charge most likely
            return 0.05  

    def dynamic_threshold(self, load_history):
        """Adaptive threshold based on demand scale."""
        avg_load = np.mean(load_history[-24*4:])  # last day
        return 0.15 * avg_load  # 15% of avg load

    def store_energy(self, energy):
        """Store energy in the battery (kWh) accounting for symmetric efficiency losses."""
        if self.max_capacity <= 0:
            return 0
        
        # Apply efficiency during charging
        energy_in = energy * self.efficiency
        
        charge_limit = min(self.max_charge_rate(), self.available_capacity())
        storable_energy = min(energy_in, charge_limit)
        
        self.SOC += storable_energy / self.max_capacity
        return storable_energy / self.efficiency  # Return the "original" input energy used

    def release_energy(self, energy):
        """Release energy from the battery (kWh) accounting for symmetric efficiency losses."""
        if self.max_capacity <= 0:
            return 0
        
        discharge_limit = min(self.max_charge_rate(), self.current_capacity())
        releasable_energy = min(energy, discharge_limit)
        
        self.SOC -= releasable_energy / self.max_capacity
        return releasable_energy * self.efficiency  # Energy actually delivered to load

    def plot_SOC(self):
        ''' Plot the State of Charge (SOC) over time '''
        plt.figure(figsize=(10, 5))
        plt.plot(self.SOC_history, label='SOC', color='blue')
        plt.title('Battery State of Charge (SOC) Over Time')
        plt.xlabel('Time (hours)')
        plt.ylabel('State of Charge (-)')
        plt.legend()
        plt.grid()