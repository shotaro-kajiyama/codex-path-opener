# Codex Path Opener

Tiny Windows helper for opening or searching paths that appear in AI coding agent output.

It is built for people using Codex, Claude Code, or similar terminal/chat agents with WSL2 and VS Code. Select a path-like snippet, press a hotkey, and jump to the file or search it in the VS Code window you were just using.

## Features

- Open selected paths in VS Code.
- Search selected paths or filenames in VS Code Quick Open.
- Prefer the most recently used VS Code window when searching.
- Support Windows paths, WSL/Linux paths, UNC WSL paths, and relative paths.
- Handle brace-style filename hints such as `button_{primary,secondary}.tsx` by searching for `button_`.
- Run as a lightweight AutoHotkey v2 tray app.

## Requirements

- Windows
- AutoHotkey v2
- VS Code
- WSL2, if you want Linux/WSL path support
- The `code` command available in Windows and, for WSL paths, inside your WSL distro

Check WSL support with:

```bash
code --version
```

## Install

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download or clone this repository.
3. Copy `CodexPathOpener.ini.example` to `CodexPathOpener.ini`.
4. Edit `CodexPathOpener.ini`.
5. Double-click `CodexPathOpener.ahk`.

Or install the startup shortcut and launch it with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install-startup.ps1
```

Example config:

```ini
[Settings]
WslDistro=Ubuntu
WslProjectRoot=~
WindowsProjectRoot=
```

If your agents usually print paths relative to one project, set `WslProjectRoot` to that project:

```ini
WslProjectRoot=~/projects/sample-app
```

## Hotkeys

| Hotkey | Action |
| --- | --- |
| `Ctrl+Alt+O` | Open the first detected selected path in VS Code |
| `Ctrl+Alt+P` | Search the selected path/query in VS Code Quick Open |
| `Ctrl+Alt+Shift+O` | Open all detected selected paths |
| `Alt+Left Click` | Copy the current selection and open the first detected path |

## Recommended Workflow

For AI agent output like:

```text
src/components/button_{primary,secondary}.tsx
```

Select the path and press:

```text
Ctrl+Alt+P
```

Codex Path Opener activates the most recently used VS Code window and sends a Quick Open search. For brace hints like `{primary,secondary}`, it searches the stable prefix, such as `button_`.

Use `Ctrl+Alt+O` when the selected path is exact and should be opened directly.

## Startup

To run it automatically on Windows login:

1. Press `Win+R`.
2. Run `shell:startup`.
3. Put a shortcut to `CodexPathOpener.ahk` in that folder.

## Files

- `CodexPathOpener.ahk`: tray app and hotkey logic
- `OpenCodexPath.ps1`: opens selected paths in VS Code
- `OpenVsCodeRoot.ps1`: opens the configured project root when no VS Code window is active
- `CodexPathOpener.ini.example`: example configuration
- `install-startup.ps1`: creates a Windows startup shortcut and launches the helper

## License

MIT
