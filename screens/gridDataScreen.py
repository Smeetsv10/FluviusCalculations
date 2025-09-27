import flet as ft
from classes import GridData
from flet.matplotlib_chart import MatplotlibChart


def gridDataScreen(page: ft.Page):
    page.title = "Grid Data Screen"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.activeFigure = None
    page.selected_file = None

    # File picker
    file_picker = ft.FilePicker()
    page.overlay.append(file_picker)

    def on_file_picked(e):
        if e.files:
            page.selected_file = e.files[0].path
            file_path_display.value = page.selected_file
            page.update()

    file_picker.on_result = on_file_picked
    file_path_display = ft.TextField(label="File Path", value="", width=800, read_only=True)
    pick_file_btn = ft.ElevatedButton("Select File", on_click=lambda e: file_picker.pick_files(allow_multiple=False))

    start_date = ft.TextField(label="Start Date", value="2025-07-24", width=200)
    end_date = ft.TextField(label="End Date", value="2025-08-24", width=200)

    def load_data(e):
        try:
            if not page.selected_file:
                page.snackbar = ft.SnackBar(ft.Text("Please select a file!"))
                page.open(page.snackbar)
                page.update()
                return
            page.house.grid_data = GridData(file_path=page.selected_file, start_date=start_date.value, end_date=end_date.value)
            page.snackbar = ft.SnackBar(ft.Text("Data Loaded Successfully!"))
            page.open(page.snackbar)
            page.update()
        except Exception as ex:
            page.snackbar = ft.SnackBar(ft.Text(f"Error loading data: {ex}"))
            page.open(page.snackbar)
            page.update()

    chart_container = ft.Container(expand=True, padding=8, alignment=ft.alignment.center)

    def visualize_data(e):
        if page.house.grid_data is None:
            page.snackbar = ft.SnackBar(ft.Text("Please load data first!"))
            page.open(page.snackbar)
            page.update()
            return
        fig = page.house.grid_data.visualize_data()
        chart = MatplotlibChart(fig, expand=True)
        chart_container.content = chart
        page.update()

    load_btn = ft.ElevatedButton("Load Data", on_click=load_data)
    visualize_btn = ft.ElevatedButton("Visualize Data", on_click=visualize_data)

    controls = ft.Column([
        ft.Row([pick_file_btn, file_path_display]),
        ft.Row([start_date, end_date]),
        ft.Row([load_btn, visualize_btn]),
        chart_container,
    ], alignment=ft.MainAxisAlignment.START)

    return controls
