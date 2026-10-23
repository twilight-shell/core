# Contributing to core

Thank you for helping. The guide for every repository of the organization is [here](https://github.com/twilight-shell/.github/blob/main/CONTRIBUTING.md): how to propose a change, the commit messages, the checks and the code style. What follows is what is particular to this repository.

## Working on it

- **What it needs:** nothing from the other components.
- **Tests:** `QT_QPA_PLATFORM=offscreen qml tests/toml.qml`; each prints its result and exits with a non-zero code when a check fails.
- **Before sending:** run the checks of the guide (`ci/run-tests.sh`, `check-settings.sh`, `check-depends.sh`, `check-install.sh` from the `.github` repository) and add a line to `CHANGELOG.md` under `## Unreleased`.

## Good to know

- Every other component imports this module, so a change to what it exports is a change to all of them. Keep what exists working; add rather than rename.
- `Toml.js` has no dates and no writing into arrays of tables. QML's JavaScript is older than a browser's: no `trimStart`, check before using a newer method.
- `ConfigFile.get(key)` reads the file, then the defaults, then the fallback argument. A property typed `string`, `bool` or `real` sees `undefined` for a moment at startup, because the defaults file is read a little later: coerce (`!!x`, `Number(x)`, `x ?? ""`).

For security problems, please don't open an issue: see [SECURITY.md](https://github.com/twilight-shell/.github/blob/main/SECURITY.md).
