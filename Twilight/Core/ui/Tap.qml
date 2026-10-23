import QtQuick
import ".."

// A sticker you can press: brightens under the pointer and sinks onto its
// shadow while held. Children go inside the sticker.
Item {
    id: root

    property color fill: Theme.surfaceHigh
    property color hoverFill: Qt.lighter(fill, 1.25)
    property real radius: height / 2
    property real lift: 3
    property bool gloss: true
    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed
    default property alias content: sticker.content

    signal clicked(var mouse)
    // The wheel goes on to whatever is underneath, say a page that scrolls,
    // unless a handler uses it by setting `event.accepted = true`.
    signal wheel(var event)

    readonly property real sink: mouse.pressed ? lift : 0

    Sticker {
        id: sticker

        y: root.sink
        width: root.width
        height: root.height
        radius: root.radius
        lift: root.lift - root.sink
        gloss: root.gloss
        fill: mouse.containsMouse ? root.hoverFill : root.fill

        Behavior on y {
            NumberAnimation { duration: 80 }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.bottomMargin: -root.lift
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event)
        onWheel: event => {
            event.accepted = false;
            root.wheel(event);
        }
    }
}
