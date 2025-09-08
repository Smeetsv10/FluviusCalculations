import flet as ft
from classes.myBattery import Battery


def batteryScreen(page: ft.Page):
    page.title = "Battery Screen"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER

    page.battery_fields = {
        "max_capacity": ft.TextField(label="Max Capacity (kWh)", value="10", width=200),
        "efficiency": ft.TextField(label="Efficiency (-)", value="0.95", width=200),
        "soc": ft.TextField(label="Initial SOC (-)", value="0.33", width=200),
        "price_per_kWh": ft.TextField(label="Price per kWh (€)", value="700", width=200),
        "lifetime": ft.TextField(label="Battery Lifetime (years)", value="10", width=200),
        "c_rate": ft.TextField(label="C-rate (1/h)", value="1", width=200),
    }
    max_capacity_field = page.battery_fields["max_capacity"]
    efficiency_field = page.battery_fields["efficiency"]
    soc_field = page.battery_fields["soc"]
    price_field = page.battery_fields["price_per_kWh"]
    lifetime_field = page.battery_fields["lifetime"]
    c_rate_field = page.battery_fields["c_rate"]

    controls = ft.Column([
        ft.Text("Battery Screen: Select battery properties here."),
        ft.Row([max_capacity_field, efficiency_field, soc_field]),
        ft.Row([price_field, lifetime_field, c_rate_field]),
    ], alignment=ft.MainAxisAlignment.START)

    return controls