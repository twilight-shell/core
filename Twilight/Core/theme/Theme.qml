pragma Singleton

import QtQuick
import Quickshell
import "Palette.js" as Palette
import "../util"

// Colors, fonts and sizes. The palette (`paletteName`) is Twilight
// Sparkle's (night sky, lavender coat, indigo mane with a magenta streak,
// pink star cutie mark), one of the other ponies' presets, or derived from
// the wallpaper. It always stays dark; presets and the wallpaper only lend
// their hues. Colors glide to the new values when the palette changes.
Singleton {
    id: root

    readonly property var twilight: Palette.twilight
    readonly property var presets: Palette.presets

    // Read from theme.toml; a host that knows better sets them itself.
    ConfigFile {
        id: config

        name: "theme"
        defaults: Qt.resolvedUrl("theme.defaults.toml")
    }

    // "wallpaper": colors picked from the wallpaper, "twilight", one of the
    // keys of `presets` or of `customPalettes`.
    // The defaults file is read a moment after the first binding runs, hence `?? ""`.
    property string paletteName: config.get("palette") ?? ""
    // The palettes of your own, the [palettes.<name>] tables of theme.toml.
    readonly property var customPalettes: config.get("palettes") ?? ({})
    // Absolute path of the picture to take colors from; "" for none.
    property string wallpaper: config.get("wallpaper") ?? ""
    // A live wallpaper is drawn in the palette's colors, so it can't lend any.
    property bool liveWallpaper: false

    readonly property bool fromWallpaper: paletteName === "wallpaper" && !liveWallpaper && quantizer.colors.length > 0
    readonly property var palette: {
        const custom = customPalettes[paletteName];
        if (custom)
            return Palette.fromCustom(custom);
        const preset = presets[paletteName];
        if (preset)
            return Palette.fromPreset(preset);
        return fromWallpaper ? Palette.derive(quantizer.colors) : twilight;
    }

    property color bg: palette.bg
    property color surface: palette.surface
    property color surfaceHigh: palette.surfaceHigh
    property color border: palette.border

    property color text: palette.text
    property color muted: palette.muted

    property color primary: palette.primary
    property color accent: palette.accent
    property color secondary: palette.secondary
    property color star: palette.star

    // Sticker look: dark ink outline and a hard shadow dropped straight down.
    property color ink: palette.ink
    property color shadow: palette.shadow
    readonly property real outline: 2
    readonly property real lift: 5

    // Monocraft when installed, the system font otherwise.
    readonly property string font: Qt.fontFamilies().includes("Monocraft") ? "Monocraft" : Qt.application.font.family
    readonly property int fontSize: 14

    readonly property int radius: 12
    readonly property int gap: 8
    readonly property int barHeight: 36

    readonly property int animMs: 150

    Behavior on bg { ColorAnimation { duration: 900 } }
    Behavior on surface { ColorAnimation { duration: 900 } }
    Behavior on surfaceHigh { ColorAnimation { duration: 900 } }
    Behavior on border { ColorAnimation { duration: 900 } }
    Behavior on text { ColorAnimation { duration: 900 } }
    Behavior on muted { ColorAnimation { duration: 900 } }
    Behavior on primary { ColorAnimation { duration: 900 } }
    Behavior on accent { ColorAnimation { duration: 900 } }
    Behavior on secondary { ColorAnimation { duration: 900 } }
    Behavior on star { ColorAnimation { duration: 900 } }
    Behavior on ink { ColorAnimation { duration: 900 } }
    Behavior on shadow { ColorAnimation { duration: 900 } }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Dominant colors of the wallpaper, a few dozen pixels' worth is plenty.
    ColorQuantizer {
        id: quantizer

        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        depth: 4
        rescaleSize: 96
    }
}
