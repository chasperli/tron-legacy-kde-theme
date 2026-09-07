import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 1920; height: 1080
    property int stage: 0
    onStageChanged: { progressAnim.to = stage/6.0; progressAnim.restart() }

    readonly property color colBg:      "#0E0505"
    readonly property color colCyan:    "#FF5A00"
    readonly property color colCyanDim: "#582000"
    readonly property color colTextDim: "#805040"

    Rectangle { anchors.fill: parent; color: root.colBg }

    // Corner brackets
    Repeater {
        model: [{ax:0,ay:0,r:0},{ax:root.width,ay:0,r:90},{ax:root.width,ay:root.height,r:180},{ax:0,ay:root.height,r:270}]
        Item {
            x: modelData.ax; y: modelData.ay; width:1; height:1
            rotation: modelData.r; transformOrigin: Item.TopLeft
            Rectangle { x:0;y:0;width:56;height:2;color:root.colCyan;opacity:0.8 }
            Rectangle { x:0;y:0;width:2;height:56;color:root.colCyan;opacity:0.8 }
        }
    }

    Column {
        anchors.centerIn: parent; anchors.verticalCenterOffset: -40; spacing: 24
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width:0; height:1; color:root.colCyan; opacity:0.9
            NumberAnimation on width { from:0; to:320; duration:900; easing.type:Easing.OutExpo; running:true } }
        Text {
            id: wm; anchors.horizontalCenter: parent.horizontalCenter
            text:"TRON"; font.family:"monospace"; font.pixelSize:96; font.letterSpacing:28
            color:root.colCyan; opacity:0.0
            SequentialAnimation on opacity { PauseAnimation{duration:300}; NumberAnimation{to:1.0;duration:700} }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text:"LEGACY"; font.family:"monospace"
            font.pixelSize:18; font.letterSpacing:16; color:root.colTextDim; opacity:0.75 }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width:0; height:1; color:root.colCyan; opacity:0.6
            NumberAnimation on width { from:0; to:220; duration:1100; easing.type:Easing.OutExpo; running:true } }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80
        width: 420; height: 20
        Rectangle { id:track; anchors.verticalCenter:parent.verticalCenter; width:parent.width; height:4; color:root.colCyanDim; radius:2 }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: track.left
            height:4; radius:2; color:root.colCyan
            property real fillRatio: 0.0
            width: track.width * fillRatio
            NumberAnimation { id:progressAnim; target:parent; property:"fillRatio"; duration:600; easing.type:Easing.OutCubic }
        }
        Text { anchors.top:track.bottom; anchors.topMargin:10; anchors.horizontalCenter:parent.horizontalCenter
            text:["INIT","LOADING","MODULES","SERVICES","DESKTOP","WIDGETS","READY"][Math.min(root.stage,6)]
            font.family:"monospace"; font.pixelSize:11; font.letterSpacing:4; color:root.colTextDim; opacity:0.7 }
    }
}
