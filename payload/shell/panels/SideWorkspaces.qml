


import QtQuick
import QtQuick.Effects
import Quickshell
import ".."
import "wheelstep.js" as WheelStep

Rectangle {
    id: ws
    required property var island

    readonly property bool active: !Prefs.p.aetherIsland && Prefs.p.sideWorkspaces && !island.wsFullscreen && !island.gameMode
    readonly property real dot: island.s(8)
    readonly property real activeW: island.s(26)
    
    
    readonly property real wheelPixelStepThreshold: 22
    readonly property real wheelNoiseFloor: 0.01
    readonly property int wheelIdleResetMs: 250
    readonly property int wheelStepCooldownMs: 120
    readonly property int pendingSettleMs: 600
    property var wheelState: WheelStep.createState()
    property int pendingIndex: -1
    property var pendingExpectedIndices: []
    readonly property int displayActiveIndex: pendingIndex >= 0 ? pendingIndex : island.workspacesModel.activeIndex

    
    function tint(amount, alpha) {
        const a = island.accent;
        return Qt.rgba(a.r + (1 - a.r) * amount, a.g + (1 - a.g) * amount, a.b + (1 - a.b) * amount, alpha);
    }
    readonly property color ink: tint(0.55, 1)

    function dispatchWorkspaceStep(direction) {
        const model = island.workspacesModel;
        const count = model.count;
        if (count <= 0)
            return;

        const activeIndex = Math.max(0, Math.min(model.activeIndex, count - 1));
        const baseIndex = pendingIndex >= 0 ? pendingIndex : activeIndex;
        const targetIndex = Math.max(0, Math.min(baseIndex + direction, count - 1));
        if (targetIndex === baseIndex)
            return;

        if (pendingIndex < 0)
            pendingExpectedIndices = [];
        pendingIndex = targetIndex;
        pendingExpectedIndices = pendingExpectedIndices.concat([targetIndex]);
        pendingSettleTimer.restart();
        
        const targetId = String(model.get(targetIndex).wsId || "");
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", targetId !== "" ? targetId : (direction > 0 ? "e+1" : "e-1")]);
    }

    function clearPendingIndex() {
        pendingSettleTimer.stop();
        pendingIndex = -1;
        pendingExpectedIndices = [];
    }

    function wheelThreshold(mode) {
        return wheelPixelStepThreshold;   // normalizeDelta puts every event on the pixel scale
    }

    function scheduleWheelDrain() {
        if (wheelState.mode === "" || Math.abs(wheelState.accumulator) < wheelThreshold(wheelState.mode)) {
            wheelDrainTimer.stop();
            return;
        }

        const remaining = wheelState.lastStepAt === null
                ? 1
                : Math.max(1, wheelStepCooldownMs - (Date.now() - wheelState.lastStepAt));
        wheelDrainTimer.interval = remaining;
        wheelDrainTimer.restart();
    }

    function applyWheelOutcome(outcome) {
        wheelState = outcome.state;
        if (outcome.step !== 0)
            dispatchWorkspaceStep(outcome.step);
        scheduleWheelDrain();
    }

    x: island.s(Prefs.p.topGap)
    y: island.topMargin
    height: island.pillHeight
    width: dots.implicitWidth + island.s(30)
    radius: height / 2
    color: "transparent"   // floats on the wallpaper; the shadow keeps it legible
    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(300); easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.phase === Qt.ScrollMomentum) {
                ws.wheelState = WheelStep.clear(ws.wheelState);
                wheelDrainTimer.stop();
                return;
            }

            const selected = WheelStep.normalizeDelta(
                event.pixelDelta.x, event.pixelDelta.y,
                event.angleDelta.x, event.angleDelta.y, ws.wheelPixelStepThreshold);
            if (selected.mode === "")
                return;

            const result = WheelStep.advance(
                ws.wheelState, selected.delta, selected.mode, Date.now(),
                ws.wheelThreshold(selected.mode), ws.wheelIdleResetMs,
                ws.wheelStepCooldownMs, ws.wheelNoiseFloor);
            ws.applyWheelOutcome(result);
        }
    }

    Timer {
        id: wheelDrainTimer
        interval: ws.wheelStepCooldownMs
        repeat: false
        onTriggered: {
            const threshold = ws.wheelThreshold(ws.wheelState.mode);
            const result = WheelStep.drain(
                ws.wheelState, Date.now(), threshold,
                ws.wheelIdleResetMs, ws.wheelStepCooldownMs);
            ws.applyWheelOutcome(result);
        }
    }

    Timer {
        id: pendingSettleTimer
        interval: ws.pendingSettleMs
        repeat: false
        onTriggered: {
            ws.pendingIndex = -1;
            ws.pendingExpectedIndices = [];
        }
    }

    Connections {
        target: ws.island.workspacesModel
        function onActiveIndexChanged() {
            if (ws.pendingIndex < 0)
                return;

            const actualIndex = ws.island.workspacesModel.activeIndex;
            const completedAt = ws.pendingExpectedIndices.indexOf(actualIndex);
            if (completedAt < 0) {
                ws.clearPendingIndex();
                return;
            }

            ws.pendingExpectedIndices = ws.pendingExpectedIndices.slice(completedAt + 1);
            if (actualIndex === ws.pendingIndex && ws.pendingExpectedIndices.length === 0)
                ws.clearPendingIndex();
        }
        function onCountChanged() {
            if (ws.pendingIndex >= ws.island.workspacesModel.count) {
                ws.clearPendingIndex();
            }
        }
    }

    Row {
        id: dots
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.75
            shadowBlur: 0.6
            shadowVerticalOffset: 1
        }
        spacing: ws.island.s(7)
        Repeater {
            model: ws.island.workspacesModel
            delegate: Rectangle {
                id: pip
                required property int index
                required property string wsId
                required property string wsState
                readonly property bool isActive: index === ws.displayActiveIndex
                readonly property bool isOccupied: wsState === "occupied"
                anchors.verticalCenter: parent.verticalCenter
                width: isActive ? ws.activeW : ws.dot
                height: ws.dot
                radius: height / 2
                color: isActive ? ws.ink
                       : ws.tint(0.7, pipMouse.containsMouse ? 0.9 : isOccupied ? 0.65 : 0.32)
                Behavior on width { NumberAnimation { duration: Prefs.duration(260); easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                Behavior on color { ColorAnimation { duration: Prefs.duration(180)} }
                MouseArea {
                    id: pipMouse
                    
                    anchors.fill: parent
                    anchors.margins: -ws.island.s(6)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", pip.wsId])
                }
            }
        }
    }
}
