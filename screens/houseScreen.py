import flet as ft
from classes.myHouse import House


def houseScreen(page: ft.Page):
    location_field = ft.TextField(label="Location (City, Country)", value="", width=200, hint_text="e.g. Hoegaarden, Belgium")
    injection_price_field = ft.TextField(label="Injection Price (€/kWh)", value="0.04", width=200)
    price_per_kwh_field = ft.TextField(label="Price per kWh (€/kWh)", value="0.35", width=200)    
    page.title = "House Screen"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    
    def simulate_household(e):
        try:
            # Create Battery from page attributes set by batteryScreen
            battery = None
            if hasattr(page, "battery_fields"):
                bf = page.battery_fields
                try:
                    from classes.myBattery import Battery
                    battery = Battery(
                        max_capacity=float(bf["max_capacity"].value),
                        efficiency=float(bf["efficiency"].value)
                    )
                    battery.SOC = float(bf["soc"].value)
                    battery.price_per_kWh = float(bf["price_per_kWh"].value)
                    battery.battery_lifetime = float(bf["lifetime"].value)
                    battery.C_rate = float(bf["c_rate"].value)
                except Exception as ex:
                    print("Error creating battery:", ex)
            # Create GridData from page attributes set by gridDataScreen
            grid_data = None
            if hasattr(page, "grid_data"):
                if page.grid_data is not None:
                    grid_data = page.grid_data
                else:
                    page.snackbar = ft.SnackBar(ft.Text("Please load grid data in the Grid Data tab!"))
                    page.open(page.snackbar)
                    page.update()
                    return
            house = House(
                location=str(location_field.value),
                injection_price=float(injection_price_field.value),
                price_per_kwh=float(price_per_kwh_field.value),
                battery=battery,
                grid_data=grid_data
            )
            house.simulate_household()
            page.snackbar = ft.SnackBar(ft.Text("Simulation complete!"))
            page.open(page.snackbar)
            page.update()
        except Exception as ex:
            page.snackbar = ft.SnackBar(ft.Text(f"Simulation error: {ex}"))
            page.open(page.snackbar)
            page.update()

    simulate_btn = ft.ElevatedButton("Simulate Household", on_click=simulate_household)
    controls = ft.Column([
        ft.Text("House Screen: Select house properties here."),
        ft.Row([location_field, injection_price_field, price_per_kwh_field]),
        ft.Row([ft.Text("Battery: assigned through Battery Screen"), ft.Text("Grid Data: assigned through Grid Data Screen")]),
        ft.Row([simulate_btn], alignment=ft.MainAxisAlignment.CENTER)
    ], alignment=ft.MainAxisAlignment.START)

    return controls