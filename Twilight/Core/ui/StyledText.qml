import QtQuick
import ".."

// Text in the theme's font and color. `outlined` adds the ink outline the
// sticker look puts on glyphs and big labels.
Text {
    property bool outlined: false

    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    style: outlined ? Text.Outline : Text.Normal
    styleColor: Theme.ink

    Behavior on color {
        ColorAnimation { duration: Theme.animMs }
    }
}
