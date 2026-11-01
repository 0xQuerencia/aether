import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

ColumnLayout {
    id: clipPanel
    required property var island
    width:island.clipW-island.s(48)
    height:island.clipH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="clipboard"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"clipboard";targetWidth:island.clipW;targetHeight:island.clipH}


    spacing: island.ps(10)
    visible: opacity > 0

    readonly property color cardColor: AetherStyle.surface(island.mocha)
    readonly property real rowH: island.ps(46)
    readonly property real imageRowH: island.ps(64)
    
    readonly property var selected: island.clipQuery !== null && island.clipSelectedIndex >= 0 && island.clipSelectedIndex < island.clipFiltered.count
                                    ? island.clipFiltered.get(island.clipSelectedIndex) : null

    
    function imageLabel(content) {
        return content.replace(/^\[\[\s*binary data\s*/, "").replace(/\s*\]\]\s*$/, "");
    }
    function moveSel(d) {
        let i = Math.max(0, Math.min(island.clipFiltered.count - 1, island.clipSelectedIndex + d));
        if (i === island.clipSelectedIndex) return;
        island.clipSelectedIndex = i;
        clipListView.positionViewAtIndex(i, ListView.Contain);
    }

    RowLayout{
        Layout.fillWidth:true
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"‹";implicitWidth:island.s(36);visible:island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:island.backToControl()}
        Text{text:"Clipboard";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(AetherStyle.titleSize);font.weight:Font.DemiBold;color:island.mocha.text}
        Item{Layout.fillWidth:true}
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"Close";onClicked:island.closeActivePanel()}
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: island.ps(10)
        Text {
            text: "󰍉"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.accent; Layout.preferredWidth: island.ps(24)
        }
        TextInput {
            id: clipSearchInput
            Layout.fillWidth: true
            font.family: "Inter"; font.pixelSize: island.ps(13)
            color: island.mocha.text
            clip: true
            onTextChanged: { island.clipQuery = text; island.clipSelectedIndex = 0; island.filterClips(); }
            focus: island.mode === "clipboard"
            Connections {
                target: island
                function onModeChanged() {
                    if (island.mode === "clipboard") {
                        clipSearchInput.text = "";
                        clipSearchInput.forceActiveFocus();
                    }
                }
            }
            Keys.onEscapePressed: { island.mode = "collapsed"; island.updateMode(); }
            Keys.onReturnPressed: island.copyClipSelected()
            Keys.onEnterPressed:  island.copyClipSelected()
            Keys.onUpPressed:       clipPanel.moveSel(-1)
            Keys.onDownPressed:     clipPanel.moveSel(1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp)   { clipPanel.moveSel(-8); event.accepted = true; }
                if (event.key === Qt.Key_PageDown) { clipPanel.moveSel(8);  event.accepted = true; }
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) { island.togglePinSelected(); event.accepted = true; }
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_D) { island.deleteClipSelected(); event.accepted = true; }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: clipSearchInput.text === ""
                text: "Search clipboard…"
                font: clipSearchInput.font; color: island.mocha.overlay0
            }
        }
        Text {
            text: island.clipFiltered.count + " / " + island.clipResults.count
            font.family: "Inter"; font.pixelSize: island.ps(10)
            color: island.mocha.overlay0
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: island.ps(12)

        
        ListView {
            id: clipListView
            Layout.fillHeight: true
            Layout.preferredWidth: island.ps(420)
            spacing: island.ps(4)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: island.clipFiltered
            delegate: Rectangle {
            transform:PressScale{target:clipMouse.parent;pressed:clipMouse.pressed}

                id: clipRow
                required property int index
                required property var model
                readonly property bool isImage: model.clipType === "image" && model.image !== ""
                readonly property bool isSelected: index === island.clipSelectedIndex
                width: ListView.view.width
                height: isImage ? clipPanel.imageRowH : clipPanel.rowH
                radius: island.ps(12)
                color: isSelected
                       ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.28)
                       : clipMouse.containsMouse
                         ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.14)
                         : clipPanel.cardColor
                Behavior on color { ColorAnimation { duration: Prefs.duration(100)} }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: island.ps(10)
                    anchors.rightMargin: clipRow.isSelected ? island.ps(76) : island.ps(12)
                    spacing: island.ps(10)
                    Rectangle {
                        Layout.preferredWidth: island.ps(3); Layout.preferredHeight: island.ps(24)
                        radius: 2; color: island.accent
                        opacity: clipRow.isSelected ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Prefs.duration(100)} }
                    }
                    ClippingRectangle {
                        visible: clipRow.isImage
                        Layout.preferredWidth: island.ps(76)
                        Layout.preferredHeight: clipPanel.imageRowH - island.ps(14)
                        radius: island.ps(8)
                        color: Qt.rgba(0, 0, 0, 0.35)
                        Image {
                            anchors.fill: parent
                            source: clipRow.isImage ? "file://" + clipRow.model.image : ""
                            sourceSize.width: island.ps(152)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                    }
                    Text {
                        visible: clipRow.model.pinned === true
                        text: "󰐃"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14)
                        color: island.accent
                    }
                    Text {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        text: clipRow.isImage ? clipPanel.imageLabel(clipRow.model.content) : clipRow.model.content
                        font.family: "Inter"; font.pixelSize: island.ps(13)
                        color: clipRow.isImage ? island.mocha.overlay0 : island.mocha.text
                        elide: Text.ElideRight; maximumLineCount: 1
                    }
                }
                MouseArea {
                    id: clipMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked:  { island.clipSelectedIndex = clipRow.index; island.copyClip(clipRow.model.clipId); }
                    onEntered:  island.clipSelectedIndex = clipRow.index
                }
                
                Row {
                    anchors.right: parent.right; anchors.rightMargin: island.ps(8)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: island.ps(4)
                    visible: clipRow.isSelected
                    Repeater {
                        model: [
                            { icon: clipRow.model.pinned ? "󰐄" : "󰐃", act: "pin" },
                            { icon: "󰆴", act: "delete" }
                        ]
                        delegate: Rectangle {
            transform:PressScale{target:actMouse.parent;pressed:actMouse.pressed}

                            required property var modelData
                            width: island.ps(28); height: island.ps(28); radius: island.ps(8)
                            color: actMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.35)
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.icon
                                font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14)
                                color: island.mocha.text
                            }
                            MouseArea {
                                id: actMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    island.clipSelectedIndex = clipRow.index;
                                    if (parent.modelData.act === "pin") island.togglePinSelected();
                                    else island.deleteClipSelected();
                                }
                            }
                        }
                    }
                }
            }
        }

        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: island.ps(14)
            color: clipPanel.cardColor

            readonly property bool showImage: clipPanel.selected !== null
                                              && clipPanel.selected.clipType === "image"
                                              && clipPanel.selected.image !== ""

            Image {
                id: previewImage
                anchors.fill: parent
                anchors.margins: island.ps(12)
                anchors.bottomMargin: island.ps(34)
                visible: parent.showImage
                source: parent.showImage ? "file://" + clipPanel.selected.image : ""
                sourceSize.width: island.ps(700)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }
            Text {
                anchors.fill: parent
                anchors.margins: island.s(AetherStyle.panelPadding)
                anchors.bottomMargin: island.ps(34)
                visible: !parent.showImage && clipPanel.selected !== null
                text: clipPanel.selected ? clipPanel.selected.content : ""
                font.family: "Inter"; font.pixelSize: island.ps(13)
                color: island.mocha.text
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            Text {
                anchors.centerIn: parent
                visible: clipPanel.selected === null
                text: island.clipResults.count === 0 ? "Clipboard is empty" : "No matches"
                font.family: "Inter"; font.pixelSize: island.ps(13)
                color: island.mocha.overlay0
            }
            Text {
                anchors.left: parent.left; anchors.bottom: parent.bottom
                anchors.margins: island.ps(12)
                visible: clipPanel.selected !== null
                text: (clipPanel.selected && clipPanel.selected.pinned ? "Pinned · " : "")
                      + (parent.showImage ? "Image" : "Text") + " · Enter copy · Ctrl+P pin · Ctrl+D delete"
                font.family: "Inter"; font.pixelSize: island.ps(10)
                color: island.mocha.overlay0
            }
        }
    }
}
