import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id:root
    required property var island
    readonly property int wantedHeight:300+(LiveActivities.error?70:0)
    width:island.s(512);height:island.s(wantedHeight-48)
    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:island.s(24)
    enabled:island.mode==="headphones";opacity:reveal.reveal;visible:opacity>0;spacing:10
    PanelReveal{id:reveal;island:root.island;mode:"headphones";targetWidth:island.s(560);targetHeight:island.s(root.wantedHeight)}
    Keys.onEscapePressed:event=>{root.island.closeActivePanel();event.accepted=true;}
    readonly property bool productImageReady:productImage.imageReady
    readonly property real productAngle:productImage.rotationAngle
    readonly property var device:LiveActivities.headphone
    readonly property bool connected:device && device.connected && LiveActivities.state.monitorAvailable!==false
    readonly property bool hasBattery:device && device.battery!==null && device.battery!==undefined
    RowLayout {
        Layout.fillWidth:true
        Text{text:LiveActivities.state.monitorAvailable===false?"Headphones · checking connection":root.connected?"Headphones connected":root.device?"Headphones disconnected":"Headphones";font.family:AetherStyle.fontFamily;font.pixelSize:12;color:root.island.mocha.subtext0}
        Item{Layout.fillWidth:true}
        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Close";onClicked:root.island.closeActivePanel()}
    }
    RowLayout {
        Layout.fillWidth:true;spacing:16
        HeadphoneProduct{
            id:productImage;Layout.preferredWidth:152;Layout.preferredHeight:152
            colors:root.island.mocha;active:root.island.mode==="headphones" && root.visible
            modelName:root.device?(root.device.model || root.device.name):""
        }
        ColumnLayout {
            Layout.fillWidth:true;spacing:6
            Text{Layout.fillWidth:true;text:root.device?root.device.name:"No headphones connected";textFormat:Text.PlainText;elide:Text.ElideRight;font.family:AetherStyle.fontFamily;font.weight:Font.DemiBold;font.pixelSize:18;color:root.island.mocha.text}
            Text{Layout.fillWidth:true;text:LiveActivities.state.monitorAvailable===false?"Connection status unavailable":!root.connected?"Connect your headphones to see their status":root.device.audioActive?"Audio is playing through these headphones":root.device.routeKnown?"Connected · audio uses another output":"Connected · audio status unavailable";wrapMode:Text.WordWrap;font.pixelSize:11;color:root.island.mocha.overlay0}
            Text{text:root.hasBattery?(root.connected?"Battery · ":"Last reported battery · ")+root.device.battery+"%":"Battery not reported";font.pixelSize:12;color:root.hasBattery && root.device.battery<=15?root.island.mocha.red:root.island.mocha.subtext0}
        }
    }
    Item{Layout.fillHeight:true}
    RowLayout {
        Layout.fillWidth:true
        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Use for audio";visible:root.connected && !!root.device.sink && !root.device.audioActive;onClicked:{root.island.activityInteractive=true;LiveActivities.run(["use-audio",root.device.mac]);}}
        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Sound";onClicked:root.island.openSoundPanel()}
        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Bluetooth";onClicked:root.island.openBtPanel()}
        Item{Layout.fillWidth:true}
    }
    AetherMessage{Layout.fillWidth:true;colors:root.island.mocha;visible:LiveActivities.error!=="";error:true;heading:LiveActivities.error}
}
