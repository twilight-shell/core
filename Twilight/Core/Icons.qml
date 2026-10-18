pragma Singleton

import QtQuick
import Quickshell

// Icon lookup with a chain of candidates. Quickshell.iconPath(name, fallback)
// still yields a "missing texture" when neither exists, so callers ask for
// the first icon that really exists and draw their own stand-in otherwise.
Singleton {
    // First of `names` that is a file, a URL or an icon in the theme, as an
    // image source; "" when none is.
    function find(names) {
        for (const name of names) {
            if (!name)
                continue;
            if (name.startsWith("/"))
                return "file://" + name;
            if (name.includes("://"))
                return name;
            const path = Quickshell.iconPath(name, true);
            if (path !== "")
                return path;
        }
        return "";
    }
}
