pragma Singleton

import QtQuick
import Quickshell

// Moon phase from a known new moon and the mean synodic month.
Singleton {
    readonly property real synodicMonth: 29.530588853
    readonly property real knownNewMoon: Date.UTC(2000, 0, 6, 18, 14) / 86400000

    // 0 new, 0.5 full, approaching 1 new again.
    function moonPhase(date) {
        const days = date.getTime() / 86400000 - knownNewMoon;
        return (((days % synodicMonth) + synodicMonth) % synodicMonth) / synodicMonth;
    }

    function moonName(phase) {
        return ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous", "Full moon",
            "Waning gibbous", "Last quarter", "Waning crescent"][Math.round(phase * 8) % 8];
    }
}
