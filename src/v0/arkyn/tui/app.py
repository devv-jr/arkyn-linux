"""Minimal Textual app for ARKYN"""
from textual.app import App
from textual.widgets import Header, Footer, Static

class ARKYNApp(App):
    CSS = """
    Screen {
        align: center middle;
    }
    """

    async def on_mount(self) -> None:
        await self.view.dock(Header(), edge="top")
        await self.view.dock(Footer(), edge="bottom")
        await self.view.dock(Static("Welcome to ARKYN TUI\nPress q to quit", id="body"))

    async def action_quit(self) -> None:
        await self.shutdown()