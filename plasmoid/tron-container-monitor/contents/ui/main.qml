/*
 * Tron Container Monitor — KDE Plasma 6 Plasmoid
 *
 * Architecture:
 *   - systemd user timer (tron-containers.timer) runs fetch.sh every minute
 *   - fetch.sh writes /tmp/tron-containers.json
 *   - This QML polls that file and renders the data.
 *
 * Imports: QtQuick + QtQuick.Layouts + org.kde.plasma.plasmoid only.
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    // ── Config ──────────────────────────────────────────────────────────────
    property int    cfg_updateInterval: plasmoid.configuration.updateInterval || 60
    property int    cfg_sortBy:         plasmoid.configuration.sortBy         || 0
    property bool   cfg_filterStopped:  plasmoid.configuration.filterStopped  || false
    property bool   cfg_showNet:        plasmoid.configuration.showNet        !== false
    property int    cfg_maxCards:       plasmoid.configuration.maxCards       || 0

    // ── Tron palette ────────────────────────────────────────────────────────
    readonly property color colBg:      "#050A0E"
    readonly property color colCard:    "#0A141E"
    readonly property color colBorder:  "#004858"
    readonly property color colCyan:    "#00F5FF"
    readonly property color colCyanMed: "#0096A8"
    readonly property color colCyanDim: "#003848"
    readonly property color colOrange:  "#FF9500"
    readonly property color colRed:     "#FF3030"
    readonly property color colText:    "#80E8F0"
    readonly property color colTextDim: "#507080"
    readonly property color colGreen:   "#00C8A0"

    // ── State ───────────────────────────────────────────────────────────────
    property var    containers:  []
    property string lastUpdated: ""
    property string errorMsg:    ""
    property string infoMsg:     ""
    property bool   loading:     false

    readonly property string tmpFile: "/tmp/tron-containers.json"

    implicitWidth:  660
    implicitHeight: 420

    // ── Lifecycle ───────────────────────────────────────────────────────────
    Component.onCompleted: readFile()

    // ── File reader ─────────────────────────────────────────────────────────
    function readFile() {
        if (root.loading) return
        root.loading = true
        root.errorMsg = ""
        root.infoMsg  = ""

        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + root.tmpFile, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false
                if (xhr.status === 0 || xhr.status === 200) {
                    if (xhr.responseText === "") {
                        root.errorMsg = "Data file not found.\nInstall the systemd timer: ./install.sh"
                        root.containers = []
                        return
                    }
                    try {
                        var raw = JSON.parse(xhr.responseText)
                        // fetch.sh writes {"error":"..."} on failure
                        if (raw && raw.error) {
                            root.errorMsg = raw.error
                            root.containers = []
                            return
                        }
                        if (!Array.isArray(raw)) {
                            root.errorMsg = "Unexpected data format."
                            root.containers = []
                            return
                        }
                        root.containers  = root.processContainers(raw)
                        root.errorMsg    = ""
                        root.lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss")
                        if (root.containers.length === 0 && raw.length === 0) {
                            root.infoMsg = "No containers found."
                        }
                    } catch(e) {
                        root.errorMsg = "JSON parse error: " + e.message
                        root.containers = []
                    }
                } else {
                    root.errorMsg = "Cannot read data file (status " + xhr.status + ")"
                    root.containers = []
                }
            }
        }
        xhr.send()
    }

    // ── Poll timer ──────────────────────────────────────────────────────────
    Timer {
        id: pollTimer
        interval: root.cfg_updateInterval * 1000
        repeat:   true
        running:  true
        triggeredOnStart: false
        onTriggered: root.readFile()
    }

    // ── Data processing ─────────────────────────────────────────────────────
    function processContainers(raw) {
        var result = []
        for (var i = 0; i < raw.length; i++) {
            var c   = raw[i]
            var cpu = parseFloat((c.cpu_percent || "0%").replace("%","")) || 0
            var mem = parseFloat((c.mem_percent || "0%").replace("%","")) || 0
            var parts    = (c.mem_usage || "0B / 0B").split("/")
            var memUsed  = parts[0] ? parts[0].trim() : "0B"
            var memLimit = parts[1] ? parts[1].trim() : "0B"
            if (root.cfg_filterStopped && cpu === 0 && mem === 0) continue
            result.push({
                name:     c.name    || c.id || "?",
                id:       (c.id     || "").substring(0, 12),
                cpu:      cpu,
                mem:      mem,
                memUsed:  memUsed,
                memLimit: memLimit,
                netIo:    c.net_io  || "–",
                pids:     parseInt(c.pids) || 0,
                cpuTime:  c.cpu_time || "",
                status:   (cpu === 0 && mem === 0) ? "stopped" : "running"
            })
        }
        switch (root.cfg_sortBy) {
            case 1: result.sort(function(a,b){ return b.cpu - a.cpu }); break
            case 2: result.sort(function(a,b){ return b.mem - a.mem }); break
            case 3: result.sort(function(a,b){ return parseFloat(b.memUsed) - parseFloat(a.memUsed) }); break
            default: result.sort(function(a,b){ return a.name.localeCompare(b.name) }); break
        }
        // maxCards limit
        if (root.cfg_maxCards > 0 && result.length > root.cfg_maxCards) {
            result = result.slice(0, root.cfg_maxCards)
        }
        return result
    }

    function barColor(pct) {
        if (pct >= 85) return colRed
        if (pct >= 60) return colOrange
        return colCyan
    }

    // ── UI ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.colBg; radius: 4
        border.color: root.colBorder; border.width: 1

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8; height: 1
            color: root.colCyan; opacity: 0.7
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text {
                    text: "CONTAINER MONITOR"
                    font.family: "monospace"; font.pixelSize: 11
                    font.letterSpacing: 4; color: root.colCyan
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: root.loading ? root.colOrange : root.colGreen
                    SequentialAnimation on opacity {
                        running: root.loading; loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 500 }
                        NumberAnimation { to: 0.9; duration: 500 }
                    }
                }
                Text {
                    text: root.lastUpdated || "–"
                    font.family: "monospace"; font.pixelSize: 10
                    color: root.colTextDim
                }
                Rectangle {
                    width: 22; height: 22; radius: 2
                    color: refreshMouse.containsMouse ? root.colCyanDim : "transparent"
                    border.color: root.colBorder; border.width: 1
                    Text {
                        anchors.centerIn: parent; text: "↻"
                        color: refreshMouse.containsMouse ? root.colCyan : root.colTextDim
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: refreshMouse; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.readFile()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: root.colBorder }

            // Error
            Text {
                Layout.fillWidth: true
                text: root.errorMsg; color: root.colRed
                font.pixelSize: 10; font.family: "monospace"
                wrapMode: Text.Wrap; visible: root.errorMsg !== ""
            }

            // Info (e.g. "No containers")
            Text {
                Layout.fillWidth: true
                text: root.infoMsg; color: root.colOrange
                font.pixelSize: 10; font.family: "monospace"
                wrapMode: Text.Wrap; visible: root.infoMsg !== "" && root.errorMsg === ""
            }

            // Empty / loading
            Text {
                Layout.fillWidth: true; Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.loading ? "LOADING…" : "NO CONTAINERS"
                font.family: "monospace"; font.pixelSize: 12
                font.letterSpacing: 4; color: root.colTextDim; opacity: 0.5
                visible: root.containers.length === 0 && root.errorMsg === "" && root.infoMsg === ""
            }

            // Cards
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: width
                contentHeight: cardFlow.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: cardFlow; width: parent.width; spacing: 8

                    Repeater {
                        model: root.containers

                        Rectangle {
                            width: 300
                            height: root.cfg_showNet ? 118 : 96
                            radius: 3; color: root.colCard
                            border.color: modelData.status === "stopped"
                                          ? root.colBorder : root.colCyanDim
                            border.width: 1

                            Rectangle {
                                visible: modelData.status === "running"
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.6; height: 1
                                color: root.colCyan; opacity: 0.5
                            }

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: modelData.status === "running"
                                               ? root.colGreen : root.colTextDim
                                    }
                                    Text {
                                        Layout.fillWidth: true; text: modelData.name
                                        font.family: "monospace"; font.pixelSize: 12
                                        color: root.colText; elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "PID " + modelData.pids
                                        font.family: "monospace"; font.pixelSize: 9
                                        color: root.colTextDim; visible: modelData.pids > 0
                                    }
                                }

                                MiniBar {
                                    Layout.fillWidth: true
                                    label: "CPU"; value: modelData.cpu
                                    detail: modelData.cpu.toFixed(1) + "%"
                                    barCol: root.barColor(modelData.cpu)
                                    textDim: root.colTextDim; bgCol: root.colCyanDim
                                }
                                MiniBar {
                                    Layout.fillWidth: true
                                    label: "RAM"; value: modelData.mem
                                    detail: modelData.memUsed + " / " + modelData.memLimit
                                    barCol: root.barColor(modelData.mem)
                                    textDim: root.colTextDim; bgCol: root.colCyanDim
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: root.cfg_showNet
                                    Text {
                                        text: "NET"; font.family: "monospace"
                                        font.pixelSize: 9; font.letterSpacing: 2
                                        color: root.colTextDim; Layout.preferredWidth: 26
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "↑↓ " + modelData.netIo
                                        font.family: "monospace"; font.pixelSize: 9
                                        color: root.colCyanMed; elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.cpuTime
                                        font.family: "monospace"; font.pixelSize: 9
                                        color: root.colTextDim; opacity: 0.6
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.containers.length + " container" +
                          (root.containers.length !== 1 ? "s" : "")
                    font.family: "monospace"; font.pixelSize: 10
                    font.letterSpacing: 2; color: root.colTextDim
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "↻ " + root.cfg_updateInterval + "s"
                    font.family: "monospace"; font.pixelSize: 10
                    color: root.colTextDim; opacity: 0.6
                }
            }
        }
    }

    component MiniBar: RowLayout {
        property string label:   ""
        property real   value:   0
        property string detail:  ""
        property color  barCol:  "#00F5FF"
        property color  textDim: "#507080"
        property color  bgCol:   "#003848"
        spacing: 4

        Text {
            text: label; font.family: "monospace"
            font.pixelSize: 9; font.letterSpacing: 2
            color: textDim; Layout.preferredWidth: 26
        }
        Rectangle {
            Layout.fillWidth: true; height: 5; radius: 2; color: bgCol
            Rectangle {
                width: Math.max(0, Math.min(1, value / 100)) * parent.width
                height: parent.height; radius: 2; color: barCol
                Behavior on width {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(parent.width, 12); height: parent.height; radius: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: "#60FFFFFF" }
                    }
                    visible: parent.width > 4
                }
            }
        }
        Text {
            text: detail; font.family: "monospace"; font.pixelSize: 9
            color: barCol; Layout.preferredWidth: 110; elide: Text.ElideRight
        }
    }
}
