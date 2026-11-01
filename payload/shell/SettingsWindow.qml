// Settings
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "settings" as NetPages


PanelWindow {
    id: win
    required property var island
    readonly property bool open: island.settingsOpen

    
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    
    readonly property color bgWin: "#0b0b0b"
    readonly property color bgCard: "#151515"
    readonly property color bgField: "#1b1b1b"
    readonly property color bgSel: "#232323"
    readonly property color line: Qt.rgba(1, 1, 1, 0.055)
    readonly property color txt: "#ececec"
    readonly property color sub: "#9a9a9a"
    readonly property color dim: "#6f6f6f"
    readonly property color track: "#2b2b2b"
    readonly property color acc: island.accent
    readonly property string ui: "Inter"
    readonly property string icons: "Iosevka Nerd Font"
    function s(v) { return island.s(v); }

    readonly property var pages: [
        { id: "island", name: "Bar & Island", icon: "󰍹", desc: "Shape and size of the island and what the idle pill shows.", rows: [
            { t: "toggle", label: "Aether attached island (off: original pill)", key: "aetherIsland" },
            { t: "slider", label: "Original pill height", key: "barHeight", min: 28, max: 56, step: 1, unit: "px" },
            { t: "slider", label: "Original pill width", key: "collapsedWidth", min: 100, max: 260, step: 2, unit: "px" },
            { t: "slider", label: "Original pill gap from screen edge", key: "topGap", min: 0, max: 40, step: 1, unit: "px" },
            { t: "slider", label: "Original pill expanded radius", key: "expandedRadius", min: 8, max: 48, step: 1, unit: "px" },
            { t: "toggle", label: "Original pill status circle (battery and Wi-Fi)", key: "statusCircle" },
            { t: "toggle", label: "Original pill workspace dots (top left)", key: "sideWorkspaces" },
            { t: "toggle", label: "Original pill CPU / RAM / temp meters (top right)", key: "sideMeters" },
            { t: "toggle", label: "Original pill album art circle", key: "albumArt" },
            { t: "toggle", label: "Original pill earbud / headphone battery", key: "btBattery" } ] },
        { id: "clock", name: "Clock & Date", icon: "󰥔", desc: "How the island's clock and date read.", rows: [
            { t: "toggle", label: "24-hour clock", key: "clock24h" },
            { t: "toggle", label: "Show seconds", key: "clockSeconds" },
            { t: "choice", label: "Date format", key: "dateFormat", options: [
                { v: "ddd, MMM d", l: "Mon, Sep 29" }, { v: "dddd d MMMM", l: "Monday 29 September" },
                { v: "dd/MM/yyyy", l: "29/09/2026" }, { v: "yyyy-MM-dd", l: "2026-09-29" } ] } ] },
        { id: "appearance", name: "Appearance", icon: "󰏘", desc: "Scale, wallpaper and theme.", rows: [
            { t: "slider", label: "Interface scale", key: "ext:uiScale", min: 0.8, max: 1.4, step: 0.05, unit: "×" },
            { t: "slider", label: "Overview card size", key: "overviewZoom", min: 0.2, max: 0.45, step: 0.01, unit: "×" },
            { t: "button", label: "Wallpaper", button: "Open picker", act: "wallpaper" },
            { t: "button", label: "Colour palette", button: "Open palettes", act: "palette" },
            { t: "toggle", label: "Wallpaper slideshow", key: "slideshow" },
            { t: "slider", label: "Change wallpaper every", key: "slideshowMinutes", min: 5, max: 180, step: 5, unit: "min" },
            { t: "button", label: "Next wallpaper", button: "Shuffle", act: "nextWallpaper" } ] },
        { id: "display", name: "Display", icon: "󰍹", desc: "Refresh rate, brightness and night light for the laptop screen.", rows: [
            { t: "choice", label: "Refresh rate", key: "hy:rate", options: [ { v: 60, l: "60 Hz" }, { v: 144, l: "144 Hz" } ] },
            { t: "toggle", label: "60 Hz on battery, back up when plugged in", key: "autoRefresh" },
            { t: "slider", label: "Brightness", key: "ext:brightness", min: 5, max: 100, step: 1, unit: "%" },
            { t: "toggle", label: "Night light", key: "island:nightLight" },
            { t: "choice", label: "Adaptive sync (VRR)", key: "hy:misc:vrr", options: [ { v: 0, l: "Off" }, { v: 1, l: "On" }, { v: 2, l: "Fullscreen only" } ] } ] },
        { id: "wifi", name: "Wi-Fi", icon: "󰤨", desc: "Wireless networks and the current connection.", rows: [
            { t: "info", label: "Wireless radio", value: "Wi-Fi" },
            { t: "info", label: "Current connection", value: "SSID, signal and IP" },
            { t: "info", label: "Available networks", value: "Connect or forget" } ] },
        { id: "bluetooth", name: "Bluetooth", icon: "󰂯", desc: "Adapter power, discoverability and nearby devices.", rows: [
            { t: "info", label: "Adapter power", value: "On or off" },
            { t: "info", label: "Discoverability", value: "Visible to nearby devices" },
            { t: "info", label: "Devices", value: "Pair, connect or remove" } ] },
        { id: "windows", name: "Windows", icon: "󰖯", desc: "Gaps, corners, transparency, blur and effects for app windows.", rows: [
            { t: "slider", label: "Gaps between windows", key: "hy:general:gaps_in", min: 0, max: 30, step: 1, unit: "px" },
            { t: "slider", label: "Gaps around the screen edge", key: "hy:general:gaps_out", min: 0, max: 48, step: 1, unit: "px" },
            { t: "slider", label: "Corner rounding", key: "hy:decoration:rounding", min: 0, max: 32, step: 1, unit: "px" },
            { t: "slider", label: "Border width", key: "hy:general:border_size", min: 0, max: 6, step: 1, unit: "px" },
            { t: "slider", label: "Window opacity (focused)", key: "hy:decoration:active_opacity", min: 0.5, max: 1.0, step: 0.01, unit: "" },
            { t: "slider", label: "Window opacity (unfocused)", key: "hy:decoration:inactive_opacity", min: 0.5, max: 1.0, step: 0.01, unit: "" },
            { t: "slider", label: "Terminal transparency (new terminals)", key: "hy:footAlpha", min: 0.3, max: 1.0, step: 0.01, unit: "" },
            { t: "toggle", label: "Blur behind windows", key: "hy:decoration:blur:enabled" },
            { t: "slider", label: "Blur strength", key: "hy:decoration:blur:size", min: 1, max: 40, step: 1, unit: "px" },
            { t: "slider", label: "Blur passes", key: "hy:decoration:blur:passes", min: 1, max: 6, step: 1, unit: "" },
            { t: "toggle", label: "Shadows", key: "hy:decoration:shadow:enabled" },
            { t: "toggle", label: "Dim unfocused windows", key: "hy:decoration:dim_inactive" },
            { t: "toggle", label: "Window animations", key: "hy:animations:enabled" } ] },
        { id: "input", name: "Input", icon: "󰟸", desc: "Touchpad, pointer and keyboard.", rows: [
            { t: "slider", label: "Touchpad scroll speed", key: "hy:input:touchpad:scroll_factor", min: 0.1, max: 1.5, step: 0.05, unit: "×" },
            { t: "toggle", label: "Natural scrolling", key: "hy:input:touchpad:natural_scroll" },
            { t: "toggle", label: "Tap to click", key: "hy:input:touchpad:tap-to-click" },
            { t: "toggle", label: "Disable touchpad while typing", key: "hy:input:touchpad:disable_while_typing" },
            { t: "slider", label: "Pointer speed", key: "hy:input:sensitivity", min: -1.0, max: 1.0, step: 0.05, unit: "" },
            { t: "slider", label: "Key repeat rate", key: "hy:input:repeat_rate", min: 10, max: 60, step: 1, unit: "/s" },
            { t: "slider", label: "Key repeat delay", key: "hy:input:repeat_delay", min: 150, max: 800, step: 10, unit: "ms" } ] },
        { id: "motion", name: "Motion", icon: "󰑓", desc: "Interface motion and transition speed.", rows: [
            { t: "toggle", label: "Reduce interface motion", key: "reducedMotion" },
            { t: "slider", label: "Animation duration", key: "animScale", min: 0.4, max: 2.0, step: 0.05, unit: "×" } ] },
        { id: "launcher", name: "Launcher", icon: "󰍉", desc: "The Spotlight-style app launcher.", rows: [
            { t: "slider", label: "Maximum results", key: "launcherResults", min: 3, max: 10, step: 1, unit: "" } ] },
        { id: "notifications", name: "Notifications", icon: "󰂚", desc: "Popups in the island.", rows: [
            { t: "toggle", label: "Do not disturb (Focus)", key: "island:dnd" },
            { t: "slider", label: "Popup duration", key: "notifSeconds", min: 2, max: 10, step: 0.5, unit: "s" },
            { t: "toggle", label: "Screenshot preview card in the island", key: "shotPreview" },
            { t: "toggle", label: "Edit every screenshot before saving (arrows, blur, text…)", key: "shotAnnotate" } ] },
        { id: "power", name: "Power", icon: "󰌪", desc: "Battery saver: power-saver profile, effects and keyboard backlight off.", rows: [
            { t: "toggle", label: "Battery saver", key: "island:batSaver" },
            { t: "toggle", label: "Turn on automatically when unplugged", key: "batterySaverAuto" },
            { t: "toggle", label: "Drop to 60 Hz in battery saver", key: "batterySaverRefresh" },
            { t: "choice", label: "Power profile", key: "ext:profile", options: [
                { v: "power-saver", l: "Saver" }, { v: "balanced", l: "Balanced" }, { v: "performance", l: "Performance" } ] } ] },
        { id: "shortcuts", name: "Shortcuts", icon: "󰌌", desc: "Keyboard shortcuts for everything in this rice.", rows: [
            { t: "info", label: "Settings", value: "Super + I" },
            { t: "info", label: "App launcher", value: "Alt + Space" },
            { t: "info", label: "Workspace overview", value: "Super + Tab" },
            { t: "info", label: "Clipboard history", value: "Super + V" },
            { t: "info", label: "Emoji picker", value: "Super + ." },
            { t: "info", label: "Task manager", value: "Super + Shift + Esc" },
            { t: "info", label: "Power menu", value: "Super + Esc" },
            { t: "info", label: "Wallpaper picker", value: "Alt + W" },
            { t: "info", label: "Random wallpaper", value: "Alt + D" },
            { t: "info", label: "Screenshot a region", value: "Super + Shift + S" },
            { t: "info", label: "Screenshot a region and edit it first", value: "Super + Shift + Alt + S" },
            { t: "info", label: "Screenshot the screen", value: "Print" },
            { t: "info", label: "Record the screen", value: "Super + Alt + R" },
            { t: "info", label: "Colour picker", value: "Super + Shift + C" },
            { t: "info", label: "Game mode", value: "Super + G" },
            { t: "info", label: "Battery saver", value: "Super + Alt + B" },
            { t: "info", label: "Night light (not captured in screenshots)", value: "Super + Shift + B" },
            { t: "info", label: "Lock", value: "Super + L" },
            { t: "info", label: "Terminal / browser / files", value: "Super + T / W / E" },
            { t: "info", label: "Close / fullscreen / float window", value: "Super + Q / F / Alt+Space" },
            { t: "info", label: "Panic: revert the rice to its safe point", value: "Super + Shift + A" } ] },
        { id: "system", name: "System", icon: "󰒓", desc: "Shell and configuration.", rows: [
            { t: "button", label: "Reload the shell", button: "Reload", act: "reloadShell" },
            { t: "button", label: "Configuration folder", button: "Open", act: "openConfig" },
            { t: "button", label: "Reset every setting on this list", button: "Reset", act: "resetAll" } ] }
    ]
    property int page: 0
    property var backStack: []
    property var fwdStack: []
    property string query: ""
    function go(i) { if (i === page) return; backStack = backStack.concat([page]); fwdStack = []; page = i; query = ""; search.text = ""; }
    function back() { if (!backStack.length) return; fwdStack = fwdStack.concat([page]); page = backStack[backStack.length - 1]; backStack = backStack.slice(0, -1); }
    function fwd() { if (!fwdStack.length) return; backStack = backStack.concat([page]); page = fwdStack[fwdStack.length - 1]; fwdStack = fwdStack.slice(0, -1); }
    function close() { island.settingsOpen = false; }

    
    readonly property var shownRows: {
        if (!query) return pages[page].rows;
        const q = query.toLowerCase(), out = [];
        for (const pg of pages) for (const r of pg.rows)
            if (r.label.toLowerCase().includes(q) || pg.name.toLowerCase().includes(q)) out.push(Object.assign({ page: pg.name }, r));
        return out;
    }

    
    property var ext: ({})
    property var hy: ({})           // Hyprland options + rate/footAlpha, read by hyprset.py on open
    property var hyPending: ({})
    readonly property string hyprset: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/settings/hyprset.py"
    readonly property var hyKeys: {
        const out = [];
        for (const pg of pages) for (const r of pg.rows) if (r.key && r.key.startsWith("hy:")) out.push(r.key.slice(3));
        return out;
    }
    function val(key) {
        if (key.startsWith("island:")) return island[key.slice(7)];
        if (key.startsWith("ext:")) return ext[key.slice(4)];
        if (key.startsWith("hy:")) return hy[key.slice(3)];
        return Prefs.p[key];
    }
    function setVal(key, v) {
        if (key === "island:dnd") { if (island.dnd !== v) island.toggleDnd(); return; }
        if (key === "island:batSaver") { if (island.batSaver !== v) island.toggleBatSaver(); return; }
        if (key === "island:nightLight") { if (island.nightLight !== v) island.toggleNightLight(); return; }
        if (key.startsWith("hy:")) {
            const k = key.slice(3), nh = Object.assign({}, hy), np = Object.assign({}, hyPending);
            nh[k] = v; np[k] = v; hy = nh; hyPending = np;
            hyFlush.restart();
            return;
        }
        if (!key.startsWith("ext:")) { Prefs.p[key] = v; return; }
        const k = key.slice(4), next = Object.assign({}, ext); next[k] = v; ext = next;
        if (k === "uiScale") writeUiScale.exec(["python3", "-c",
            "import json,sys,os;p=os.path.expanduser('~/.config/hypr/settings.json');d=json.load(open(p));d['uiScale']=round(float(sys.argv[1]),2);t=p+'.tmp';json.dump(d,open(t,'w'),indent=2);os.replace(t,p)", String(v)]);
        else if (k === "brightness") island.setBrightness(v);
        else if (k === "profile") { island.powerProfile = v; Quickshell.execDetached(["powerprofilesctl", "set", v]); }
    }
    function action(a) {
        if (a === "palette") { close(); island.paletteOpen = true; return; }
        if (a === "wallpaper") { close(); island.openWallpaper(); }
        if (a === "nextWallpaper") Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-slideshow.sh", "next"]);
        else if (a === "reloadShell") Quickshell.execDetached(["systemctl", "--user", "restart", "aether-shell.service"]);
        else if (a === "openConfig") { close(); Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/hypr"]); }
        else if (a === "resetAll") for (const k in Prefs.defaults) Prefs.reset(k);
    }

    
    Process {
        id: readExt
        command: ["python3", "-c",
            "import json,os,tomllib\n" +
            "h=os.path.expanduser('~')\n" +
            "try: ui=json.load(open(h+'/.config/hypr/settings.json')).get('uiScale',1.0)\nexcept Exception: ui=1.0\n" +
            "import subprocess\n" +
            "def sh(*a):\n    try: return subprocess.run(a,capture_output=True,text=True,timeout=2).stdout.strip()\n    except Exception: return ''\n" +
            "b=sh('brightnessctl','-m').split(',')\n" +
            "print(json.dumps({'brightness':int(b[3].rstrip('%')) if len(b)>3 else None,'profile':sh('powerprofilesctl','get'),'uiScale':ui}))"]
        stdout: StdioCollector { onStreamFinished: { try { win.ext = JSON.parse(this.text); } catch (e) {} } }
    }
    Process { id: writeUiScale }
    
    Process {
        id: readHy
        command: ["python3", win.hyprset, "get"].concat(win.hyKeys)
        stdout: StdioCollector { onStreamFinished: { try { win.hy = JSON.parse(this.text); } catch (e) {} } }
    }
    Timer {
        id: hyFlush; interval: 150
        onTriggered: {
            if (!Object.keys(win.hyPending).length) return;
            Quickshell.execDetached(["python3", win.hyprset, "set", JSON.stringify(win.hyPending)]);
            win.hyPending = {};
        }
    }

    onOpenChanged: if (open) { readExt.running = true; readHy.running = true; search.forceActiveFocus(); }

    // Controls
    component RowBase: Item {
        property var row: ({ t: "", label: "", key: "", min: 0, max: 1, step: 1, unit: "", options: [], button: "", act: "", value: "" })
        width: parent ? parent.width : 0
        implicitHeight: row.t === "slider" ? win.s(64) : win.s(48)
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: win.line; visible: !last }
        property bool last: false
        Text {
            id: lbl
            anchors.left: parent.left; anchors.leftMargin: win.s(16)
            y: row.t === "slider" ? win.s(14) : (parent.height - height) / 2
            text: row.label + (row.page ? "   ·  " + row.page : "")
            font.family: win.ui; font.pixelSize: win.s(14); color: win.txt
        }
    }
    component SliderRow: RowBase {
        id: sr
        readonly property real v: Number(win.val(row.key) ?? row.min)
        function fmt(x) { return (row.step < 1 ? x.toFixed(row.step < 0.1 ? 2 : 1) : Math.round(x)) + (row.unit ? " " + row.unit : ""); }
        Text {
            anchors.right: parent.right; anchors.rightMargin: win.s(16); y: win.s(15)
            text: sr.fmt(sr.v); font.family: win.ui; font.pixelSize: win.s(13); color: win.sub
        }
        Item {
            id: bar
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: win.s(16); anchors.rightMargin: win.s(16)
            y: win.s(38); height: win.s(18)
            readonly property real frac: (sr.v - row.min) / (row.max - row.min)
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: win.s(4); radius: height / 2; color: win.track }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * bar.frac; height: win.s(4); radius: height / 2; color: win.acc }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * bar.frac - width / 2
                width: win.s(15); height: width; radius: width / 2
                color: Qt.lighter(win.acc, 1.35); border.width: win.s(2); border.color: win.bgCard
                scale: drag.pressed ? 1.15 : 1; Behavior on scale { NumberAnimation { duration: Prefs.duration(100)} }
            }
            MouseArea {
                id: drag
                anchors.fill: parent; anchors.margins: -win.s(6)
                cursorShape: Qt.PointingHandCursor
                function apply(mx) {
                    const f = Math.max(0, Math.min(1, (mx - win.s(6)) / bar.width));
                    let x = row.min + f * (row.max - row.min);
                    x = Math.round(x / row.step) * row.step;
                    win.setVal(row.key, Number(x.toFixed(3)));
                }
                onPressed: m => apply(m.x)
                onPositionChanged: m => { if (pressed) apply(m.x); }
            }
        }
    }
    component ToggleRow: RowBase {
        id: tr
        readonly property bool on: !!win.val(row.key)
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: win.s(16); anchors.verticalCenter: parent.verticalCenter
            width: win.s(40); height: win.s(22); radius: height / 2
            color: tr.on ? win.acc : "#3a3a3a"; Behavior on color { ColorAnimation { duration: Prefs.duration(140)} }
            Rectangle {
                width: win.s(16); height: width; radius: width / 2; anchors.verticalCenter: parent.verticalCenter
                x: tr.on ? parent.width - width - win.s(3) : win.s(3); Behavior on x { NumberAnimation { duration: Prefs.duration(140); easing.type: Easing.OutCubic } }
                color: tr.on ? "#0b0b0b" : "#9a9a9a"
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.setVal(row.key, !tr.on) }
    }
    component ChoiceRow: RowBase {
        id: cr
        Row {
            anchors.right: parent.right; anchors.rightMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
            spacing: win.s(6)
            Repeater {
                model: cr.row.options
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: win.val(cr.row.key) === modelData.v
                    height: win.s(28); width: ct.implicitWidth + win.s(22); radius: win.s(9)
                    color: on ? Qt.rgba(win.acc.r, win.acc.g, win.acc.b, 0.22) : (cm.containsMouse ? win.bgSel : win.bgField)
                    border.width: on ? 1 : 0; border.color: win.acc
                    Text { id: ct; anchors.centerIn: parent; text: modelData.l; font.family: win.ui; font.pixelSize: win.s(12.5); color: on ? win.txt : win.sub }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.setVal(cr.row.key, modelData.v) }
                }
            }
        }
    }
    component InfoRow: RowBase {
        id: ir
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
            height: win.s(26); width: kt.implicitWidth + win.s(20); radius: win.s(8)
            color: win.bgField; border.width: 1; border.color: win.line
            Text { id: kt; anchors.centerIn: parent; text: ir.row.value || ""; font.family: win.ui; font.weight: Font.Medium; font.pixelSize: win.s(12); color: win.sub }
        }
    }
    component ButtonRow: RowBase {
        id: br
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
            height: win.s(30); width: bt.implicitWidth + win.s(28); radius: win.s(10)
            color: bm.pressed ? Qt.rgba(win.acc.r, win.acc.g, win.acc.b, 0.35) : (bm.containsMouse ? Qt.rgba(win.acc.r, win.acc.g, win.acc.b, 0.22) : win.bgField)
            Text { id: bt; anchors.centerIn: parent; text: br.row.button; font.family: win.ui; font.weight: Font.Medium; font.pixelSize: win.s(12.5); color: win.txt }
            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.action(br.row.act) }
        }
    }

    // Layout
    Item {
        id: fade
        anchors.fill: parent

        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35); MouseArea { anchors.fill: parent; onClicked: win.close() } }

        Rectangle {
            id: frame
            width: Math.min(win.s(1320), parent.width - win.s(80))
            height: parent.height - y - win.s(34)
            y: island.topMargin + island.pillHeight + win.s(18)
            anchors.horizontalCenter: parent.horizontalCenter
            radius: win.s(38)
            color: win.bgWin
            border.width: 1; border.color: win.line
            MouseArea { anchors.fill: parent }       // swallow clicks so the backdrop doesn't close

            // Sidebar
            ColumnLayout {
                id: side
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.margins: win.s(12); anchors.topMargin: win.s(12)
                width: win.s(208)
                spacing: win.s(3)
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: win.s(33); Layout.bottomMargin: win.s(10)
                    radius: win.s(10); color: win.bgField
                    Text { id: sIcon; anchors.left: parent.left; anchors.leftMargin: win.s(11); anchors.verticalCenter: parent.verticalCenter
                           text: "󰍉"; font.family: win.icons; font.pixelSize: win.s(13); color: win.dim }
                    TextInput {
                        id: search
                        anchors.left: sIcon.right; anchors.leftMargin: win.s(8); anchors.right: parent.right; anchors.rightMargin: win.s(10)
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: win.ui; font.pixelSize: win.s(13); color: win.txt; clip: true
                        onTextChanged: win.query = text.trim()
                        Keys.onEscapePressed: { if (text) text = ""; else win.close(); }
                        Text { visible: !search.text; text: "Search Settings"; font: search.font; color: win.dim }
                    }
                }
                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool on: index === win.page && !win.query
                        Layout.fillWidth: true; Layout.preferredHeight: win.s(43)
                        radius: win.s(12)
                        color: on ? win.bgSel : (nm.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent")
                        Rectangle {
                            id: ic
                            anchors.left: parent.left; anchors.leftMargin: win.s(8); anchors.verticalCenter: parent.verticalCenter
                            width: win.s(29); height: width; radius: width / 2
                            color: Qt.rgba(win.acc.r, win.acc.g, win.acc.b, on ? 0.9 : 0.16)
                            Text { anchors.centerIn: parent; text: modelData.icon; font.family: win.icons; font.pixelSize: win.s(15); color: on ? "#0b0b0b" : win.acc }
                        }
                        Text { anchors.left: ic.right; anchors.leftMargin: win.s(11); anchors.verticalCenter: parent.verticalCenter
                               text: modelData.name; font.family: win.ui; font.pixelSize: win.s(14); color: win.txt }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.go(index) }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            // Content
            Flickable {
                id: content
                anchors.left: side.right; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.leftMargin: win.s(22); anchors.rightMargin: win.s(22); anchors.topMargin: win.s(14)
                contentHeight: col.implicitHeight + win.s(24)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: col
                    width: content.width
                    spacing: win.s(12)

                    Row {
                        spacing: win.s(8)
                        Repeater {
                            model: [ { ic: "󰁍", fn: "back", en: win.backStack.length > 0 }, { ic: "󰁔", fn: "fwd", en: win.fwdStack.length > 0 } ]
                            delegate: Rectangle {
                                required property var modelData
                                width: win.s(28); height: width; radius: win.s(8)
                                color: am.containsMouse && modelData.en ? win.bgSel : win.bgField
                                Text { anchors.centerIn: parent; text: modelData.ic; font.family: win.icons; font.pixelSize: win.s(14); color: modelData.en ? win.txt : win.dim }
                                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.fn === "back" ? win.back() : win.fwd() }
                            }
                        }
                    }

                    
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: win.s(158)
                        radius: win.s(18); color: win.bgCard
                        visible: !win.query
                        Column {
                            anchors.centerIn: parent; spacing: win.s(8)
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: win.s(58); height: width; radius: width / 2
                                color: Qt.rgba(win.acc.r, win.acc.g, win.acc.b, 0.16)
                                Text { anchors.centerIn: parent; text: win.pages[win.page].icon; font.family: win.icons; font.pixelSize: win.s(26); color: win.acc }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: win.pages[win.page].name
                                   font.family: win.ui; font.weight: Font.DemiBold; font.pixelSize: win.s(20); color: win.txt }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: win.pages[win.page].desc
                                   font.family: win.ui; font.pixelSize: win.s(13); color: win.sub }
                        }
                    }

                    Text { visible: !!win.query; text: win.shownRows.length ? win.shownRows.length + " results" : "No settings match “" + win.query + "”"
                           font.family: win.ui; font.pixelSize: win.s(12); color: win.dim; Layout.leftMargin: win.s(4) }

                    Loader {
                        id: wifiPageLoader
                        Layout.fillWidth: true
                        active: true
                        visible: !win.query && win.pages[win.page].id === "wifi"
                        sourceComponent: wifiPageC
                    }
                    Loader {
                        id: bluetoothPageLoader
                        Layout.fillWidth: true
                        active: true
                        visible: !win.query && win.pages[win.page].id === "bluetooth"
                        sourceComponent: bluetoothPageC
                    }

                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rows.implicitHeight
                        visible: win.pages[win.page].id !== "wifi" && win.pages[win.page].id !== "bluetooth" && win.shownRows.length > 0
                        radius: win.s(18); color: win.bgCard
                        ColumnLayout {
                            id: rows
                            width: parent.width
                            spacing: 0
                            Repeater {
                                model: win.shownRows
                                delegate: Loader {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    sourceComponent: modelData.t === "slider" ? sliderC : modelData.t === "toggle" ? toggleC : modelData.t === "choice" ? choiceC
                                                   : modelData.t === "info" ? infoC : buttonC
                                    onLoaded: { item.row = modelData; item.last = index === win.shownRows.length - 1; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component { id: wifiPageC; NetPages.WifiPage { island: win.island; pageActive: win.open && wifiPageLoader.visible } }
    Component { id: bluetoothPageC; NetPages.BluetoothPage { island: win.island; pageActive: win.open && bluetoothPageLoader.visible } }
    Component { id: sliderC; SliderRow {} }
    Component { id: toggleC; ToggleRow {} }
    Component { id: choiceC; ChoiceRow {} }
    Component { id: buttonC; ButtonRow {} }
    Component { id: infoC; InfoRow {} }

    
    Item { focus: win.open; Keys.onEscapePressed: win.close() }
}
