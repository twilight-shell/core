import QtQuick
import ".."

// Night sky of twinkling stars scattered over the item. The twinkle is
// computed from the shared Ticker rather than one endless animation per
// star: those redraw the window at the display's refresh rate, this at 30.
Item {
    id: root

    property int count: 90
    property bool running: true

    // Ticker time while running, frozen at the last value otherwise.
    property real time: 0

    Binding {
        target: root
        property: "time"
        value: Ticker.t
        when: root.running
        restoreMode: Binding.RestoreNone
    }

    Repeater {
        model: root.count

        StyledText {
            id: star

            readonly property real rx: Math.random()
            readonly property real ry: Math.random()
            // Seconds from dim to bright, and back.
            readonly property real period: (900 + Math.random() * 2600) / 1000
            readonly property real peak: 0.35 + Math.random() * 0.6
            readonly property real phase: Math.random()

            x: rx * root.width
            y: ry * root.height
            text: ["✦", "✧", "·", "⋆", "·"][Math.floor(Math.random() * 5)]
            color: [Theme.text, Theme.primary, Theme.star, Theme.text][Math.floor(Math.random() * 4)]
            font.pixelSize: 6 + Math.random() * 12
            opacity: 0.08 + (peak - 0.08) * (0.5 - 0.5 * Math.cos(2 * Math.PI * (root.time / (2 * period) + phase)))
        }
    }
}
