import flet as ft
from screens.gridDataScreen import gridDataScreen
from screens.batteryScreen import batteryScreen
from screens.houseScreen import houseScreen


def results_page():
    return ft.Text("Results Page: View results for the given grid data, battery, and house.")

def homescreen(page: ft.Page):
    page.title = "Home Screen"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER    
    
    tabs = ft.Tabs(
        selected_index=0,
        tabs=[
            ft.Tab(text="Grid Data", content=ft.Container(gridDataScreen(page), padding=16)),
            ft.Tab(text="Battery", content=ft.Container(batteryScreen(page), padding=16)),
            ft.Tab(text="House", content=ft.Container(houseScreen(page), padding=16)),
            ft.Tab(text="Results", content=ft.Container(results_page(), padding=16)),
        ],
        expand=True
    )
    page.add(tabs)

if __name__ == "__main__":
    ft.app(target=homescreen)




