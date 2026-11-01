import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: picker
    required property var island
    visible: island.paletteOpen
    anchors { top: true; left: true; right: true }
    implicitHeight: island.wallH + island.s(18)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aether-palette"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: panel }
    property var palettes: []
    property string query: ""
    property string selectedId: ""
    property int selected: 0
    property string errorText: ""
    readonly property var filtered: palettes.filter(palette => palette.label.toLowerCase().includes(query.toLowerCase()))
    function close() { island.paletteOpen = false; }
    function applySelected() {
        if (apply.running || selected < 0 || selected >= filtered.length) return;
        errorText = "";
        let choice = filtered[selected];
        apply.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/aether-theme.py", choice.kind || "palette", choice.kind === "wallpaper" ? choice.path : choice.id];
        apply.running = true;
    }
    onVisibleChanged: if (visible) {
        query = ""; search.text = ""; selected = 0; errorText = "";
        dataReader.running = false; dataReader.running = true; current.reload(); search.forceActiveFocus();
    }
    onSelectedChanged: if (selected >= 0) paletteList.positionViewAtIndex(selected, ListView.Contain)
    Process {
        id: dataReader
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/aether-theme.py", "palette-data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { picker.palettes = JSON.parse(this.text); current.reload(); }
                catch(e) { picker.errorText = "Could not read palettes"; }
            }
        }
    }
    FileView {
        id: current
        path: Quickshell.env("HOME") + "/.local/state/aether/themes/current.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                let state = JSON.parse(text());
                picker.selectedId = state.mode === "wallpaper" ? "wallpaper" : state.id;
                let index = picker.filtered.findIndex(palette => palette.id === picker.selectedId);
                if (index >= 0) picker.selected = index;
            } catch(e) {}
        }
    }
    Process {
        id: apply
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let result = JSON.parse(this.text);
                    if (result.ok) picker.selectedId = result.selection || result.theme;
                    else picker.errorText = result.error;
                } catch(e) { picker.errorText = "Could not apply palette"; }
            }
        }
    }
    Rectangle {
        id: panel
        x: (parent.width - width) / 2; y: island.s(8)
        width: island.wallW; height: island.wallH
        radius: island.s(12); color: "#080a09"
        border.width: 1; border.color: "#1affffff"
        ColumnLayout {
            anchors.fill: parent; anchors.margins: island.s(20)
            spacing: island.s(12)
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: island.s(24)
                Text { text: "⌕"; color: island.mocha.subtext0; font.pixelSize: island.s(16) }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: island.mocha.text; selectionColor: island.mocha.blue
                    font.family: "Inter"; font.pixelSize: island.s(13)
                    clip: true
                    onTextChanged: { picker.query = text; picker.selected = 0; }
                    Keys.onEscapePressed: picker.close()
                    Keys.onReturnPressed: picker.applySelected()
                    Keys.onEnterPressed: picker.applySelected()
                    Keys.onDownPressed: picker.selected = Math.min(picker.filtered.length - 1, picker.selected + 1)
                    Keys.onUpPressed: picker.selected = Math.max(0, picker.selected - 1)
                    Keys.onTabPressed: event => { picker.selected = (picker.selected + 1) % Math.max(1,picker.filtered.length); event.accepted = true; }
                    Text { anchors.fill: parent; text: "Search palettes"; color: island.mocha.overlay0; font: search.font; visible: search.text.length === 0 }
                }
                AetherButton{colors:island.mocha;uiScale:island.s(1);text:"×";implicitWidth:island.s(28);implicitHeight:island.s(24);Accessible.name:"Close palette picker";onClicked:picker.close()}
            }
            ListView {
                id: paletteList
                Layout.fillWidth: true; Layout.fillHeight: true
                orientation: ListView.Horizontal; spacing: island.s(12)
                clip: true; boundsBehavior: Flickable.StopAtBounds
                model: picker.filtered
                currentIndex: picker.selected
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: (panel.width - island.s(64)) / 3; height: ListView.view.height
                    transform:PressScale{target:palettePress.parent;pressed:palettePress.pressed}
                    radius: island.s(10)
                    color: index === picker.selected ? AetherStyle.hoverSurface(island.mocha) : AetherStyle.surface(island.mocha)
                    border.width: 1
                    border.color: modelData.id === picker.selectedId ? island.mocha.blue : index === picker.selected ? island.mocha.subtext0 : AetherStyle.insetSurface(island.mocha)
                    Column {
                        anchors.centerIn: parent; spacing: island.s(12)
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: island.s(6)
                            Repeater {
                                model: modelData.colors
                                Rectangle { required property var modelData; width: island.s(11); height: width; radius: width / 2; color: modelData }
                            }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.text }
                    }
                    MouseArea { id:palettePress;anchors.fill: parent; enabled: !apply.running; onClicked: { picker.selected = index; picker.applySelected(); search.forceActiveFocus(); } }
                }
                Text { anchors.centerIn: parent; visible: picker.filtered.length === 0; text: "No palettes found"; color: island.mocha.overlay0; font.pixelSize: island.s(11) }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: apply.running ? "Applying…" : picker.errorText || "Colours only"; color: picker.errorText ? island.mocha.red : island.mocha.overlay0; font.family: "Inter"; font.pixelSize: island.s(11); Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: "↑ ↓ select   Enter apply   Esc close"; color: island.mocha.overlay0; font.family: "Inter"; font.pixelSize: island.s(11) }
            }
        }
    }
}
