# AGENTS.md

For AI coding agents working in this repository; humans may find it a quick orientation. The full guide is [CONTRIBUTING.md](CONTRIBUTING.md) and [the organization's](https://github.com/twilight-shell/.github/blob/main/CONTRIBUTING.md).

## What this is

The module every component builds on: the theme (`Theme`), the palettes (`Palette`), the sticker UI kit, `ConfigFile` for the TOML settings files, and a TOML reader and writer (`Toml`).

It is one repository of [twilight-shell](https://github.com/twilight-shell), a Wayland desktop shell made of independent repositories. It needs: nothing from the other components.

## Layout

- `Twilight/Core/theme/`: `Theme.qml` (a singleton), `Palette.js` (palette math, pure), `theme.defaults.toml`
- `Twilight/Core/util/`: `ConfigFile.qml`, `Toml.js` (pure), `Icons.qml`, `Astro.qml`, `Ticker.qml`
- `Twilight/Core/ui/` and `deco/`: the sticker kit and the decorations; `qmldir` lists what is public
- `tests/toml.qml`: tests for the TOML reader and writer and for the palettes
- `DEPENDS`: the modules it needs; `CHANGELOG.md`; `Makefile` (`make install`)

## Run and check it

It has no entry point of its own; it is used by the other components.

```sh
QT_QPA_PLATFORM=offscreen qml tests/toml.qml
```

A test prints its result and exits with a non-zero code when a check fails.

The checks CI runs are scripts in the [`.github` repository](https://github.com/twilight-shell/.github/tree/main/ci); run them before you push.

## Rules

- Work on a branch (`feat/...`, `fix/...`, `docs/...`); never commit to or push `main`. Changes land through a pull request.
- Commit messages are `type: Subject` (`feat`, `fix`, `docs`, `test`, `ci`, `chore`, `refactor`), imperative, capitalized, no full stop.
- One change per pull request, small. Update the `CHANGELOG.md` (`## Unreleased`), the README, and `DEPENDS` if you import another `Twilight.*` module.
- **Defaults live in one place:** `<name>.defaults.toml`. Never repeat a default in code.
- **A component doesn't know the others:** what it needs comes in as properties and signals, set by the shell. Don't import another component to reach into it.
- Don't add a dependency without asking. Comments say why, not what; English; match the style around.

## Be careful

- **Use a throwaway settings folder** while you try things: `XDG_CONFIG_HOME=$(mktemp -d)`. Don't write to the user's `~/.config/twilight-shell/`.
- **Don't match your own command with `pkill -f` or `pgrep -f`:** a pattern that is in the command line of the shell that runs it kills that shell. Use `pgrep -x qs`, or `qs -p <path> kill`.
- A screenshot of the whole screen shows whatever windows are open. Take them on an empty workspace, and don't publish what isn't yours.
- Don't run the real lock screen without a way out (a TTY, and a timer that unlocks); see the `lock` repository.

## This repository

- Every other component imports this module, so a change to what it exports is a change to all of them. Keep what exists working; add rather than rename.
- `Toml.js` has no dates and no writing into arrays of tables. QML's JavaScript is older than a browser's: no `trimStart`, check before using a newer method.
- `ConfigFile.get(key)` reads the file, then the defaults, then the fallback argument. A property typed `string`, `bool` or `real` sees `undefined` for a moment at startup, because the defaults file is read a little later: coerce (`!!x`, `Number(x)`, `x ?? ""`).

## QML and Quickshell gotchas

- Typed properties (`string`, `bool`, `real`) see `undefined` at startup until a defaults file is read; coerce with `!!x`, `Number(x)` or `x ?? ""` rather than repeating the default.
- In a function with typed parameters QML wants a return type too (`function f(a: string): void`); without it a returned value is an error.
- An `id` can hide a property of the same name: `auth: auth` is a property bound to itself. Give ids names that don't repeat a property.
- `Process` and `FileView` are asynchronous; whatever reads their result has to wait for it.
- Quickshell loads the config again when a file of the config changes, but QML Qt has already loaded from elsewhere is cached, and the list of module folders is read once, at start.
- A `Row` doesn't use `implicitWidth`: give the items a `width`, or they have none.
