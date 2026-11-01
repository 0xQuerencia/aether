
import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property var island

    anchors.fill: parent
    anchors.margins: island.ps(14)
    spacing: island.ps(8)
    opacity: island.mode === "scratchpad" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    Timer {
        id: scratchSaveTimer; interval: 600
        onTriggered: island.scratchSave(scratchEdit.text)
    }

    
    RowLayout {
        Layout.fillWidth: true; spacing: island.ps(8)
        Text { text: "󰎞"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18); color: island.accent }
        Text { text: "Scratchpad"; font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(14); color: island.mocha.text }
        Item { Layout.fillWidth: true }
        Text {
            text: scratchSaveTimer.running ? "saving…" : "saved"
            font.family: "Inter"; font.pixelSize: island.ps(9)
            color: scratchSaveTimer.running ? island.accent : island.mocha.overlay0
        }
        Rectangle {
            width: island.ps(48); height: island.ps(24); radius: island.ps(12)
            color: scratchClrMouse.containsMouse ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.25) : Qt.rgba(1,1,1,0.06)
            Behavior on color { ColorAnimation { duration: Prefs.duration(120)} }
            Text { anchors.centerIn: parent; text: "Clear"; font.family: "Inter"; font.pixelSize: island.ps(9); color: island.mocha.red }
            MouseArea { id: scratchClrMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { scratchEdit.text = ""; island.scratchSave(""); } }
        }
        Rectangle {
            width: island.ps(26); height: island.ps(26); radius: island.ps(8)
            color: scratchCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: scratchCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.scratchSave(scratchEdit.text); island.mode = "collapsed"; island.updateMode(); } }
        }
    }

    
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true
        radius: island.ps(12); color: Qt.rgba(1,1,1,0.05); clip: true
        Flickable {
            id: scratchFlick
            anchors.fill: parent; anchors.margins: island.ps(10)
            contentWidth: width; contentHeight: scratchEdit.implicitHeight; clip: true
            TextEdit {
                id: scratchEdit
                width: scratchFlick.width
                text: island.scratchText
                font.family: "Inter"; font.pixelSize: island.ps(14)
                color: island.mocha.text
                selectionColor: Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.4)
                wrapMode: TextEdit.Wrap; selectByMouse: true; persistentSelection: true
                Keys.onEscapePressed: {
                    island.scratchSave(scratchEdit.text);
                    island.mode = "collapsed"; island.updateMode();
                }
                Connections {
                    target: island
                    function onScratchLoadedChanged() {
                        if (island.scratchLoaded && island.mode === "scratchpad") {
                            scratchEdit.text = island.scratchText;
                            scratchEdit.forceActiveFocus();
                            scratchEdit.cursorPosition = scratchEdit.text.length;
                        }
                    }
                    function onModeChanged() {
                        if (island.mode === "scratchpad" && island.scratchLoaded)
                            scratchEdit.forceActiveFocus();
                    }
                }
                onTextChanged: scratchSaveTimer.restart()
                onCursorRectangleChanged: {
                    if (cursorRectangle.y + cursorRectangle.height > scratchFlick.contentY + scratchFlick.height)
                        scratchFlick.contentY = cursorRectangle.y + cursorRectangle.height - scratchFlick.height;
                    else if (cursorRectangle.y < scratchFlick.contentY)
                        scratchFlick.contentY = cursorRectangle.y;
                }
                Text {
                    anchors.top: parent.top; anchors.left: parent.left
                    visible: scratchEdit.text === ""
                    text: "Jot something down…"
                    font: scratchEdit.font; color: island.mocha.overlay0
                }
            }
        }
    }
}
