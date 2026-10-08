import QtQuick 2.15

/*
 * Tron Legacy — KSplash
 *
 * An identity disc built from SVG layers (images/<layer>-<palette>.svg) that
 * QML spins at different speeds — QtSvg cannot play SMIL animations itself.
 * The disc starts in the CLU orange of the login screen and shifts to grid
 * cyan as Plasma reports its loading stages (0…6), handing over to the desktop.
 */
Rectangle {
    id: root

    property int stage: 0
    // 0 = CLU orange (login), 1 = grid cyan (desktop)
    property real progress: 0
    onStageChanged: progress = Math.min(stage, 6) / 6.0
    Behavior on progress { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    readonly property color cluHi:   "#FF5A00"
    readonly property color cluDim:  "#805040"
    readonly property color cluBg:   "#0E0505"
    readonly property color gridHi:  "#00F5FF"
    readonly property color gridDim: "#507080"
    readonly property color gridBg:  "#050A0E"

    readonly property color colHi:  mix(cluHi, gridHi, progress)
    readonly property color colDim: mix(cluDim, gridDim, progress)

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, 1)
    }

    color: mix(cluBg, gridBg, progress)

    readonly property real discSize: Math.min(width, height) * 0.42

    /* ── One spinning disc layer, cross-fading from CLU to grid palette ── */
    component DiscLayer: Item {
        id: layer
        property string name
        property int period: 0        // ms per revolution, 0 = static
        property bool reverse: false

        anchors.centerIn: parent
        width: root.discSize; height: root.discSize

        Image {
            anchors.fill: parent
            source: "images/" + layer.name + "-clu.svg"
            sourceSize: Qt.size(root.discSize, root.discSize)
            smooth: true; antialiasing: true
            opacity: 1 - root.progress
        }
        Image {
            anchors.fill: parent
            source: "images/" + layer.name + "-grid.svg"
            sourceSize: Qt.size(root.discSize, root.discSize)
            smooth: true; antialiasing: true
            opacity: root.progress
        }

        RotationAnimator on rotation {
            running: layer.period > 0
            from: 0; to: layer.reverse ? -360 : 360
            duration: Math.max(layer.period, 1)
            loops: Animation.Infinite
        }
    }

    /* ── Corner brackets ── */
    Repeater {
        model: [{ax: 0, ay: 0, r: 0}, {ax: root.width, ay: 0, r: 90},
                {ax: root.width, ay: root.height, r: 180}, {ax: 0, ay: root.height, r: 270}]
        Item {
            x: modelData.ax; y: modelData.ay; width: 1; height: 1
            rotation: modelData.r; transformOrigin: Item.TopLeft
            Rectangle { width: 56; height: 2; color: root.colHi; opacity: 0.8 }
            Rectangle { width: 2; height: 56; color: root.colHi; opacity: 0.8 }
        }
    }

    /* ── Identity disc ── */
    Item {
        id: disc
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.06
        width: root.discSize; height: root.discSize

        // Intro: the disc powers up out of the dark
        opacity: 0; scale: 0.7
        ParallelAnimation {
            running: true
            NumberAnimation { target: disc; property: "opacity"; to: 1; duration: 900; easing.type: Easing.OutCubic }
            NumberAnimation { target: disc; property: "scale"; to: 1; duration: 1200; easing.type: Easing.OutExpo }
        }

        DiscLayer { name: "trail";    period: 1800 }
        DiscLayer { name: "outer";    period: 24000; reverse: true }
        DiscLayer { name: "segments"; period: 9000 }
        DiscLayer { name: "inner";    period: 4500; reverse: true }
        DiscLayer {
            name: "core"
            // heartbeat
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.06; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
            }
        }
    }

    /* ── Wordmark ── */
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: disc.bottom; anchors.topMargin: root.height * 0.04
        spacing: 10

        Text {
            id: wordmark
            anchors.horizontalCenter: parent.horizontalCenter
            text: "TRON"; font.family: "monospace"; font.pixelSize: 44; font.letterSpacing: 24
            color: root.colHi; opacity: 0
            SequentialAnimation on opacity {
                PauseAnimation { duration: 400 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "LEGACY"; font.family: "monospace"; font.pixelSize: 14; font.letterSpacing: 14
            color: root.colDim; opacity: wordmark.opacity * 0.8
        }
    }

    /* ── Progress ── */
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80
        width: 420; height: 30

        Rectangle {
            id: track
            width: parent.width; height: 2; radius: 1
            color: root.colDim; opacity: 0.4
        }
        Rectangle {
            id: fill
            anchors.verticalCenter: track.verticalCenter
            height: 2; radius: 1; color: root.colHi
            width: track.width * root.progress
        }
        // bright head running along the bar
        Rectangle {
            anchors.verticalCenter: track.verticalCenter
            x: fill.width - width / 2
            width: 10; height: 6; radius: 3; color: root.colHi
            opacity: root.progress > 0 && root.progress < 1 ? 1 : 0
        }

        Text {
            anchors.top: track.bottom; anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            text: ["INIT", "LOADING", "MODULES", "SERVICES", "DESKTOP", "WIDGETS", "ENTERING THE GRID"][Math.min(root.stage, 6)]
            font.family: "monospace"; font.pixelSize: 11; font.letterSpacing: 4
            color: root.colDim
        }
    }
}
