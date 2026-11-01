// Overview
import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property var island

    id: overviewContent
    anchors.fill: parent
    anchors.margins: island.ps(14)
    spacing: island.ps(10)
    opacity: island.mode === "overview" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    RowLayout {
        Layout.fillWidth: true; spacing: island.ps(8)
        Text {
            text: "󰕮"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.accent
        }
        Text {
            text: "Workspaces"
            font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(14)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: island.ps(26); height: island.ps(26); radius: island.ps(8)
            color: ovCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: ovCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.mode = "collapsed"; island.updateMode(); } }
        }
    }

    
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 3
        rowSpacing: island.ps(10)
        columnSpacing: island.ps(10)
        Repeater {
            model: 9
            delegate: Rectangle {
                id: ovCell
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: island.ps(12)
                property int wsNum: index + 1
                property bool isActive: index === workspacesModel.activeIndex
                property var winList: island.ovWindows[String(wsNum)] || []
                property bool isOccupied: winList.length > 0
                color: isActive
                       ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.16)
                       : (ovCellMouse.containsMouse ? Qt.rgba(1,1,1,0.10)
                          : (isOccupied ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.025)))
                Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }
                border.width: isActive ? island.ps(2) : island.ps(1)
                border.color: isActive ? island.accent : Qt.rgba(1,1,1,0.08)
                scale: ovCellMouse.containsMouse ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: Prefs.duration(160); easing.type: Easing.OutBack } }
                clip: true


                Item {
                    id: ovScreen
                    anchors.centerIn: parent
                    property real monAspect: island.monW / Math.max(1, island.monH)
                    property real availW: parent.width - island.ps(12)
                    property real availH: parent.height - island.ps(12)
                    width:  Math.min(availW, availH * monAspect)
                    height: width / monAspect
                    clip: true

                    
                    Rectangle {
                        id: ovScreenMask
                        anchors.fill: parent
                        radius: island.ps(5)
                        color: island.mocha.crust
                        clip: true

                        
                        Image {
                            anchors.fill: parent
                            source: island.ovWallpaper.length
                                    ? "file://" + island.ovWallpaper : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: 0.5
                        }

                        
                        Image {
                            id: ovThumb
                            anchors.fill: parent
                            
                            source: island.ovThumbDir.length
                                    ? "file://" + island.ovThumbDir + "/" + ovCell.wsNum + ".jpg?r=" + island.ovThumbRev
                                    : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            visible: status === Image.Ready
                        }

                        
                        Rectangle {
                            anchors.fill: parent
                            radius: island.ps(5)
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.06)
                        }
                    }
                }

                
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top
                    anchors.leftMargin: island.ps(6); anchors.topMargin: island.ps(6)
                    width: island.ps(20); height: island.ps(20)
                    radius: island.ps(6)
                    color: ovCell.isActive ? island.accent : Qt.rgba(0,0,0,0.45)
                    Text {
                        anchors.centerIn: parent
                        text: ovCell.wsNum
                        font.family: "Inter"; font.weight: Font.Black
                        font.pixelSize: island.ps(11)
                        color: ovCell.isActive ? island.mocha.base
                               : (ovCell.isOccupied ? island.mocha.text : island.mocha.overlay0)
                    }
                }

                MouseArea {
                    id: ovCellMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", String(ovCell.wsNum)]);
                        island.mode = "collapsed"; island.updateMode();
                    }
                }
            }
        }
    }

    
    function prettyName(raw) {
        if (!raw) return "";
        let s = String(raw);
        
        s = s.replace(/^org\.[a-z]+\./i, "").replace(/_/g, " ");
        return s.length > 14 ? s.slice(0, 13) + "…" : s;
    }
}
