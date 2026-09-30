# Agent guidance for youtube-to-markdown

This is a standalone Bun/TypeScript CLI for Windows and macOS. Source files
live at the repo root. `index.ts` calls the public conversion API and copies
its markdown response to the clipboard. There are no API keys or persisted settings.

## Development

- Use test-first development for non-trivial changes. Extract a test seam first
  if needed, then implement until the test passes.
- Rerun relevant tests when behavior, startup, copy, or tested contracts change.
- Before committing, run `bun install --frozen-lockfile`, `bun test`, and
  `pwsh -NoProfile -File tests/check-powershell.ps1`. Smoke-test the actual CLI.
- Tests must stay offline, without changing the user's clipboard or requiring secrets.
- `youtube-to-markdown` is the macOS launcher. Resolve its own location even when
  called through an installed symlink or from another working directory.
- `install.sh` links it into `~/.local/bin` and installs dependencies. Rerun
  the installer after moving the clone.

## Windows integration

- `install.ps1` writes thin stubs into `C:\dev\tools`, creates the Explorer
  entries, converts the icon, and runs `deps.ps1`. Use `-SkipDeps` to skip dependencies.
- Never copy source files into `C:\dev\tools`. Stubs point at this clone, so code
  edits take effect without reinstalling. Large binaries belong outside the repo.
- Write `.bat` stubs as ASCII. Avoid curly quotes and non-ASCII strings in them.
- This is an interactive terminal tool, so a visible console is intentional.
- Preserve the shared `Mike's Tools` submenu and every other tool's verbs.
  `uninstall.ps1` removes only this tool's entries and generated files.
- `deps.ps1` must be idempotent, self-contained, and give clear output.
  Check for Bun before installing dependencies and fail if installation fails.
- Parse every `.ps1` with PowerShell. On Windows, also run the scripts directly
  and verify CLI forwarding, Explorer entries, icon transparency, and uninstall.

## Documentation

Use the current command and GitHub repo name throughout. External service domains
are independent of this tool's name. Keep the existing screenshot files and icon
attribution. Write plainly, without em dashes or en dashes.
