import QtQuick
import QtQuick.Layouts
import "components" as Tm

Item {
    required property var manager
    required property var island
    Item {
        id: processesPage
        function focusSearch() { processSearch.forceActiveFocus(); }
        function ensureIndex(index) { processList.positionViewAtIndex(index, ListView.Contain); }
        anchors.fill: parent
        visible: manager.page === "processes"
        RowLayout {
            anchors.fill: parent
            spacing: manager.s(11)
            Tm.TaskCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                island: manager.island
                title: "Running processes"
                cardColor: manager.cardColor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(34)
                    radius: manager.s(10)
                    color: manager.fieldColor
                    Text { anchors.left: parent.left; anchors.leftMargin: manager.s(10); anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"; font.family: manager.iconFont; font.pixelSize: manager.s(13); color: manager.island.mocha.overlay0 }
                    TextInput {
                        id: processSearch
                        anchors.left: parent.left
                        anchors.leftMargin: manager.s(31)
                        anchors.right: parent.right
                        anchors.rightMargin: manager.s(8)
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        text: manager.processQuery
                        font.family: manager.uiFont
                        font.pixelSize: manager.s(11.5)
                        color: manager.island.mocha.text
                        onTextChanged: manager.processQuery = text
                        Keys.onEscapePressed: { if (text.length) text = ""; else manager.close(); }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                                || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
                                || event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                                manager.handleKey(event);
                            } else if (event.key === Qt.Key_Delete) {
                                manager.beginEndTask();
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                                manager.handleKey(event);
                            }
                        }
                        Text { visible: !processSearch.text; text: "Search by name or command"; font: processSearch.font; color: manager.island.mocha.overlay0 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.confirmProcess ? manager.s(42) : 0
                    visible: !!manager.confirmProcess
                    radius: manager.s(10)
                    color: Qt.rgba(manager.accent.r, manager.accent.g, manager.accent.b, 0.12)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: manager.s(10)
                        anchors.rightMargin: manager.s(6)
                        Text { Layout.fillWidth: true; text: "End " + (manager.confirmProcess ? manager.confirmProcess.name : "process") + "?"; font.family: manager.uiFont; font.pixelSize: manager.s(10.5); color: manager.island.mocha.text; elide: Text.ElideRight }
                        Repeater {
                            model: [ { label: "End task", sig: "TERM" }, { label: "Force kill", sig: "KILL" }, { label: "Cancel", sig: "" } ]
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: confirmLabel.implicitWidth + manager.s(16)
                                Layout.preferredHeight: manager.s(27)
                                radius: manager.s(8)
                                color: confirmMouse.containsMouse ? manager.selectedColor : Qt.rgba(1, 1, 1, 0.055)
                                Text { id: confirmLabel; anchors.centerIn: parent; text: modelData.label; font.family: manager.uiFont; font.pixelSize: manager.s(9.5); color: manager.island.mocha.text }
                                MouseArea { id: confirmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.sig ? manager.killConfirmed(modelData.sig) : manager.confirmProcess = null }
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(31)
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        spacing: manager.s(4)
                        Repeater {
                            model: [
                                { label: "Name", key: "name", width: 0.27 },
                                { label: "PID", key: "pid", width: 0.10 },
                                { label: "CPU", key: "cpu", width: 0.10 },
                                { label: "Memory", key: "mem", width: 0.15 },
                                { label: "Disk I/O", key: "io", width: 0.17 },
                                { label: "User", key: "user", width: 0.15 }
                            ]
                            delegate: Item {
                                required property var modelData
                                Layout.fillWidth: true
                        Layout.preferredWidth: parent.width * modelData.width
                                Layout.fillHeight: true
                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label + (manager.sortKey === modelData.key ? "  ↓" : "")
                                    font.family: manager.uiFont; font.weight: Font.DemiBold; font.pixelSize: manager.s(9); color: manager.island.mocha.overlay0; elide: Text.ElideRight }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: manager.setSort(modelData.key) }
                            }
                        }
                    }
                }
                ListView {
                    id: processList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    boundsBehavior: Flickable.StopAtBounds
                    model: manager.visibleProcesses
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: processList.width
                        height: manager.s(31)
                        radius: manager.s(6)
                        color: modelData.pid === manager.selectedPid ? Qt.rgba(manager.accent.r, manager.accent.g, manager.accent.b, 0.17)
                            : index % 2 ? Qt.rgba(1, 1, 1, 0.018) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: manager.s(5)
                            anchors.rightMargin: manager.s(5)
                            spacing: manager.s(4)
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.27; text: modelData.name || "—"; font.family: manager.uiFont; font.pixelSize: manager.s(9.3); color: manager.island.mocha.text; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.10; text: modelData.pid; font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.10; text: manager.number(modelData.cpu_percent, 1, "%"); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.15; text: manager.bytes(modelData.rss_bytes); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.17; text: modelData.io_read_bps === null || modelData.io_read_bps === undefined || modelData.io_write_bps === null || modelData.io_write_bps === undefined ? "—" : manager.rate(modelData.io_read_bps + modelData.io_write_bps); font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.subtext0; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; Layout.preferredWidth: parent.width * 0.15; text: modelData.user || "—"; font.family: manager.uiFont; font.pixelSize: manager.s(9); color: manager.island.mocha.overlay0; elide: Text.ElideRight }
                        }
                        MouseArea { anchors.fill: parent; onClicked: manager.selectedPid = modelData.pid }
                    }
                    Text { anchors.centerIn: parent; visible: !processList.count; text: "No processes match"; font.family: manager.uiFont; font.pixelSize: manager.s(11); color: manager.island.mocha.overlay0 }
                }
            }
            Tm.TaskCard {
                Layout.preferredWidth: manager.s(260)
                Layout.fillHeight: true
                island: manager.island
                title: "Process details"
                cardColor: manager.cardColor
                Text { Layout.fillWidth: true; text: manager.selectedProcess ? manager.selectedProcess.name : "Select a process"; font.family: manager.uiFont; font.weight: Font.DemiBold; font.pixelSize: manager.s(15); color: manager.island.mocha.text; wrapMode: Text.WrapAnywhere }
                Tm.Sparkline { Layout.fillWidth: true; Layout.preferredHeight: manager.s(65); values: manager.processHistory[manager.selectedPid] || []; lineColor: manager.accent; strokeWidth: manager.s(1.8) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: manager.s(6)
                    RowLayout { Layout.fillWidth: true; Text { text: "PID"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? manager.selectedProcess.pid : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } }
                    RowLayout { Layout.fillWidth: true; Text { text: "CPU"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? manager.number(manager.selectedProcess.cpu_percent, 1, "%") : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } }
                    RowLayout { Layout.fillWidth: true; Text { text: "Memory"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? manager.bytes(manager.selectedProcess.rss_bytes) : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } }
                    RowLayout { Layout.fillWidth: true; Text { text: "Threads"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? manager.selectedProcess.threads : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } }
                    RowLayout { Layout.fillWidth: true; Text { text: "State"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? (manager.selectedProcess.state || "—") : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } }
                    RowLayout { Layout.fillWidth: true; Text { text: "User"; color: manager.island.mocha.overlay0; font.family: manager.uiFont; font.pixelSize: manager.s(10) } Item { Layout.fillWidth: true } Text { text: manager.selectedProcess ? (manager.selectedProcess.user || "—") : "—"; color: manager.island.mocha.subtext0; font.family: manager.uiFont; font.pixelSize: manager.s(10); elide: Text.ElideRight } }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: manager.selectedProcess ? (manager.selectedProcess.cmdline || "—") : "—"
                    font.family: manager.uiFont
                    font.pixelSize: manager.s(9.5)
                    color: manager.island.mocha.overlay0
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 12
                    elide: Text.ElideRight
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: manager.s(34)
                    radius: manager.s(10)
                    color: endMouse.containsMouse ? Qt.rgba(manager.accent.r, manager.accent.g, manager.accent.b, 0.17) : manager.fieldColor
                    Text { anchors.centerIn: parent; text: "End task"; font.family: manager.uiFont; font.pixelSize: manager.s(10); color: manager.island.mocha.text }
                    MouseArea { id: endMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: manager.beginEndTask() }
                }
            }
        }
    }
}
