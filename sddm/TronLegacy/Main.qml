import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    anchors.fill: parent
    color: "#050A0E"

    readonly property color colBg:      "#0E0505"
    readonly property color colPanel:   "#1E0A0A"
    readonly property color colCyan:    "#FF5A00"
    readonly property color colCyanDim: "#582000"
    readonly property color colText:    "#F0C080"
    readonly property color colTextDim: "#805040"
    readonly property color colError:   "#FF3030"

    /* ── Wallpaper fallback ── */
    Image {
        anchors.fill: parent
        source: "tron-legacy-wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.35
        visible: status === Image.Ready
    }

    /* ── Corner brackets ── */
    Repeater {
        model: [
            {ax:0,         ay:0,          r:0},
            {ax:root.width,ay:0,          r:90},
            {ax:root.width,ay:root.height,r:180},
            {ax:0,         ay:root.height,r:270}
        ]
        Item {
            x: modelData.ax; y: modelData.ay; width: 1; height: 1
            rotation: modelData.r; transformOrigin: Item.TopLeft
            Rectangle { x: 0; y: 0; width: 56; height: 2; color: root.colCyan; opacity: 0.8 }
            Rectangle { x: 0; y: 0; width: 2; height: 56; color: root.colCyan; opacity: 0.8 }
        }
    }

    /* ── Clock ── */
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: parent.height * 0.10
        spacing: 8

        Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "monospace"; font.pixelSize: 96; font.weight: Font.Light
            font.letterSpacing: 8; color: root.colCyan; opacity: 0.95
            text: Qt.formatTime(new Date(), "hh:mm")
            Timer { interval: 1000; repeat: true; running: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm") }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "monospace"; font.pixelSize: 16; font.letterSpacing: 8
            color: root.colTextDim; opacity: 0.75
            text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
        }
    }

    /* ── Login panel ── */
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 40
        width: 420; height: panelCol.implicitHeight + 72; radius: 4
        color: root.colPanel; border.color: root.colCyanDim; border.width: 1

        Rectangle {
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8; height: 1; color: root.colCyan; opacity: 0.75
        }

        Column {
            id: panelCol
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 16

            /* User selector */
            ComboBox {
                id: userCombo
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                font.family: "monospace"; font.pixelSize: 14

                contentItem: Text {
                    text: userCombo.currentText
                    font: userCombo.font
                    color: root.colText
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                popup: Popup {
                    y: userCombo.height
                    width: userCombo.width
                    background: Rectangle { color: root.colPanel; border.color: root.colCyanDim; border.width: 1 }
                    contentItem: ListView {
                        clip: true
                        model: userCombo.popup.visible ? userCombo.model : null
                        currentIndex: userCombo.highlightedIndex
                        delegate: ItemDelegate {
                            width: userCombo.width
                            contentItem: Text {
                                text: model.name
                                font: userCombo.font
                                color: root.colText
                            }
                            highlighted: userCombo.highlightedIndex === index
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: 1; color: root.colCyanDim
            }

            /* Password field */
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: 44; radius: 3;                 color: "#160A06"
                border.color: pwField.focus ? root.colCyan : root.colCyanDim
                border.width: pwField.focus ? 1.5 : 1

                TextInput {
                    id: pwField
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    echoMode: TextInput.Password; passwordCharacter: "●"
                    font.pixelSize: 18; color: root.colText; focus: true
                    Keys.onReturnPressed: root.tryLogin()
                    Keys.onEnterPressed: root.tryLogin()

                    Text {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        text: "ENTER PASSWORD"; font.pixelSize: 13; font.letterSpacing: 3
                        color: root.colTextDim; visible: pwField.text.length === 0
                    }
                }
            }

            /* Login button */
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: 40; radius: 3
                color: mouseArea.pressed ? "#401800" : (mouseArea.containsMouse ? "#703810" : "#582000")
                border.color: root.colCyanDim; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "LOGIN"; font.family: "monospace"; font.pixelSize: 14
                    font.letterSpacing: 6; color: root.colCyan
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.tryLogin()
                }
            }

            /* Session selector */
            ComboBox {
                id: sessionCombo
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: "monospace"; font.pixelSize: 12

                contentItem: Text {
                    text: sessionCombo.currentText
                    font: sessionCombo.font
                    color: root.colTextDim
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                popup: Popup {
                    y: sessionCombo.height
                    width: sessionCombo.width
                    background: Rectangle { color: root.colPanel; border.color: root.colCyanDim; border.width: 1 }
                    contentItem: ListView {
                        clip: true
                        model: sessionCombo.popup.visible ? sessionCombo.model : null
                        currentIndex: sessionCombo.highlightedIndex
                        delegate: ItemDelegate {
                            width: sessionCombo.width
                            contentItem: Text {
                                text: model.name
                                font: sessionCombo.font
                                color: root.colText
                            }
                            highlighted: sessionCombo.highlightedIndex === index
                        }
                    }
                }
            }

            /* Error message */
            Text {
                id: msgText
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12; font.letterSpacing: 2; color: root.colError
                visible: text.length > 0; wrapMode: Text.Wrap
            }
        }
    }

    /* ── Power buttons ── */
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 40
        spacing: 24

        function powerButton(label, action) {
            return {
                label: label,
                action: action
            }
        }

        Repeater {
            model: [
                { label: "SUSPEND",  action: function() { sddm.suspend(); } },
                { label: "REBOOT",   action: function() { sddm.reboot(); } },
                { label: "SHUTDOWN", action: function() { sddm.powerOff(); } }
            ]
            Rectangle {
                width: lb.implicitWidth + 24; height: 32; radius: 3
                color: ma.pressed ? "#401800" : (ma.containsMouse ? "#703810" : "transparent")
                border.color: root.colCyanDim; border.width: 1

                Text {
                    id: lb
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: "monospace"; font.pixelSize: 11
                    font.letterSpacing: 3; color: ma.containsMouse ? root.colCyan : root.colTextDim
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: modelData.action()
                }
            }
        }
    }

    function tryLogin() {
        if (pwField.text.length === 0) {
            msgText.text = "PASSWORD REQUIRED"
            return
        }
        msgText.text = ""
        sddm.login(userCombo.currentText, pwField.text, sessionCombo.currentIndex)
    }
}
