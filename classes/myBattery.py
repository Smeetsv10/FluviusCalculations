class Battery:
    def __init__(self, max_capacity, efficiency=0.95):
        self.max_capacity = max_capacity # (kWh)
        self.efficiency = efficiency # (-)
        self.SOC = 0.33 # State of Charge (-)
        self.price_per_kWh = 700
        self.battery_lifetime = 10 # (years)

        # Dependent properties
        self.current_capacity = self.calc_current_capacity()
        self.available_capacity = self.calc_available_capacity()
        self.battery_cost = self.calc_battery_cost()

    def calc_battery_cost(self):
        return self.price_per_kWh * self.max_capacity

    def calc_current_capacity(self):
        ''' Calculate current capacity of the battery (kWh)'''
        return self.SOC * self.max_capacity

    def calc_available_capacity(self):
        ''' Calculate available capacity of the battery (kWh)'''
        return self.max_capacity - self.current_capacity

    def store_energy(self, energy):
        ''' Store energy in the battery (kWh)'''
        if self.max_capacity <= 0:
            return 0
        energy_in = energy * self.efficiency # Account for storage losses
        storable_energy = min(energy_in, self.available_capacity)
        self.SOC += storable_energy / self.max_capacity
        return storable_energy

    def release_energy(self, energy):
        ''' Release energy from the battery (kWh)'''
        if self.max_capacity <= 0:
            return 0
        releasable_energy = min(energy, self.current_capacity) 
        self.SOC -= releasable_energy / self.max_capacity
        self.current_capacity = self.SOC * self.max_capacity
        return releasable_energy