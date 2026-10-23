# twilight-shell/core

The shared QML module behind the twilight shell and its components: theme,
sticker look, small UI kit. Components import it instead of copying it.

```qml
import Twilight.Core

Sticker {
    fill: Theme.surface
    StyledText { text: "hello" }
}
```

## What's inside

| | |
|---|---|
| `Theme` (singleton) | Palette, font, sizes. Palette comes from Twilight, a preset, or a wallpaper. |
| `Ticker` (singleton) | A slow shared clock for idle motion, so endless animations don't redraw at the display's refresh rate. |
| `Icons` (singleton) | Icon lookup with a chain of candidates. |
| `Astro` (singleton) | Moon phase and its name for any date. |
| `ConfigFile` | A TOML settings file in `~/.config/twilight-shell/`, reloaded when it changes. |
| `Toml` | The reader and writer behind it: `Toml.parse(text)`, `Toml.set(text, ["a", "b"], value)`. |
| `Sticker`, `Tap`, `StyledText`, `Toggle`, `StarSlider`, `RollText` | The sticker UI kit. |
| `Moon`, `Starfield`, `SparkleBurst` | Decorations. |

The module knows nothing about the compositor or the other components. `Theme`
takes its palette from `theme.toml` (see Settings below). A host that knows
better, say a wallpaper component that draws a live wallpaper, sets the same
properties itself:

```qml
Binding { target: Theme; property: "paletteName"; value: "twilight" }
Binding { target: Theme; property: "wallpaper"; value: "/path/to/picture.png" }
Binding { target: Theme; property: "liveWallpaper"; value: true }
```

## Settings

Components keep their settings in TOML, one file each in
`~/.config/twilight-shell/`. Comments and layout survive when the shell writes a
value back.

The defaults are a TOML file shipped with the component and nowhere else, so the
code never repeats them:

```qml
ConfigFile {
    id: config
    name: "app-launcher"                                       // app-launcher.toml
    defaults: Qt.resolvedUrl("app-launcher.defaults.toml")
}

terminal: config.get("terminal")                // the file, else the defaults
height: config.get("bar.height")                // `height` in the [bar] table
// config.set("terminal", ["ghostty", "-e"])
```

A component that starts without a settings file creates one from its defaults,
so the file shows every setting with the value in use. Values are copied once:
a default that changes in a later version doesn't overwrite yours, and a key the
file lacks still reads its default.

`Theme` reads `theme.toml`, shared by every component:

```toml
palette = "wallpaper"   # "twilight", "luna", "rarity", "pinkie", "celestia",
                        # "fluttershy", "rainbow", or "wallpaper"
wallpaper = ""          # picture to take the colors from
```

A file that doesn't parse is reported in `config.error` and the last good values
stay.

## Installing

Needs [Quickshell](https://quickshell.org) 0.3 or newer.

```sh
sudo make install                       # to /usr/lib/qt6/qml/Twilight/Core
make install PREFIX=~/.local QMLDIR=~/.local/lib/qt6/qml
```

If the module isn't in a directory Qt searches, point `QML_IMPORT_PATH` at its
parent:

```sh
QML_IMPORT_PATH=/path/to/core qs -c my-shell
```

Without it Quickshell fails with `module "Twilight.Core" is not installed`.

## License

MIT, see `LICENSE`.
