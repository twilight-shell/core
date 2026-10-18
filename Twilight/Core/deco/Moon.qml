import QtQuick
import QtQuick.Effects
import ".."

// The moon drawn for a given phase: 0 new, 0.5 full, 1 new again.
Item {
    id: root

    property real phase: 0
    property color color: Theme.text

    // Shadow disc slides across the lit one: from the left while waxing,
    // off to the right while waning.
    readonly property real shadowX: phase <= 0.5 ? -phase * 2 * width : (1 - phase) * 2 * width

    implicitWidth: 34
    implicitHeight: 34

    Item {
        id: disc

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.color
        }

        Rectangle {
            x: root.shadowX
            width: parent.width
            height: parent.height
            radius: width / 2
            color: Theme.surfaceHigh
        }
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }

    // Soft glow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 12
        height: width
        radius: width / 2
        color: Theme.alpha(Theme.primary, 0.15)
    }

    MultiEffect {
        anchors.fill: parent
        source: disc
        maskEnabled: true
        maskSource: mask
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: Theme.ink
        border.width: 2
    }
}
