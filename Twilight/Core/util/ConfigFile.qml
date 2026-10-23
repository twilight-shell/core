import QtQuick
import Quickshell
import Quickshell.Io
import "Toml.js" as Toml

// A settings file in TOML, ~/.config/twilight-shell/<name>.toml. A missing
// file reads as empty, so every setting needs a default at the place it is
// used. Edits made by hand apply as soon as the file is saved; a file that
// doesn't parse is reported in `error` and the last good values stay.
//
//     ConfigFile { id: config; name: "app-launcher" }
//     ... config.get("terminal", "xterm")        // reacts to changes
//     ... config.get("bar.height", 36)           // a key inside [bar]
//     config.set("terminal", "ghostty")          // writes it, comments kept
Scope {
    id: root

    // File name without the extension.
    property string name
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/twilight-shell"
    readonly property string path: dir + "/" + name + ".toml"

    // The parsed file; replaced as a whole on every change.
    property var data: ({})
    // What is wrong with the file, "" when nothing is.
    property string error: ""

    property string source: ""

    // The value at `key` ("table.key" or ["table", "key"]), or `fallback`.
    function get(key, fallback) {
        let at = data;
        for (const part of Array.isArray(key) ? key : String(key).split(".")) {
            if (at === null || typeof at !== "object" || !(part in at))
                return fallback;
            at = at[part];
        }
        return at ?? fallback;
    }

    // Writes `value` to `key`, creating the file and its table when needed.
    function set(key, value) {
        const parts = Array.isArray(key) ? key : String(key).split(".");
        const next = Toml.set(source, parts, value);
        if (!apply(next))
            return;
        pending = next;
        mkdir.running = true;
    }

    property string pending: ""

    function apply(text) {
        try {
            const parsed = Toml.parse(text);
            source = text;
            data = parsed;
            error = "";
            return true;
        } catch (e) {
            error = String(e.message ?? e);
            console.warn("twilight: " + path + ": " + error);
            return false;
        }
    }

    // The directory has to exist before the file can be written, and before
    // it can be watched: without it edits are never noticed, so make it at
    // startup and read the file again once it is there.
    Process {
        id: mkdir

        command: ["mkdir", "-p", root.dir]
        running: true
        onExited: {
            if (root.pending !== "") {
                file.setText(root.pending);
                root.pending = "";
            } else {
                file.reload();
            }
        }
    }

    FileView {
        id: file

        path: root.path
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            // Our own write comes back through the watcher: nothing to redo.
            if (text() !== root.source)
                root.apply(text());
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.source = "";
                root.data = ({});
                root.error = "";
            } else {
                root.error = "can't read the file";
            }
        }
    }
}
