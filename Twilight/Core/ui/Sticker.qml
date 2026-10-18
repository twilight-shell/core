import QtQuick
import ".."

// Base surface: a fill inside a thick ink line, a hard shadow below and a
// soft gloss on top. Children go inside the fill.
Item {
    id: root

    property color fill: Theme.surface
    property color edge: Theme.ink
    property color shade: Theme.shadow
    property real radius: Theme.radius
    property real outline: Theme.outline
    property real lift: Theme.lift
    property bool gloss: true
    default property alias content: face.data

    Rectangle {
        visible: root.lift > 0
        y: root.lift
        width: root.width
        height: root.height
        radius: root.radius
        color: root.shade
    }

    Rectangle {
        id: face

        anchors.fill: parent
        radius: root.radius
        color: root.fill
        border.color: root.edge
        border.width: root.outline

        Behavior on color {
            ColorAnimation { duration: Theme.animMs }
        }

        // Hairline of light inside the ink so the sticker doesn't sink into the dark.
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.outline
            radius: Math.max(0, root.radius - root.outline)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)
        }

        Rectangle {
            visible: root.gloss
            anchors.fill: parent
            anchors.margins: root.outline
            radius: Math.max(0, root.radius - root.outline)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }
}
