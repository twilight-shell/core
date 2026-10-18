import QtQuick
import ".."

// On/off switch: a pill track with a star knob that springs across and
// lights up when on.
Item {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 54
    implicitHeight: 28

    Sticker {
        anchors.fill: parent
        radius: height / 2
        lift: 2
        fill: root.checked ? Theme.accent : Theme.surfaceHigh
        gloss: false
    }

    StyledText {
        id: knob

        outlined: true
        x: root.checked ? root.width - width - 4 : 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: "★"
        color: root.checked ? Theme.text : Theme.muted
        font.pixelSize: 22
        rotation: root.checked ? 144 : 0
        scale: mouse.pressed ? 0.8 : mouse.containsMouse ? 1.15 : 1

        Behavior on x {
            NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2 }
        }
        Behavior on rotation {
            NumberAnimation { duration: 450; easing.type: Easing.OutBack }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
