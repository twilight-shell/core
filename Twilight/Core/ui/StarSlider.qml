import QtQuick
import ".."

// Horizontal slider with a star for a knob. Click or drag anywhere on it,
// or scroll. Emits moved(value) with the new value in 0..1; the owner
// decides what to do with it.
Item {
    id: root

    property real value: 0
    property bool muted: false

    signal moved(real value)

    property real dragValue: 0
    readonly property real shown: mouse.pressed ? dragValue : value

    implicitWidth: 200
    implicitHeight: 26

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 12
        radius: 6
        color: Theme.bg
        border.color: Theme.ink
        border.width: 2

        Rectangle {
            id: fill

            x: 2
            y: 2
            height: parent.height - 4
            width: Math.max(height, (parent.width - 4) * root.shown)
            radius: height / 2
            visible: root.shown > 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.muted ? Theme.muted : Theme.secondary }
                GradientStop { position: 1; color: root.muted ? Theme.muted : Theme.star }
            }

            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            }

            // Gloss
            Rectangle {
                x: 3
                y: 1
                width: Math.max(0, parent.width - 6)
                height: 2
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.35)
            }
        }
    }

    StyledText {
        x: fill.x + fill.width - width / 2
        outlined: true
        anchors.verticalCenter: parent.verticalCenter
        text: "★"
        color: root.muted ? Theme.muted : Theme.text
        font.pixelSize: 20
        rotation: root.shown * 360
        scale: mouse.pressed ? 1.35 : mouse.containsMouse ? 1.15 : 1

        Behavior on scale {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function set(x) {
            root.dragValue = root.clamp((x - 6) / root.width);
            root.moved(root.dragValue);
        }

        onPressed: event => set(event.x)
        onPositionChanged: event => {
            if (pressed)
                set(event.x);
        }
        onWheel: event => root.moved(root.clamp(root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
