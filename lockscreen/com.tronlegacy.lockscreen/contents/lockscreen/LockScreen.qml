import QtQuick 2.15

/*
 * Tron Legacy — lock screen (kscreenlocker greeter, Plasma 6)
 *
 * Doubles as the screensaver: while idle only the identity disc and the clock
 * are shown, slowly drifting so nothing burns in. Any key or mouse movement
 * brings up the password panel; after 10 s without input it fades out again.
 *
 * The disc layers are the CLU-palette SVGs of the splash
 * (look-and-feel/…/splash/images/*-clu.svg), copied to images/ by install.sh.
 */
Item {
    id: root

    // Properties and signals kscreenlocker looks for
    property bool viewVisible: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    readonly property color colBg:      "#0E0505"
    readonly property color colPanel:   "#1E0A0A"
    readonly property color colHi:      "#FF5A00"
    readonly property color colHiDim:   "#582000"
    readonly property color colText:    "#F0C080"
    readonly property color colTextDim: "#805040"
    readonly property color colError:   "#FF3030"

    // false = screensaver, true = password panel shown
    property bool uiVisible: false
    // PAM succeeded without asking for a password (account without one)
    property bool noPassword: false
    property bool seenPositionChange: false

    readonly property real discSize: Math.min(width, height) * 0.42
    readonly property bool hasAuth: typeof authenticator !== "undefined"

    function wake() {
        if (!uiVisible) {
            uiVisible = true;
            if (Window.window)
                Window.window.requestActivate();
            if (hasAuth)
                authenticator.startAuthenticating();
        }
        idleTimer.restart();
    }

    function sleep() {
        uiVisible = false;
        pwField.text = "";
        msgText.text = "";
    }

    function submit() {
        if (noPassword) {
            Qt.quit();
        } else if (hasAuth && !authenticator.graceLocked) {
            authenticator.respond(pwField.text);
        }
    }

    onClearPassword: pwField.text = ""

    Timer {
        id: idleTimer
        interval: 10000
        onTriggered: if (pwField.text.length === 0 && !root.noPassword) root.sleep()
    }
    Timer {
        id: retryTimer
        interval: 3000
        onTriggered: {
            pwField.text = "";
            msgText.text = "";
            if (root.hasAuth)
                authenticator.startAuthenticating();
        }
    }

    Connections {
        target: root.hasAuth ? authenticator : null
        ignoreUnknownSignals: true
        function onFailed(kind) {
            if (kind != 0) // non-interactive authenticators (fingerprint, smartcard)
                return;
            msgText.text = "ACCESS DENIED";
            shake.restart();
            retryTimer.restart();
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                root.noPassword = true;
                root.wake();
            }
        }
        function onInfoMessageChanged()  { msgText.text = authenticator.infoMessage.toUpperCase() }
        function onErrorMessageChanged() { msgText.text = authenticator.errorMessage.toUpperCase() }
        function onPromptForSecretChanged(msg) { pwField.forceActiveFocus() }
    }

    /* One spinning disc layer */
    component DiscLayer: Image {
        id: layer
        property string name
        property int period: 0        // ms per revolution, 0 = static
        property bool reverse: false

        anchors.fill: parent
        source: "images/" + name + "-clu.svg"
        sourceSize: Qt.size(root.discSize, root.discSize)
        smooth: true; antialiasing: true

        RotationAnimator on rotation {
            running: layer.period > 0
            from: 0; to: layer.reverse ? -360 : 360
            duration: Math.max(layer.period, 1)
            loops: Animation.Infinite
        }
    }

    Rectangle { anchors.fill: parent; color: root.colBg }

    Image {
        anchors.fill: parent
        source: "background.svg"
        fillMode: Image.PreserveAspectCrop
        opacity: root.uiVisible ? 0.55 : 0.25
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        onPressed: root.wake()
        // The view reports one position change on start-up; ignore it
        onPositionChanged: {
            if (root.seenPositionChange)
                root.wake();
            root.seenPositionChange = true;
        }
    }

    /* ── Corner brackets ── */
    Repeater {
        model: [{ax: 0, ay: 0, r: 0}, {ax: root.width, ay: 0, r: 90},
                {ax: root.width, ay: root.height, r: 180}, {ax: 0, ay: root.height, r: 270}]
        Item {
            x: modelData.ax; y: modelData.ay; width: 1; height: 1
            rotation: modelData.r; transformOrigin: Item.TopLeft
            opacity: root.uiVisible ? 0.7 : 0.25
            Behavior on opacity { NumberAnimation { duration: 600 } }
            Rectangle { width: 56; height: 2; color: root.colHi }
            Rectangle { width: 2; height: 56; color: root.colHi }
        }
    }

    /* ── Screensaver HUD: clock + identity disc, drifting against burn-in ── */
    Item {
        id: hud
        width: root.width; height: root.height

        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to:  root.width * 0.02; duration: 23000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -root.width * 0.02; duration: 47000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 23000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: -root.height * 0.02; duration: 31000; easing.type: Easing.InOutSine }
            NumberAnimation { to:  root.height * 0.02; duration: 61000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 31000; easing.type: Easing.InOutSine }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: parent.height * 0.08
            spacing: 8
            Text {
                id: clk; anchors.horizontalCenter: parent.horizontalCenter
                font.family: "monospace"; font.pixelSize: 112; font.weight: Font.Light
                font.letterSpacing: 8; color: root.colHi; opacity: 0.95
                text: Qt.formatTime(new Date(), "hh:mm")
            }
            Text {
                id: dateText; anchors.horizontalCenter: parent.horizontalCenter
                font.family: "monospace"; font.pixelSize: 16; font.letterSpacing: 8
                color: root.colTextDim
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
            }
            Timer {
                interval: 1000; repeat: true; running: true
                onTriggered: {
                    const now = new Date();
                    clk.text = Qt.formatTime(now, "hh:mm");
                    dateText.text = Qt.formatDate(now, "dddd, MMMM d").toUpperCase();
                }
            }
        }

        Item {
            id: disc
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.height * 0.06
            width: root.discSize; height: root.discSize
            // Recedes behind the password panel when it is shown
            opacity: root.uiVisible ? 0.15 : 1
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            DiscLayer { name: "trail";    period: 3000 }
            DiscLayer { name: "outer";    period: 36000; reverse: true }
            DiscLayer { name: "segments"; period: 14000 }
            DiscLayer { name: "inner";    period: 7000; reverse: true }
            DiscLayer {
                name: "core"
                // heartbeat
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.06; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 1100; easing.type: Easing.InOutSine }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: parent.height * 0.08
            text: "SYSTEM LOCKED  ·  PRESS ANY KEY"
            font.family: "monospace"; font.pixelSize: 12; font.letterSpacing: 6
            color: root.colTextDim
            opacity: root.uiVisible ? 0 : pulse
            property real pulse
            SequentialAnimation on pulse {
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.8;  duration: 2000; easing.type: Easing.InOutSine }
            }
        }
    }

    /* ── Password panel ── */
    Rectangle {
        id: panel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.06
        width: 420; height: col.implicitHeight + 56; radius: 4
        color: root.colPanel; border.color: root.colHiDim; border.width: 1
        // Only faded out, never hidden: the field keeps focus so the first
        // key press of the screensaver already types
        opacity: root.uiVisible ? 1 : 0
        transform: Translate { id: shakeOffset }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shakeOffset; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 100 }
            NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
        }

        Rectangle {
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8; height: 1; color: root.colHi; opacity: 0.75
        }

        Column {
            id: col; anchors.centerIn: parent; width: parent.width - 56; spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : "USER").toUpperCase()
                font.family: "monospace"; font.pixelSize: 20; font.letterSpacing: 4; color: root.colText
            }
            Rectangle { width: parent.width; height: 1; color: root.colHiDim }
            Rectangle {
                width: parent.width; height: 44; radius: 3; color: "#160A06"
                border.color: pwField.activeFocus ? root.colHi : root.colHiDim
                border.width: pwField.activeFocus ? 1.5 : 1
                TextInput {
                    id: pwField
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    echoMode: TextInput.Password; passwordCharacter: "●"
                    font.pixelSize: 18; color: root.colText
                    focus: true
                    readOnly: root.noPassword
                    enabled: !(root.hasAuth && authenticator.graceLocked)
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.sleep();
                            event.accepted = true;
                        } else {
                            root.wake();
                            event.accepted = false;
                        }
                    }
                    onAccepted: root.submit()
                    Text {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        text: root.noPassword ? "PRESS ENTER TO UNLOCK" : "ENTER PASSWORD"; font.pixelSize: 13; font.letterSpacing: 3
                        color: root.colTextDim; visible: pwField.text.length === 0
                    }
                }
            }
            Text {
                id: msgText; width: parent.width
                horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12; font.letterSpacing: 2
                color: root.colError; visible: text.length > 0; wrapMode: Text.Wrap
            }
        }
    }
}
