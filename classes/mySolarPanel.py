
class SolarPanel:
    def __init__(self, area, efficiency):
        self.area = area
        self.cost_per_kWpp = 1500 # eur/kWpp
        self.efficiency = efficiency

    def P_solar(self, irradiance):
        ''' Calculate the solar power output in kW'''
        return self.area * self.efficiency * irradiance / 1000

class SolarPanels:
    def __init__(self):
        self.panels = []

    def add_panel(self, panel):
        self.panels.append(panel)

    def total_power_output(self, irradiance):
        return sum(panel.P_solar(irradiance) for panel in self.panels)