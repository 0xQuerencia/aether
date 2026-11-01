import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    property bool failed: false
    property bool authenticating: false
    Timer { id: pamActionTimer; interval: 50; onTriggered: pam.start() }
    PamContext {
        id: pam
        Component.onCompleted: pamActionTimer.start()
        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                rootLock.locked = false;
                Qt.quit();
            } else {
                root.failed = true;
                pamActionTimer.start();
            }
        }
    }
    Process { id: suspendProcess; command: ["systemctl", "suspend"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    WlSessionLock {
        id: rootLock
        locked: true
        WlSessionLockSurface {
            LockView {
                anchors.fill: parent
                authenticating: root.authenticating
                failed: root.failed
                onSubmitted: response => {
                    if (pam.responseRequired && !root.authenticating) {
                        root.authenticating = true;
                        root.failed = false;
                        pam.respond(response);
                    }
                }
                onSuspendRequested: suspendProcess.running = true
                onRebootRequested: rebootProcess.running = true
                onPoweroffRequested: poweroffProcess.running = true
            }
        }
    }
}
