import QtQuick
import Quickshell
import Quickshell.Io
import "Toml.js" as Toml

// A settings file in TOML, ~/.config/twilight-shell/<name>.toml. Edits made by
// hand apply as soon as the file is saved; a file that doesn't parse is
// reported in `error` and the last good values stay.
//
// The defaults are a TOML file shipped with the component, the only place they
// are written down. A missing settings file is created from them, so it shows
// every setting with the value in use. A key the file lacks, say one added by a
// later version, still reads its default.
//
//     ConfigFile {
//         id: config
//         name: "app-launcher"
//         defaults: Qt.resolvedUrl("app-launcher.defaults.toml")
//     }
//     ... config.get("terminal")                 // reacts to changes
//     ... config.get("bar.height")               // a key inside [bar]
//     config.set("terminal", "ghostty")          // writes it, comments kept
Scope {
    id: root

    // File name without the extension.
    property string name
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/twilight-shell"
    readonly property string path: dir + "/" + name + ".toml"

    // The component's defaults file; none means every `get` needs a fallback.
    property url defaults
    // The parsed defaults.
    property var defaultsData: ({})
    // The parsed file; replaced as a whole on every change.
    property var data: ({})
    // What is wrong with the file, "" when nothing is.
    property string error: ""

    property string source: ""

    // The value at `key` ("table.key" or ["table", "key"]) in the file, else in
    // the defaults, else `fallback`.
    function get(key, fallback) {
        const parts = Array.isArray(key) ? key : String(key).split(".");
        return Toml.lookup(data, parts) ?? Toml.lookup(defaultsData, parts) ?? fallback;
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
    // Set once the directory exists, so a missing file can be created.
    property bool dirReady: false
    // What a new file starts with; "" without defaults.
    property string template: ""

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
            root.dirReady = true;
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
                root.data = ({});
                root.error = "";
                if (root.dirReady && root.template !== "") {
                    root.source = root.template;
                    // Not from inside the failed load itself.
                    Qt.callLater(() => setText(root.template));
                } else {
                    root.source = "";
                }
            } else {
                root.error = "can't read the file";
            }
        }
    }

    FileView {
        id: defaultsFile

        // A url is file:///path; FileView wants the path.
        path: root.defaults.toString().replace(/^file:\/\//, "")
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.defaultsData = Toml.parse(text());
                root.template = Toml.template(text());
            } catch (e) {
                console.warn("twilight: " + path + ": " + e.message);
            }
        }
        onLoadFailed: {
            if (root.defaults.toString() !== "")
                console.warn("twilight: can't read the defaults " + path);
        }
    }
}
