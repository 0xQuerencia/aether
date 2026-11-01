import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets


PanelWindow {
    id: ov
    required property var island

    readonly property bool open: island.niriOpen
    readonly property var monitor: Hyprland.monitorFor(screen)
    
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property real zoom: Prefs.p.overviewZoom         // card size relative to the screen (Settings › Appearance)
    readonly property int columns: width < island.s(1100) ? 2 : 3
    readonly property real cardW: Math.min(width * zoom, (width-island.s(128))/columns-island.s(24))
    readonly property real cardH: cardW * height / width
    readonly property real cardGap: island.s(34)
    readonly property real cardRadius: island.s(18)
    readonly property color cardColor: AetherStyle.surface(island.mocha)
    readonly property color cardBorder: Qt.rgba(1, 1, 1, 0.08)

    
    property var wsIds: []
    property int sel: 0                                     // keyboard-selected row
    property var dragWin: null                              // HyprlandToplevel being dragged
    property int dragWs: -1                                 // workspace id whose badge is being dragged
    property int dropRow: -1

    function close() { island.niriOpen = false; }
    function addr(t) { const a = t.address; return a.startsWith("0x") ? a : "0x" + a; }
    
    function dispatch(cmd) {
        const sp = cmd.indexOf(" ");
        const args = sp < 0 ? [cmd] : [cmd.substring(0, sp), "--", cmd.substring(sp + 1)];
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch"].concat(args));
    }

    function rebuild() {
        const ids = [];
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) {
            const w = all[i];
            if (w.id > 0 && (!ov.monitor || w.monitor === ov.monitor)) ids.push(w.id);
        }
        ids.sort((a, b) => a - b);
        ids.push(ids.length ? ids[ids.length - 1] + 1 : 1);
        wsIds = ids;
    }
    function wsById(id) {
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) if (all[i].id === id) return all[i];
        return null;
    }
    function windowsOf(id) {
        const out = [], all = Hyprland.toplevels.values;
        for (let i = 0; i < all.length; i++) if (all[i].workspace && all[i].workspace.id === id) out.push(all[i]);
        return out;
    }
    function goTo(id) { dispatch("workspace " + id); close(); }
    function focusWin(t) { dispatch("focuswindow address:" + addr(t)); close(); }
    function moveWin(t, id) {
        if (t.workspace && t.workspace.id === id) return;
        dispatch("movetoworkspacesilent " + id + ",address:" + addr(t));
        refresh.restart();
    }
    
    function swapWs(a, b) {
        if (a === b) return;
        const wa = windowsOf(a), wb = windowsOf(b);
        for (let i = 0; i < wa.length; i++) dispatch("movetoworkspacesilent " + b + ",address:" + addr(wa[i]));
        for (let i = 0; i < wb.length; i++) dispatch("movetoworkspacesilent " + a + ",address:" + addr(wb[i]));
        refresh.restart();
    }
    function rowAt(sceneX, sceneY) {
        const p = list.mapFromItem(null, sceneX, sceneY);
        const idx = list.indexAt(p.x + list.contentX, p.y + list.contentY);
        return idx;
    }

    Timer { id: refresh; interval: 120; onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces(); settle.restart(); } }
    Timer { id: settle; interval: 150; onTriggered: { const keep = ov.wsIds[ov.sel]; ov.rebuild(); const i = ov.wsIds.indexOf(keep); ov.sel = i >= 0 ? i : Math.min(ov.sel, ov.wsIds.length - 1); if (!ov.centred) ov.centreFocused(); } }
    property bool centred: false
    function centreFocused() {
        const cur = ov.monitor && ov.monitor.activeWorkspace ? wsIds.indexOf(ov.monitor.activeWorkspace.id) : -1;
        sel = Math.max(0, cur);
        centred = cur >= 0;
        Qt.callLater(() => list.positionViewAtIndex(ov.sel, GridView.Contain));   // after delegates are laid out
    }

    onOpenChanged: {
        if (!open) { dragWin = null; dragWs = -1; dropRow = -1; centred = false; return; }
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        rebuild();
        centreFocused();
        refresh.restart();          // re-read once the async refresh has landed (positions/workspaces)
        keys.forceActiveFocus();
    }
    Connections {
        target: Hyprland
        enabled: ov.open
        function onRawEvent(ev) {
            if (["openwindow", "closewindow", "movewindowv2", "createworkspacev2", "destroyworkspacev2"].indexOf(ev.name) !== -1) refresh.restart();
        }
    }

    Item {
        id: fade
        anchors.fill: parent

        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.62)
            MouseArea { anchors.fill: parent; onClicked: ov.close(); onWheel: w => list.flick(0, w.angleDelta.y * 12) }
        }

        Text {
            anchors.left: parent.left; anchors.leftMargin: island.s(64)
            anchors.top: parent.top; anchors.topMargin: island.s(42)
            text: "Workspaces"; color: island.mocha.text; font.family: "Inter"; font.pixelSize: island.s(28); font.weight: Font.DemiBold
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: island.s(160)
            anchors.top: parent.top; anchors.topMargin: island.s(52)
            text: (ov.monitor ? ov.monitor.name : "") + "  ·  " + Math.max(0,ov.wsIds.length-1) + " workspaces"
            color: island.mocha.overlay0; font.family: "Inter"; font.pixelSize: island.s(12)
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: island.s(64)
            anchors.top: parent.top; anchors.topMargin: island.s(50)
            text: "Close ×"; font.family: "Inter"; font.pixelSize: island.s(13); color: island.mocha.subtext0
            MouseArea { anchors.fill: parent; onClicked: ov.close() }
        }
        GridView {
            id: list
            anchors.horizontalCenter: parent.horizontalCenter
            y: island.s(114)
            width: parent.width-island.s(128)
            height: parent.height-island.s(190)
            cellWidth: width/ov.columns
            cellHeight: ov.cardH+island.s(76)
            model: ov.wsIds
            clip: true
            interactive: ov.dragWin === null && ov.dragWs < 0
            currentIndex: ov.sel
            highlightMoveDuration: Prefs.duration(AetherStyle.motionPanel)
            onCurrentIndexChanged: positionViewAtIndex(currentIndex,GridView.Contain)

            delegate: Item {
                id: row
                required property int modelData
                required property int index
                readonly property int wsId: modelData
                readonly property bool isEmptySlot: index === ov.wsIds.length - 1
                readonly property bool isFocused: ov.monitor && ov.monitor.activeWorkspace && ov.monitor.activeWorkspace.id === wsId
                readonly property bool isDrop: ov.dropRow === index && (ov.dragWin !== null || ov.dragWs >= 0)
                width: list.cellWidth
                height: list.cellHeight

                
                Rectangle {
                    id: badge
                    anchors.left: card.left
                    anchors.top: parent.top; anchors.topMargin: island.s(8)
                    width: island.s(34); height: width; radius: width / 2
                    visible: !row.isEmptySlot
                    color: row.isFocused ? island.accent : Qt.rgba(1, 1, 1, badgeMouse.containsMouse ? 0.16 : 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: row.wsId
                        font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(14)
                        color: row.isFocused ? "#0d0d0d" : "#e6e6e6"
                    }
                    MouseArea {
                        id: badgeMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.OpenHandCursor
                        preventStealing: true
                        onPressed: { ov.dragWs = row.wsId; ghost.label = "Workspace " + row.wsId; ghost.src = null; }
                        onPositionChanged: m => { if (ov.dragWs >= 0) { const p = mapToItem(null, m.x, m.y); ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2; ov.dropRow = ov.rowAt(p.x, p.y); } }
                        onReleased: {
                            const target = ov.dropRow >= 0 && ov.dropRow < ov.wsIds.length ? ov.wsIds[ov.dropRow] : -1;
                            if (target > 0 && ov.dragWs > 0) ov.swapWs(ov.dragWs, target);
                            ov.dragWs = -1; ov.dropRow = -1;
                        }
                    }
                }

                Text {
                    anchors.left: card.left; anchors.leftMargin: island.s(46)
                    anchors.top: parent.top; anchors.topMargin: island.s(15)
                    text: row.isEmptySlot ? "New workspace" : ov.windowsOf(row.wsId).length + (ov.windowsOf(row.wsId).length === 1 ? " window" : " windows") + (row.isFocused ? " · active" : "")
                    color: island.mocha.subtext0; font.family: "Inter"; font.pixelSize: island.s(12)
                }
                ClippingRectangle {
                    id: card
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(16)
                    width: ov.cardW; height: ov.cardH
                    radius: ov.cardRadius
                    color: ov.cardColor
                    border.width: row.isDrop ? island.s(3) : (row.index === ov.sel ? island.s(2) : 1)
                    border.color: row.isDrop ? island.accent : (row.index === ov.sel ? island.accent : ov.cardBorder)
                    scale: row.index === ov.sel ? 1.0 : 0.98
                    opacity: ov.dragWs === row.wsId ? 0.45 : 1
                    Behavior on scale { NumberAnimation { duration: Prefs.duration(180); easing.type: Easing.OutCubic } }

                    MouseArea { anchors.fill: parent; onClicked: ov.goTo(row.wsId) }

                    Text {
                        anchors.centerIn: parent
                        visible: winRep.count === 0
                        text: row.isEmptySlot ? "+" : "Empty"
                        font.family: "Inter"; font.pixelSize: island.s(row.isEmptySlot ? 30 : 13)
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }

                    Repeater {
                        id: winRep
                        model: ov.open ? ov.windowsOf(row.wsId) : []
                        delegate: Item {
                            id: win
                            required property var modelData
                            readonly property var ipc: modelData.lastIpcObject || {}
                            readonly property real k: ov.cardW / ov.width
                            readonly property real mx: ov.monitor ? ov.monitor.x : 0
                            readonly property real my: ov.monitor ? ov.monitor.y : 0
                            x: ipc.at ? (ipc.at[0] - mx) * k : 0
                            y: ipc.at ? (ipc.at[1] - my) * k : 0
                            width: ipc.size ? Math.max(island.s(24), ipc.size[0] * k) : ov.cardW / 2
                            height: ipc.size ? Math.max(island.s(18), ipc.size[1] * k) : ov.cardH / 2
                            opacity: ov.dragWin === modelData ? 0.3 : 1

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: island.s(8)
                                color: "#1b1b1b"
                                border.width: winMouse.containsMouse ? 2 : 0
                                border.color: island.accent
                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: ov.open ? win.modelData.wayland : null
                                    live: true
                                }
                            }
                            MouseArea {
                                id: winMouse
                                anchors.fill: parent; hoverEnabled: true
                                preventStealing: true
                                property point pressAt
                                property bool didDrag: false
                                onPressed: m => { pressAt = Qt.point(m.x, m.y); didDrag = false; }
                                onPositionChanged: m => {
                                    if (!pressed) return;
                                    if (ov.dragWin === null && Math.hypot(m.x - pressAt.x, m.y - pressAt.y) > 8) {
                                        didDrag = true;
                                        ov.dragWin = win.modelData;
                                        ghost.src = win.modelData.wayland;
                                        ghost.label = win.modelData.title;
                                    }
                                    if (ov.dragWin !== null) {
                                        const p = mapToItem(null, m.x, m.y);
                                        ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2;
                                        ov.dropRow = ov.rowAt(p.x, p.y);
                                    }
                                }
                                onReleased: {
                                    if (ov.dragWin !== null) {
                                        const target = ov.dropRow >= 0 && ov.dropRow < ov.wsIds.length ? ov.wsIds[ov.dropRow] : -1;
                                        if (target > 0) ov.moveWin(ov.dragWin, target);
                                        ov.dragWin = null; ov.dropRow = -1;
                                    }
                                }
                                onClicked: if (!didDrag && ov.dragWin === null) ov.focusWin(win.modelData)
                            }
                        }
                    }
                }
            }
        }

        
        Rectangle {
            id: ghost
            property var src: null
            property string label: ""
            visible: ov.dragWin !== null || ov.dragWs >= 0
            width: ov.cardW * 0.42; height: ov.cardH * 0.42
            radius: island.s(12)
            color: "#1b1b1b"
            border.width: 2; border.color: island.accent
            z: 100
            ScreencopyView { anchors.fill: parent; anchors.margins: 2; captureSource: ghost.visible ? ghost.src : null; live: true; visible: ghost.src !== null }
            Text {
                anchors.centerIn: parent; visible: ghost.src === null
                width: parent.width - island.s(16); elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                text: ghost.label; color: "#e6e6e6"
                font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(15)
            }
        }

        
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(22)
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Click to open  ·  drag a window to move it  ·  drag a number to swap workspaces  ·  ←↑↓→ to select  ·  Enter to open  ·  Esc to close"
            font.family: "Inter"; font.pixelSize: island.s(12)
            color: Qt.rgba(1, 1, 1, 0.45)
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            const n = ov.wsIds.length;
            if (e.key === Qt.Key_Escape || (e.key === Qt.Key_Tab && (e.modifiers & Qt.MetaModifier))) { ov.close(); e.accepted = true; }
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) {
                if (e.modifiers & Qt.ControlModifier && ov.sel >= ov.columns) { ov.swapWs(ov.wsIds[ov.sel], ov.wsIds[ov.sel - ov.columns]); }
                ov.sel = Math.max(0, ov.sel - ov.columns); e.accepted = true;
            }
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) {
                if (e.modifiers & Qt.ControlModifier && ov.sel + ov.columns < n) { ov.swapWs(ov.wsIds[ov.sel], ov.wsIds[ov.sel + ov.columns]); }
                ov.sel = Math.min(n - 1, ov.sel + ov.columns); e.accepted = true;
            }
            else if (e.key === Qt.Key_Left) { ov.sel=Math.max(0,ov.sel-1);e.accepted=true; }
            else if (e.key === Qt.Key_Right) { ov.sel=Math.min(n-1,ov.sel+1);e.accepted=true; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { ov.goTo(ov.wsIds[ov.sel]); e.accepted = true; }
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) { ov.goTo(e.key - Qt.Key_0); e.accepted = true; }
        }
    }
}
