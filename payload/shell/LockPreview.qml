import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        title: "Aether lock design preview"
        implicitWidth: 1280; implicitHeight: 720
        LockView { anchors.fill: parent; preview: true; previewInput: Quickshell.env("AETHER_PREVIEW_ENTRY") === "1" }
    }
    Timer { interval: 15000; running: true; onTriggered: Qt.quit() }
}
