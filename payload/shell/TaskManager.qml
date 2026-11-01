import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "taskmgr" as Tm
import "taskmgr/components" as Tmc

PanelWindow {
    id: win
    required property var island
    readonly property bool open: island.taskMgrOpen
    readonly property color frameColor: "#0b0b0b"
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.045)
    readonly property color fieldColor: Qt.rgba(1, 1, 1, 0.07)
    readonly property color selectedColor: Qt.rgba(1, 1, 1, 0.09)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.06)
    readonly property color trackColor: Qt.rgba(1, 1, 1, 0.10)
    readonly property color accent: island.accent
    readonly property string uiFont: "Inter"
    readonly property string iconFont: "Iosevka Nerd Font"

    
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-taskmgr"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string page: "overview"
    property string resource: "cpu"
    property string sortKey: "cpu"
    property string processQuery: ""
    property int selectedPid: -1
    property var confirmProcess: null
    property var snapshot: ({})
    property var processRows: []
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var diskHistory: []
    property var networkHistory: []
    property var batteryHistory: []
    property var processHistory: ({})

    readonly property var cpuInfo: snapshot.cpu || ({})
    readonly property var memoryInfo: snapshot.memory || ({})
    readonly property var gpuInfo: snapshot.gpu || ({})
    readonly property var diskInfo: snapshot.disks || ({ devices: [] })
    readonly property var networkInfo: snapshot.network || ({ interfaces: [] })
    readonly property var batteryInfo: snapshot.battery || ({})
    readonly property bool gpuReady: snapshot.gpu !== null && snapshot.gpu !== undefined
    readonly property var visibleProcesses: {
        const q = processQuery.trim().toLowerCase();
        if (!q) return processRows;
        return processRows.filter(row => String(row.name || "").toLowerCase().includes(q)
            || String(row.cmdline || "").toLowerCase().includes(q));
    }
    readonly property var selectedProcess: processRows.find(row => row.pid === selectedPid) || null
    readonly property string resourceTitle: ({ cpu: "CPU", memory: "Memory", gpu: "GPU", disk: "Disk", network: "Network", battery: "Battery" })[resource] || "Performance"

    function s(value) { return island.s(value); }
    function close() { island.taskMgrOpen = false; }
    function number(value, digits, suffix) {
        if (value === null || value === undefined || !Number.isFinite(Number(value))) return "—";
        return Number(value).toFixed(digits || 0) + (suffix || "");
    }
    function bytes(value) {
        if (value === null || value === undefined || !Number.isFinite(Number(value))) return "—";
        let amount = Number(value);
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let unit = 0;
        while (amount >= 1024 && unit < units.length - 1) { amount /= 1024; unit++; }
        return amount.toFixed(unit === 0 ? 0 : 1) + " " + units[unit];
    }
    function rate(value) {
        if (value === null || value === undefined || !Number.isFinite(Number(value))) return "—";
        let amount = Number(value);
        const units = ["B/s", "KiB/s", "MiB/s", "GiB/s"];
        let unit = 0;
        while (amount >= 1024 && unit < units.length - 1) { amount /= 1024; unit++; }
        return amount.toFixed(unit === 0 ? 0 : 1) + " " + units[unit];
    }
    function gpuMemory() {
        const used = gpuInfo.memory_used_mib, total = gpuInfo.memory_total_mib;
        return used === null || used === undefined || total === null || total === undefined
            ? "—" : number(used, 0) + " / " + number(total, 0) + " MiB";
    }
    function timeLeft(value) {
        if (value === null || value === undefined || !Number.isFinite(Number(value))) return "—";
        const total = Math.max(0, Math.floor(Number(value) / 60));
        const hours = Math.floor(total / 60);
        const minutes = total % 60;
        return hours > 0 ? hours + " h " + minutes + " min" : minutes + " min";
    }
    function append(history, value) {
        const next = history.slice();
        next.push(value === null || value === undefined || !Number.isFinite(Number(value)) ? null : Number(value));
        while (next.length > 60) next.shift();
        return next;
    }
    function historyFor(key) {
        if (key === "cpu") return cpuHistory;
        if (key === "memory") return memoryHistory;
        if (key === "gpu") return gpuHistory;
        if (key === "disk") return diskHistory;
        if (key === "network") return networkHistory;
        if (key === "battery") return batteryHistory;
        return [];
    }
    function resourceValue(key) {
        if (key === "cpu") return cpuInfo.total_percent;
        if (key === "memory") return memoryInfo.percent;
        if (key === "gpu") return gpuInfo.utilization_percent;
        if (key === "disk") return diskInfo.read_bps === null || diskInfo.read_bps === undefined
            || diskInfo.write_bps === null || diskInfo.write_bps === undefined ? null : diskInfo.read_bps + diskInfo.write_bps;
        if (key === "network") return networkInfo.rx_bps === null || networkInfo.rx_bps === undefined
            || networkInfo.tx_bps === null || networkInfo.tx_bps === undefined ? null : networkInfo.rx_bps + networkInfo.tx_bps;
        if (key === "battery") return batteryInfo.percent;
        return null;
    }
    function sendCommand(command) {
        if (sysmon.running) sysmon.write(JSON.stringify(command) + "\n");
    }
    function setResource(key) {
        resource = key;
        page = "performance";
    }
    function setSort(key) {
        sortKey = key;
        sendCommand({ cmd: "sort", key: key });
    }
    function beginEndTask() {
        if (selectedProcess) confirmProcess = selectedProcess;
    }
    function killConfirmed(sig) {
        if (confirmProcess) sendCommand({ cmd: "kill", pid: confirmProcess.pid, sig: sig });
        confirmProcess = null;
    }
    function readLine(line) {
        try {
            const packet = JSON.parse(line);
            if (packet.type !== "sample") return;
            snapshot = packet;
            processRows = packet.processes && packet.processes.items ? packet.processes.items : [];
            if (selectedPid < 0 && processRows.length) selectedPid = processRows[0].pid;
            if (selectedPid >= 0 && !processRows.some(row => row.pid === selectedPid)) selectedPid = processRows.length ? processRows[0].pid : -1;
            const cpu = packet.cpu ? packet.cpu.total_percent : null;
            const memory = packet.memory ? packet.memory.percent : null;
            const gpu = packet.gpu ? packet.gpu.utilization_percent : null;
            const disk = packet.disks && packet.disks.read_bps !== null && packet.disks.read_bps !== undefined
                && packet.disks.write_bps !== null && packet.disks.write_bps !== undefined ? packet.disks.read_bps + packet.disks.write_bps : null;
            const net = packet.network && packet.network.rx_bps !== null && packet.network.rx_bps !== undefined
                && packet.network.tx_bps !== null && packet.network.tx_bps !== undefined ? packet.network.rx_bps + packet.network.tx_bps : null;
            const battery = packet.battery ? packet.battery.percent : null;
            cpuHistory = append(cpuHistory, cpu);
            memoryHistory = append(memoryHistory, memory);
            gpuHistory = append(gpuHistory, gpu);
            diskHistory = append(diskHistory, disk);
            networkHistory = append(networkHistory, net);
            batteryHistory = append(batteryHistory, battery);
            const next = Object.assign({}, processHistory);
            for (const row of processRows) {
                if (row.cpu_percent === null || row.cpu_percent === undefined) continue;
                next[row.pid] = append(next[row.pid] || [], row.cpu_percent);
            }
            processHistory = next;
        } catch (error) {
            console.warn("Task Manager ignored an invalid sysmon line", error);
        }
    }
    function handleKey(event) {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            page = "processes";
            Qt.callLater(() => processesPage.focusSearch());
            event.accepted = true;
            return;
        }
        if (page !== "processes" || !visibleProcesses.length) return;
        let index = visibleProcesses.findIndex(row => row.pid === selectedPid);
        if (index < 0) index = 0;
        let next = index;
        if (event.key === Qt.Key_Down) next = Math.min(visibleProcesses.length - 1, index + 1);
        else if (event.key === Qt.Key_Up) next = Math.max(0, index - 1);
        else if (event.key === Qt.Key_PageDown) next = Math.min(visibleProcesses.length - 1, index + 12);
        else if (event.key === Qt.Key_PageUp) next = Math.max(0, index - 12);
        else if (event.key === Qt.Key_Home) next = 0;
        else if (event.key === Qt.Key_End) next = visibleProcesses.length - 1;
        else if (event.key === Qt.Key_Delete) { beginEndTask(); event.accepted = true; return; }
        else return;
        selectedPid = visibleProcesses[next].pid;
        processesPage.ensureIndex(next);
        event.accepted = true;
    }

    Process {
        id: sysmon
        running: win.open
        stdinEnabled: true
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/taskmgr/sysmon.py"]
        stdout: SplitParser { onRead: line => win.readLine(line) }
    }

    onOpenChanged: {
        if (open) {
            if (page === "processes") Qt.callLater(() => processesPage.focusSearch());
            else Qt.callLater(() => keyboardFocus.forceActiveFocus());
        } else {
            confirmProcess = null;
        }
    }

    Item {
        id: backdrop
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.42)
            MouseArea { anchors.fill: parent; onClicked: win.close() }
        }
        Rectangle {
            id: frame
            width: Math.min(win.s(1180), parent.width - win.s(56))
            height: Math.min(win.s(760), parent.height - win.s(48))
            anchors.centerIn: parent
            radius: win.s(38)
            color: win.frameColor
            border.width: 1
            border.color: win.hairline
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: sidebar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: win.s(14)
                width: win.s(214)
                spacing: win.s(4)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: win.s(44)
                    Layout.bottomMargin: win.s(6)
                    Rectangle {
                        Layout.preferredWidth: win.s(34)
                        Layout.preferredHeight: win.s(34)
                        radius: win.s(12)
                        color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.16)
                        Text { anchors.centerIn: parent; text: "󰍛"; font.family: win.iconFont; font.pixelSize: win.s(18); color: win.accent }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Task Manager"
                        font.family: win.uiFont
                        font.weight: Font.DemiBold
                        font.pixelSize: win.s(15)
                        color: win.island.mocha.text
                        elide: Text.ElideRight
                    }
                }
                Repeater {
                    model: [
                        { id: "overview", label: "Overview", icon: "󰋊" },
                        { id: "processes", label: "Processes", icon: "󰘚" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: win.s(42)
                        radius: win.s(12)
                        color: win.page === modelData.id ? win.selectedColor : (navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent")
                        Text { anchors.left: parent.left; anchors.leftMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon; font.family: win.iconFont; font.pixelSize: win.s(16); color: win.page === modelData.id ? win.accent : win.island.mocha.overlay0 }
                        Text { anchors.left: parent.left; anchors.leftMargin: win.s(42); anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label; font.family: win.uiFont; font.pixelSize: win.s(13); color: win.island.mocha.text }
                        MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { win.page = modelData.id; win.confirmProcess = null; } }
                    }
                }
                Text {
                    Layout.leftMargin: win.s(12)
                    Layout.topMargin: win.s(14)
                    Layout.bottomMargin: win.s(3)
                    text: "PERFORMANCE"
                    font.family: win.uiFont
                    font.weight: Font.DemiBold
                    font.letterSpacing: win.s(0.7)
                    font.pixelSize: win.s(10)
                    color: win.island.mocha.overlay0
                }
                Repeater {
                    model: [
                        { id: "cpu", label: "CPU", icon: "󰻠" },
                        { id: "memory", label: "Memory", icon: "󰍛" },
                        { id: "gpu", label: "GPU", icon: "󰢮" },
                        { id: "disk", label: "Disk", icon: "󰋊" },
                        { id: "network", label: "Network", icon: "󰓅" },
                        { id: "battery", label: "Battery", icon: "󰁹" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: win.s(39)
                        radius: win.s(11)
                        color: win.page === "performance" && win.resource === modelData.id ? win.selectedColor
                            : (perfMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent")
                        Text { anchors.left: parent.left; anchors.leftMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon; font.family: win.iconFont; font.pixelSize: win.s(14); color: win.page === "performance" && win.resource === modelData.id ? win.accent : win.island.mocha.overlay0 }
                        Text { anchors.left: parent.left; anchors.leftMargin: win.s(39); anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label; font.family: win.uiFont; font.pixelSize: win.s(12.5); color: win.island.mocha.text }
                        Tmc.Sparkline {
                            anchors.right: parent.right
                            anchors.rightMargin: win.s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            width: win.s(48)
                            height: win.s(22)
                            values: win.historyFor(modelData.id)
                            lineColor: win.accent
                            strokeWidth: win.s(1.4)
                            filled: false
                        }
                        MouseArea { id: perfMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: win.setResource(modelData.id) }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: win.s(42)
                    radius: win.s(12)
                    color: win.cardColor
                    Rectangle { anchors.left: parent.left; anchors.leftMargin: win.s(12); anchors.verticalCenter: parent.verticalCenter
                        width: win.s(7); height: width; radius: width / 2; color: win.snapshot.type === "sample" ? win.island.mocha.green : win.island.mocha.overlay0 }
                    Text { anchors.left: parent.left; anchors.leftMargin: win.s(27); anchors.verticalCenter: parent.verticalCenter
                        text: win.snapshot.type === "sample" ? "Monitoring" : "Waiting for data"
                        font.family: win.uiFont; font.pixelSize: win.s(11.5); color: win.island.mocha.subtext0 }
                }
            }

            ColumnLayout {
                anchors.left: sidebar.right
                anchors.leftMargin: win.s(22)
                anchors.right: parent.right
                anchors.rightMargin: win.s(22)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: win.s(19)
                anchors.bottomMargin: win.s(18)
                spacing: win.s(13)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: win.s(42)
                    ColumnLayout {
                        spacing: win.s(2)
                        Text {
                            text: win.page === "overview" ? "Overview" : win.page === "processes" ? "Processes" : win.resourceTitle
                            font.family: win.uiFont
                            font.weight: Font.DemiBold
                            font.pixelSize: win.s(20)
                            color: win.island.mocha.text
                        }
                        Text {
                            text: win.page === "processes" ? (win.snapshot.processes ? win.snapshot.processes.count : "—") + " processes · " + (win.snapshot.processes ? win.snapshot.processes.thread_count : "—") + " threads"
                                : "Live system telemetry · 1 second refresh"
                            font.family: win.uiFont
                            font.pixelSize: win.s(11.5)
                            color: win.island.mocha.overlay0
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: win.s(34)
                        Layout.preferredHeight: win.s(34)
                        radius: win.s(10)
                        color: closeMouse.containsMouse ? win.selectedColor : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅖"; font.family: win.iconFont; font.pixelSize: win.s(16); color: win.island.mocha.overlay0 }
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.close() }
                    }
                }

                Item {
                    id: pageHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    focus: win.open
                    Keys.onPressed: event => win.handleKey(event)

                    Tm.OverviewPage { anchors.fill: parent; visible: win.page === "overview"; manager: win; island: win.island }

                    Tm.ProcessesPage { id: processesPage; anchors.fill: parent; visible: win.page === "processes"; manager: win; island: win.island }

                    Tmc.TaskCard {
                        id: performancePage
                        anchors.fill: parent
                        visible: win.page === "performance"
                        island: win.island
                        title: win.resourceTitle + " performance"
                        cardColor: win.cardColor
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: win.resource === "disk" || win.resource === "network" ? win.rate(win.resourceValue(win.resource)) : win.number(win.resourceValue(win.resource), 1, "%"); font.family: win.uiFont; font.weight: Font.Black; font.pixelSize: win.s(32); color: win.accent }
                            Item { Layout.fillWidth: true }
                            Text { text: win.resource === "cpu" ? win.number(win.cpuInfo.frequency_mhz ? win.cpuInfo.frequency_mhz.current : null, 0, " MHz") : "Last 60 samples"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                        }
                        Tmc.Sparkline { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: win.s(180); values: win.historyFor(win.resource); lineColor: win.accent; strokeWidth: win.s(2.5) }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "cpu"
                            Text { text: "Processor"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { Layout.fillWidth: true; text: win.cpuInfo.model || "—"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text; elide: Text.ElideRight }
                            Text { text: "Base speed"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.number(win.cpuInfo.frequency_mhz ? win.cpuInfo.frequency_mhz.max : null, 0, " MHz"); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Logical processors"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.cpuInfo.logical_cores || "—"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Load average"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.cpuInfo.load_avg ? win.cpuInfo.load_avg.map(value => Number(value).toFixed(2)).join("  ·  ") : "—"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Temperature / uptime"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.number(win.cpuInfo.temperature_c, 1, " °C") + "  ·  " + win.timeLeft(win.cpuInfo.uptime_s); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "memory"
                            Text { text: "In use"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.bytes(win.memoryInfo.used_bytes) + " / " + win.bytes(win.memoryInfo.total_bytes); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Available"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.bytes(win.memoryInfo.available_bytes); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Cached / buffers"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.bytes(win.memoryInfo.cache_bytes) + " / " + win.bytes(win.memoryInfo.buffers_bytes); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Swap / zram"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.bytes(win.memoryInfo.swap_used_bytes) + " / " + win.bytes(win.memoryInfo.swap_total_bytes) + "  ·  " + ((win.memoryInfo.zram || []).length ? win.bytes(win.memoryInfo.zram[0].memory_bytes) : "—"); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "gpu"
                            Text { text: "GPU"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.gpuReady ? win.gpuInfo.name : "—"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "VRAM used"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                                        Text { text: win.gpuMemory(); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Temperature / power"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.number(win.gpuInfo.temperature_c, 0, " °C") + "  ·  " + win.number(win.gpuInfo.power_w, 1, " W"); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "disk"
                            Text { text: "Read / write"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.rate(win.diskInfo.read_bps) + "  /  " + win.rate(win.diskInfo.write_bps); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Repeater {
                                model: win.diskInfo.devices || []
                                delegate: Text {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    text: modelData.device + "  " + modelData.mountpoint + " · " + win.bytes(modelData.used_bytes) + " / " + win.bytes(modelData.total_bytes)
                                    font.family: win.uiFont
                                    font.pixelSize: win.s(11)
                                    color: win.island.mocha.text
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "network"
                            Text { text: "Receive / send"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.rate(win.networkInfo.rx_bps) + "  /  " + win.rate(win.networkInfo.tx_bps); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Interfaces"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: (win.networkInfo.interfaces || []).map(item => item.name).join(" · ") || "—"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: win.s(12)
                            columnSpacing: win.s(20)
                            visible: win.resource === "battery"
                            Text { text: "Status / charge"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: (win.batteryInfo.status || "—") + "  ·  " + win.number(win.batteryInfo.percent, 0, "%"); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Power / time left"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.number(win.batteryInfo.power_w, 1, " W") + "  ·  " + win.timeLeft(win.batteryInfo.time_remaining_s); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                            Text { text: "Battery health"; font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.overlay0 }
                            Text { text: win.number(win.batteryInfo.health_percent, 0, "%"); font.family: win.uiFont; font.pixelSize: win.s(11); color: win.island.mocha.text }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: keyboardFocus
        focus: win.open && win.page !== "processes"
        Keys.onPressed: event => win.handleKey(event)
        Keys.onEscapePressed: win.close()
    }
}
