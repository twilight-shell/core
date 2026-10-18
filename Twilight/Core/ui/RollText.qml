import QtQuick
import ".."

// Text that rolls when it changes: the old value slides up and fades out
// while the new one springs in from below.
Item {
    id: root

    property string text
    property color color: Theme.text
    property int pixelSize: Theme.fontSize
    property bool bold: false
    property bool outline: false
    property int elide: Text.ElideNone
    property int maxWidth: 100000
    property int duration: 420
    // When false, the next text change is applied in place without rolling.
    property bool animate: true

    property string previous: ""
    property string last: ""
    property real t: 1

    implicitWidth: Math.min(maxWidth, current.implicitWidth)
    implicitHeight: current.implicitHeight
    clip: true

    Component.onCompleted: last = text

    onTextChanged: {
        if (animate) {
            previous = last;
            roll.restart();
        }
        last = text;
    }

    NumberAnimation {
        id: roll

        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.OutBack
        easing.overshoot: 1.6
    }

    StyledText {
        y: -root.t * root.height
        width: root.width
        opacity: 1 - root.t
        text: root.previous
        color: root.color
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        outlined: root.outline
        elide: root.elide
    }

    StyledText {
        id: current

        y: (1 - root.t) * root.height
        width: root.width
        text: root.text
        color: root.color
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        outlined: root.outline
        elide: root.elide
    }
}
