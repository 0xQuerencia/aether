import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property var island
    width:island.launchW-island.s(0)
    height:island.launchH-island.s(0)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(0)
    enabled:island.mode==="launcher"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"launcher";targetWidth:island.launchW;targetHeight:island.launchH}

    
    readonly property color cardColor:      AetherStyle.surface(island.mocha)
    readonly property color cardHoverColor: AetherStyle.hoverSurface(island.mocha)
    readonly property color dividerColor:   AetherStyle.insetSurface(island.mocha)
    readonly property color mutedIconColor: island.mocha.subtext0
    readonly property color subtitleColor:  island.mocha.overlay0


    spacing: 0
    visible: opacity > 0

    
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: island.s(40)
        Layout.topMargin: island.s(4)
        spacing: island.s(11)
        Text {
            Layout.leftMargin: island.s(13)
            text: "󰍉"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(17)
            color: mutedIconColor
            horizontalAlignment: Text.AlignHCenter
        }
        TextInput {
            id: searchInput
            Layout.fillWidth: true
            font.family: "Inter"; font.pixelSize: island.s(15)
            color: island.mocha.text
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            onTextChanged: { island.searchQuery = text; island.filterApps(); }
            focus: island.mode === "launcher"
            Connections {
                target: island
                function onModeChanged() {
                    if (island.mode === "launcher") {
                        searchInput.text = "";
                        searchInput.forceActiveFocus();
                    }
                }
            }
            Keys.onEscapePressed: island.closeLauncher()
            Keys.onReturnPressed: island.launchSelected()
            Keys.onEnterPressed:  island.launchSelected()
            Keys.onUpPressed: {
                if (island.launchSelectedIndex > 0) {
                    island.launchSelectedIndex--;
                    appListView.positionViewAtIndex(island.launchSelectedIndex, ListView.Contain);
                }
            }
            Keys.onDownPressed: {
                if (island.launchSelectedIndex < appResults.count - 1) {
                    island.launchSelectedIndex++;
                    appListView.positionViewAtIndex(island.launchSelectedIndex, ListView.Contain);
                }
            }
            
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""
                text: "Search apps · = calculate · > command · # clipboard"
                font: searchInput.font; color: subtitleColor
            }
        }
    }

    
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: island.s(16)
        Layout.rightMargin: island.s(16)
        Layout.topMargin: island.s(31)
        Layout.preferredHeight: island.s(1)
        color: dividerColor
    }

    
    ListView {
        id: appListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: island.s(10)
        Layout.leftMargin: island.s(13)
        Layout.rightMargin: island.s(13)
        Layout.bottomMargin: island.s(14)
        spacing: island.s(6)
        clip: true
        model: island.appResults
        delegate: Rectangle {
            width: ListView.view.width
            height: island.s(48)
            radius: island.s(12)
            clip: true
            property bool isSelected: index === island.launchSelectedIndex
            readonly property string subLabel: {
                if (model.detail) return model.detail;
                var e = model.exec || "";
                return e.split("/").pop();
            }
            color: isSelected
                   ? cardColor
                   : resMouse.containsMouse
                     ? cardHoverColor
                     : "transparent"
            Behavior on color { ColorAnimation { duration: Prefs.duration(100)} }
            MouseArea {
                id: resMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.launchSelectedIndex = index; island.launchSelected(); }
                onEntered: island.launchSelectedIndex = index
            }
            
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: island.s(4); height: island.s(34)
                radius: island.s(2); color: island.accent
                opacity: parent.isSelected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Prefs.duration(100)} }
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: island.s(11)
                anchors.rightMargin: island.s(12)
                spacing: island.s(10)
                
                Rectangle {
                    Layout.preferredWidth: island.s(27); Layout.preferredHeight: island.s(27)
                    radius: island.s(6); clip: true; color: "transparent"
                    Image {
                        anchors.fill: parent
                        source: model.icon ? (model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon) : ""
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: island.s(7)
                    Text {
                        Layout.fillWidth: true
                        text: model.name
                        font.family: "Inter"; font.pixelSize: island.s(14); font.weight: Font.DemiBold
                        color: island.mocha.text; elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: subLabel !== ""
                        text: subLabel
                        font.family: "Inter"; font.pixelSize: island.s(12)
                        color: subtitleColor; elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
