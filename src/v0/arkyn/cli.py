"""Main CLI entrypoint for ARKYN"""
import click
from .plugin_manager import register_plugins
from .core import ensure_dirs


@click.group()
@click.version_option()
def main():
    """ARKYN - toolkit for Termux & Linux"""
    ensure_dirs()


@main.command()
def info():
    """Show basic ARKYN info"""
    click.echo("ARKYN v0.1 — Termux-first toolkit")


@main.group()
def plugins():
    """Plugin management commands"""
    pass


@plugins.command("list")
def plugins_list():
    """List discovered plugins"""
    plugins = register_plugins.__globals__["discover_plugins"]()
    if not plugins:
        click.echo("No plugins found")
        return
    for name in sorted(plugins.keys()):
        click.echo(f"- {name}")


@main.command()
def tui():
    """Launch the Textual TUI (if installed)"""
    try:
        from .tui.app import ARKYNApp
    except Exception as e:
        click.echo("Textual not installed. Install with: pip install '.[ui]'\n" + str(e))
        return
    ARKYNApp().run()


# Register plugins into CLI (this will add plugin commands)
register_plugins(main)


if __name__ == "__main__":
    main()