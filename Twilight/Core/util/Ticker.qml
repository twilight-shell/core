pragma Singleton

import QtQuick
import Quickshell

// A slow shared clock for idle motion (breathing, swaying). Animations run
// at the display's refresh rate, 144 frames a second here, and an endless
// one keeps its whole window redrawing; gentle loops bound to `t` instead
// redraw at 30.
Singleton {
    // Seconds since the shell started.
    property real t: 0

    function wave(period) {
        return Math.sin(t * 2 * Math.PI / period);
    }

    Timer {
        interval: 33
        repeat: true
        running: true
        onTriggered: parent.t += interval / 1000
    }
}
