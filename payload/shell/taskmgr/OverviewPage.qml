import QtQuick
import QtQuick.Layouts
import "components" as Tm

Item {
    required property var manager
    required property var island
    Flickable {
        id: overviewPage
        anchors.fill: parent
        visible: manager.page === "overview"
        clip: true
        contentWidth: width
        contentHeight: overviewColumn.implicitHeight + manager.s(8)
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: overviewColumn
            width: overviewPage.width
            spacing: manager.s(11)
            RowLayout {
                Layout.fillWidth: true
                spacing: manager.s(11)
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(276)
                    island: manager.island
                    title: "CPU"
                    cardColor: manager.cardColor
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: manager.number(manager.cpuInfo.total_percent, 1, "%"); font.family: manager.uiFont; font.weight: Font.Black; font.pixelSize: manager.s(30); color: manager.accent }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.number(manager.cpuInfo.frequency_mhz ? manager.cpuInfo.frequency_mhz.current : null, 0, " MHz")
                            font.family: manager.uiFont; font.pixelSize: manager.s(11); color: manager.island.mocha.overlay0 }
                    }
                    Tm.Sparkline { Layout.fillWidth: true; Layout.preferredHeight: manager.s(72); values: manager.cpuHistory; lineColor: manager.accent; strokeWidth: manager.s(2) }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: manager.s(7)
                        columnSpacing: manager.s(9)
                        Repeater {
                            model: manager.cpuInfo.per_core_percent || []
                            delegate: ColumnLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: manager.s(3)
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "C" + (index + 1); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: manager.number(modelData, 0, "%"); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0 }
                                }
                                Tm.UsageBar { Layout.fillWidth: true; value: modelData; foreground: manager.accent; background: manager.trackColor }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: manager.cpuInfo.model || "—"
                        font.family: manager.uiFont
                        font.pixelSize: manager.s(9.5)
                        color: manager.island.mocha.overlay0
                        elide: Text.ElideRight
                    }
                }
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: manager.s(270)
                    Layout.preferredHeight: manager.s(276)
                    island: manager.island
                    title: "Memory"
                    cardColor: manager.cardColor
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: manager.number(manager.memoryInfo.percent, 1, "%"); font.family: manager.uiFont; font.weight: Font.Black; font.pixelSize: manager.s(28); color: manager.accent }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.bytes(manager.memoryInfo.used_bytes) + " / " + manager.bytes(manager.memoryInfo.total_bytes); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                    Tm.UsageBar { Layout.fillWidth: true; Layout.preferredHeight: manager.s(9); value: manager.memoryInfo.percent || 0; foreground: manager.accent; background: manager.trackColor; visible: manager.memoryInfo.percent !== null && manager.memoryInfo.percent !== undefined }
                    Tm.Sparkline { Layout.fillWidth: true; Layout.preferredHeight: manager.s(60); values: manager.memoryHistory; lineColor: manager.accent; strokeWidth: manager.s(2) }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: manager.s(5)
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Available"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                            Item { Layout.fillWidth: true }
                            Text { text: manager.bytes(manager.memoryInfo.available_bytes); color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Cache / buffers"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                            Item { Layout.fillWidth: true }
                            Text { text: manager.bytes(manager.memoryInfo.cache_bytes) + " / " + manager.bytes(manager.memoryInfo.buffers_bytes); color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Swap"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                            Item { Layout.fillWidth: true }
                            Text { text: manager.bytes(manager.memoryInfo.swap_used_bytes) + " / " + manager.bytes(manager.memoryInfo.swap_total_bytes); color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: manager.s(11)
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(208)
                    island: manager.island
                    title: "GPU"
                    cardColor: manager.cardColor
                    Text { Layout.fillWidth: true; text: manager.gpuReady ? (manager.gpuInfo.name || "NVIDIA GPU") : "—"; font.family: manager.uiFont; font.weight: Font.DemiBold; font.pixelSize: manager.s(13); color: manager.island.mocha.text; elide: Text.ElideRight }
                    Tm.UsageBar { Layout.fillWidth: true; value: manager.gpuInfo.utilization_percent || 0; foreground: manager.accent; background: manager.trackColor; visible: manager.gpuReady }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: manager.s(7)
                        columnSpacing: manager.s(10)
                        Text { text: "Utilization"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Text { Layout.alignment: Qt.AlignRight; text: manager.number(manager.gpuInfo.utilization_percent, 0, "%"); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                        Text { text: "VRAM"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Text { Layout.alignment: Qt.AlignRight; text: manager.gpuMemory(); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                        Text { text: "Temperature / power"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Text { Layout.alignment: Qt.AlignRight; text: manager.number(manager.gpuInfo.temperature_c, 0, " °C") + " / " + manager.number(manager.gpuInfo.power_w, 1, " W"); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                }
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(208)
                    island: manager.island
                    title: "Disk"
                    cardColor: manager.cardColor
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Read  " + manager.rate(manager.diskInfo.read_bps); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                        Item { Layout.fillWidth: true }
                        Text { text: "Write  " + manager.rate(manager.diskInfo.write_bps); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                    Repeater {
                        model: manager.diskInfo.devices || []
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: manager.s(4)
                            RowLayout {
                                Layout.fillWidth: true
                                Text { Layout.fillWidth: true; text: modelData.device + "  " + modelData.mountpoint; font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.overlay0; elide: Text.ElideMiddle }
                                Text { text: manager.bytes(modelData.used_bytes) + " / " + manager.bytes(modelData.total_bytes); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0 }
                            }
                            Tm.UsageBar { Layout.fillWidth: true; value: modelData.percent; foreground: manager.accent; background: manager.trackColor }
                        }
                    }
                    Text { visible: !(manager.diskInfo.devices || []).length; text: "—"; font.family: manager.uiFont; font.pixelSize: manager.s(11); color: manager.island.mocha.overlay0 }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: manager.s(11)
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(192)
                    island: manager.island
                    title: "Network"
                    cardColor: manager.cardColor
                    Tm.Sparkline { Layout.fillWidth: true; Layout.preferredHeight: manager.s(80); values: manager.networkHistory; lineColor: manager.accent; strokeWidth: manager.s(2) }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "↓  " + manager.rate(manager.networkInfo.rx_bps); font.family: manager.uiFont; font.pixelSize: manager.s(11); color: manager.island.mocha.subtext0 }
                        Item { Layout.fillWidth: true }
                        Text { text: "↑  " + manager.rate(manager.networkInfo.tx_bps); font.family: manager.uiFont; font.pixelSize: manager.s(11); color: manager.island.mocha.subtext0 }
                    }
                    Text { Layout.fillWidth: true; text: (manager.networkInfo.interfaces || []).map(item => item.name).join(" · ") || "—"; font.family: manager.uiFont; font.pixelSize: manager.s(9.5); color: manager.island.mocha.overlay0; elide: Text.ElideRight }
                }
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(192)
                    island: manager.island
                    title: "Battery"
                    cardColor: manager.cardColor
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: manager.number(manager.batteryInfo.percent, 0, "%"); font.family: manager.uiFont; font.weight: Font.Black; font.pixelSize: manager.s(27); color: manager.accent }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.batteryInfo.status || "—"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                    Tm.UsageBar { Layout.fillWidth: true; value: manager.batteryInfo.percent || 0; foreground: manager.accent; background: manager.trackColor; visible: manager.batteryInfo.percent !== null && manager.batteryInfo.percent !== undefined }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Power"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.number(manager.batteryInfo.power_w, 1, " W"); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Time left"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.timeLeft(manager.batteryInfo.time_remaining_s); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Health"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.number(manager.batteryInfo.health_percent, 0, "%"); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                    }
                }
                Tm.TaskCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(192)
                    island: manager.island
                    title: "Temps & fans"
                    cardColor: manager.cardColor
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                        Item { Layout.fillWidth: true }
                        Text { text: manager.number(manager.cpuInfo.temperature_c, 1, " °C"); font.family: manager.uiFont; font.weight: Font.DemiBold; font.pixelSize: manager.s(14); color: manager.island.mocha.text }
                    }
                    Repeater {
                        model: manager.snapshot.fans || []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: modelData.name; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                            Text { text: manager.number(modelData.rpm, 0, " RPM"); font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.subtext0 }
                        }
                    }
                    Text { visible: !(manager.snapshot.fans || []).length; text: "Fans unavailable"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.overlay0 }
                }
            }
        }
    }
}
