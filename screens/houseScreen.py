import flet as ft
from classes.myHouse import House
from flet.matplotlib_chart import MatplotlibChart


def houseScreen(page: ft.Page):
    def optimize_battery(e):
        if page.house.battery is None or page.house.grid_data is None:
            page.snackbar = ft.SnackBar(ft.Text("Please assign battery and grid data first!"))
            page.open(page.snackbar)
            page.update()
            return
        try:
            page.house.optimize_battery_capacity()
            page.snackbar = ft.SnackBar(ft.Text("Battery optimization completed!"))
            page.open(page.snackbar)
            page.update()
        except Exception as ex:
            page.snackbar = ft.SnackBar(ft.Text(f"Optimization failed: {ex}"))
            page.open(page.snackbar)
            page.update()
    page.title = "House Screen"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    
    def update_house(e=None):
        try:
            page.house = House(
                location=location_field.value,
                injection_price=float(injection_price_field.value),
                price_per_kWh=float(price_per_kwh_field.value)
            )
        except Exception as ex:
            print("House update error:", ex)
            
    def simulate(e):
        # Check that battery and grid_data are assigned
        if page.house.battery is None:
            page.snackbar = ft.SnackBar(ft.Text("Please assign a battery in the Battery Screen!"))
            page.open(page.snackbar)
            page.update()
            return
        if page.house.grid_data is None:
            page.snackbar = ft.SnackBar(ft.Text("Please load grid data in the Grid Data Screen!"))
            page.open(page.snackbar)
            page.update()
            return
        try:
            page.house.simulate_household()
            page.snackbar = ft.SnackBar(ft.Text("Simulation completed successfully!"))
            page.open(page.snackbar)
            page.update()

            fig = page.house.plot_energy_history()
            chart = MatplotlibChart(fig, expand=True)
            chart_container.content = chart
            page.update()
            
        except Exception as e:
            page.snackbar = ft.SnackBar(ft.Text(f"Simulation failed: {e}"))
            page.open(page.snackbar)
            page.update()
            
    location_field = ft.TextField(label="Location (City, Country)", value="", width=200, hint_text="e.g. Hoegaarden, Belgium", on_change=update_house)
    injection_price_field = ft.TextField(label="Injection Price (€/kWh)", value="0.04", width=200, on_change=update_house)
    price_per_kwh_field = ft.TextField(label="Price per kWh (€/kWh)", value="0.35", width=200, on_change=update_house)
    chart_container = ft.Container(expand=True, padding=8, alignment=ft.alignment.center)

    simulate_btn = ft.ElevatedButton("Simulate Household", on_click=simulate)
    optimize_btn = ft.ElevatedButton("Optimize Battery Capacity", on_click=optimize_battery)
    controls = ft.Column([
        ft.Text("House Screen: Select house properties here."),
        ft.Row([location_field, injection_price_field, price_per_kwh_field]),
        ft.Row([ft.Text("Battery: assigned through Battery Screen"), ft.Text("Grid Data: assigned through Grid Data Screen")]),
        ft.Row([simulate_btn, optimize_btn], alignment=ft.MainAxisAlignment.CENTER),
        chart_container
    ], alignment=ft.MainAxisAlignment.START)

    return controls