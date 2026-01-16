"""Simple plugin discovery and loader.

Supports two discovery modes:
 - Entry points: `arkyn.plugins` (packaged plugins)
 - Local plugins: `$ARKYN_HOME/plugins` or `~/.arkyn/plugins`

Plugin contract: plugin module must provide `register(cli)` function OR `run(*args, **kwargs)`.
"""
from importlib import import_module
from importlib.metadata import entry_points, EntryPoint
import sys
from pathlib import Path
import os

from .core import PLUGIN_DIR


def discover_entrypoint_plugins():
    eps = entry_points()
    # compatibility for different Python versions
    group = eps.select(group="arkyn.plugins") if hasattr(eps, "select") else eps.get("arkyn.plugins", [])
    plugins = {}
    for ep in group:
        try:
            plugins[ep.name] = ep.load()
        except Exception as e:
            print(f"failed loading entrypoint {ep}: {e}")
    return plugins


def discover_local_plugins():
    plugins = {}
    if PLUGIN_DIR.exists():
        for p in PLUGIN_DIR.iterdir():
            if p.is_dir() and (p / "plugin.py").exists():
                # add parent to sys.path temporarily
                sys.path.insert(0, str(PLUGIN_DIR))
                try:
                    mod = import_module(p.name + ".plugin")
                    plugins[p.name] = mod
                except Exception as e:
                    print(f"failed loading local plugin {p.name}: {e}")
                finally:
                    sys.path.pop(0)
    return plugins


def discover_plugins():
    plugins = {}
    plugins.update(discover_entrypoint_plugins())
    plugins.update(discover_local_plugins())
    return plugins


def register_plugins(cli):
    plugins = discover_plugins()
    for name, mod in plugins.items():
        try:
            if hasattr(mod, "register"):
                mod.register(cli)
            elif hasattr(mod, "setup"):
                mod.setup(cli)
            else:
                # fallback: create a command wrapper
                import click

                @cli.command(name=name)
                def wrapper():
                    print(f"Plugin {name} loaded but has no register()")
        except Exception as e:
            print(f"error registering plugin {name}: {e}")