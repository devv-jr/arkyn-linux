```


---


# README.md


```markdown
# ARKYN CLI v0


**ARKYN**: environment toolkit for mobile and desktop (Termux-first).


## Goals v0
- Python-first CLI with plugin architecture
- Minimal TUI powered by Textual
- Easy install on Termux / Android via `scripts/install_termux.sh`


## Quickstart (dev)


```bash
# create virtualenv
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
arkyn --help
```


## Install on Termux (basic)


Run `scripts/install_termux.sh` on device (requires git + python in Termux)


## Plugin dev
- Create a package under `src/arkyn/plugins/<name>` implementing a `register(cli)` function or expose an entry point `arkyn.plugins`.


```python
# plugin example interface
def register(cli):
@cli.command()
def hello():
print('hello from plugin')
```