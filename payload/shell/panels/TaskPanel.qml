import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: panel
    property string focusedTask: ""
    required property var island
    width:island.s(700)-island.s(48)
    height:island.s(440)-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="tasks"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"tasks";targetWidth:island.s(700);targetHeight:island.s(440)}

    spacing: island.s(16)
    visible: opacity > 0
    component TaskButton:AetherButton{colors:panel.island.mocha;uiScale:panel.island.s(1);
    }
    RowLayout {
        AetherButton{colors:panel.island.mocha;uiScale:panel.island.s(1);text:"‹";implicitWidth:panel.island.s(36);visible:panel.island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:panel.island.backToControl()}

        Layout.fillWidth: true
        Text { text: "Tasks"; color: panel.island.mocha.text; font.family: AetherStyle.fontFamily; font.pixelSize: panel.island.s(AetherStyle.titleSize); font.weight: Font.DemiBold }
        Text { text: Tasks.runningCount ? Tasks.runningCount + " running" : "Recent results"; color: panel.island.mocha.overlay0; font.family: AetherStyle.fontFamily; font.pixelSize: panel.island.s(12) }
        Item { Layout.fillWidth: true }
        TaskButton { text: "Close"; onClicked: { panel.island.mode="collapsed"; panel.island.updateMode(); } }
    }
    Text { visible: Tasks.visibleJobs.length===0; text: "No recent tasks\nFile actions and recording exports will appear here."; color: panel.island.mocha.subtext0; font.family: AetherStyle.fontFamily; font.pixelSize: panel.island.s(13); wrapMode: Text.Wrap; Layout.fillWidth: true }
    ListView {
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true; spacing: panel.island.s(10)
        model: Tasks.visibleJobs
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width; height: panel.island.s(94)
            radius: panel.island.s(12); color: AetherStyle.surface(panel.island.mocha)
            RowLayout {
                anchors.fill: parent; anchors.margins: panel.island.s(14); spacing: panel.island.s(12)
                Text { text: modelData.status==="succeeded" ? "✓" : modelData.status==="failed" ? "!" : "◷"; color: modelData.status==="failed" ? panel.island.mocha.red : panel.island.mocha.blue; font.pixelSize: panel.island.s(AetherStyle.titleSize) }
                Image {
                    visible: modelData.thumbnail !== undefined && modelData.thumbnail !== "" && modelData.status === "succeeded"
                    Layout.preferredWidth: panel.island.s(54); Layout.preferredHeight: panel.island.s(54)
                    source: visible ? "file://"+modelData.thumbnail : ""
                    fillMode: Image.PreserveAspectFit
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 5
                    Text { Layout.fillWidth: true; text: modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; font.family: AetherStyle.fontFamily; font.pixelSize: panel.island.s(13); color: panel.island.mocha.text }
                    Text { Layout.fillWidth: true; text: modelData.status==="succeeded"?(modelData.output?"Completed · output available":"Completed"):modelData.status==="running" || modelData.status==="queued"?"Working · you can close this panel":"Needs attention · open Details for the error"; textFormat: Text.PlainText; elide: Text.ElideMiddle; font.family: AetherStyle.fontFamily; font.pixelSize: panel.island.s(11); color: panel.island.mocha.overlay0 }
                }
                TaskButton { text: "Output"; visible:modelData.output !== undefined && modelData.output !== "" && modelData.status === "succeeded"; onClicked: Quickshell.execDetached(["xdg-open",modelData.output]) }
                TaskButton { text: "Details"; onActiveFocusChanged: { if (activeFocus) panel.focusedTask = "log:" + modelData.id; else if (panel.focusedTask === "log:" + modelData.id) panel.focusedTask = ""; } Accessible.name: "Open log for " + modelData.title; onClicked: Tasks.openLog(modelData.id) }
                ToolButton { text: "×"; Accessible.name: "Dismiss task"; onClicked: Tasks.dismiss(modelData.id) }
            }
        }
    }
}
