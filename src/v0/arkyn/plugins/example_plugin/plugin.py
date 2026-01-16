"""Example plugin demonstrating the register contract"""

def register(cli):
    import click

    @cli.command(name="hello-plugin")
    def hello_plugin():
        """Say hello (from plugin)"""
        click.echo("Hello from example_plugin!")