import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    // Omarchy injects these properties into third-party entry points.
    property string omarchyPath: ""
    property var shell: null
    property var manifest: null
    property var pluginRegistry: null

    readonly property string pluginDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
    readonly property string controlScript: pluginDir + "/scripts/omaglowctl"

    onPluginDirChanged: {
        if (pluginDir)
            reapplyTimer.restart();
    }

    function apply() {
        if (!pluginDir || applyProcess.running)
            return;
        applyProcess.exec([controlScript, "apply"]);
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim();
                if (message)
                    console.info("Omaglow: " + message);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(text || "").trim();
                if (message)
                    console.warn("Omaglow: " + message);
            }
        }
    }

    Timer {
        id: reapplyTimer
        interval: 75
        repeat: false
        onTriggered: root.apply()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                reapplyTimer.restart();
        }
    }

    Component.onDestruction: {
        if (pluginDir)
            Quickshell.execDetached([controlScript, "reset"]);
    }
}
