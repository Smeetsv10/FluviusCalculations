import flet as ft
from  screens import homescreen


if __name__ == "__main__":
    ft.app(target=homescreen, view=ft.WEB_BROWSER, port=8550)
