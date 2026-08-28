import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    readonly property color colBg:      "#050A0E"
    readonly property color colPanel:   "#0A141E"
    readonly property color colCyan:    "#00F5FF"
    readonly property color colCyanDim: "#004858"
    readonly property color colText:    "#80E8F0"
    readonly property color colTextDim: "#507080"
    readonly property color colError:   "#FF3030"

    Rectangle { anchors.fill:parent; color:root.colBg }

    Repeater {
        model:[{ax:0,ay:0,r:0},{ax:root.width,ay:0,r:90},{ax:root.width,ay:root.height,r:180},{ax:0,ay:root.height,r:270}]
        Item {
            x:modelData.ax; y:modelData.ay; width:1; height:1
            rotation:modelData.r; transformOrigin:Item.TopLeft
            Rectangle{x:0;y:0;width:56;height:2;color:root.colCyan;opacity:0.7}
            Rectangle{x:0;y:0;width:2;height:56;color:root.colCyan;opacity:0.7}
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: parent.height*0.12; spacing:8
        Text {
            id: clk; anchors.horizontalCenter:parent.horizontalCenter
            font.family:"monospace"; font.pixelSize:112; font.weight:Font.Light
            font.letterSpacing:8; color:root.colCyan; opacity:0.95
            text: Qt.formatTime(new Date(),"hh:mm")
            Timer{interval:10000;repeat:true;running:true;onTriggered:clk.text=Qt.formatTime(new Date(),"hh:mm")}
        }
        Text { anchors.horizontalCenter:parent.horizontalCenter; font.family:"monospace"; font.pixelSize:16
            font.letterSpacing:8; color:root.colTextDim; text:Qt.formatDate(new Date(),"dddd, MMMM d").toUpperCase() }
    }

    Rectangle {
        anchors.centerIn:parent; anchors.verticalCenterOffset:40
        width:420; height:col.implicitHeight+56; radius:4
        color:root.colPanel; border.color:root.colCyanDim; border.width:1

        Rectangle { anchors.top:parent.top; anchors.horizontalCenter:parent.horizontalCenter
            width:parent.width*0.8; height:1; color:root.colCyan; opacity:0.75 }

        Column {
            id:col; anchors.centerIn:parent; width:parent.width-56; spacing:16
            Text { anchors.horizontalCenter:parent.horizontalCenter
                text:typeof userSession!=="undefined"?userSession.name:"USER"
                font.family:"monospace"; font.pixelSize:20; font.letterSpacing:4; color:root.colText }
            Rectangle { anchors.horizontalCenter:parent.horizontalCenter; width:parent.width; height:1; color:root.colCyanDim }
            Rectangle {
                width:parent.width; height:44; radius:3; color:"#060E16"
                border.color:pwField.focus?root.colCyan:root.colCyanDim; border.width:pwField.focus?1.5:1
                TextInput {
                    id:pwField; anchors.verticalCenter:parent.verticalCenter
                    anchors.left:parent.left; anchors.right:parent.right
                    anchors.leftMargin:14; anchors.rightMargin:14
                    echoMode:TextInput.Password; passwordCharacter:"●"
                    font.pixelSize:18; color:root.colText; focus:true
                    Keys.onReturnPressed: if(typeof authenticator!=="undefined") authenticator.tryUnlock(text)
                    Text { anchors.fill:parent; verticalAlignment:Text.AlignVCenter
                        text:"ENTER PASSWORD"; font.pixelSize:13; font.letterSpacing:3
                        color:root.colTextDim; visible:pwField.text.length===0 }
                }
            }
            Text { id:msgText; anchors.horizontalCenter:parent.horizontalCenter; width:parent.width
                horizontalAlignment:Text.AlignHCenter; font.pixelSize:12; font.letterSpacing:2
                color:root.colError; visible:text.length>0; wrapMode:Text.Wrap }
        }
    }

    Connections {
        target: typeof authenticator!=="undefined"?authenticator:null
        ignoreUnknownSignals:true
        function onFailed(){ msgText.text="AUTHENTICATION FAILED"; pwField.text="" }
        function onSucceeded(){ }
        function onError(msg){ msgText.text=msg.toUpperCase() }
    }
}
