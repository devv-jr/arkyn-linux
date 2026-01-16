"""Core helpers for ARKYN"""
import os
from pathlib import Path

ARKYN_HOME = Path(os.environ.get("ARKYN_HOME", Path.home() / ".arkyn"))
PLUGIN_DIR = ARKYN_HOME / "plugins"

def ensure_dirs():
    PLUGIN_DIR.mkdir(parents=True, exist_ok=True)