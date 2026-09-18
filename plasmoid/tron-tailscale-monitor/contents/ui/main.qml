/*
 * Tron Tailscale Monitor — KDE Plasma 6 Plasmoid
 *
 * Architecture:
 *   - systemd user timer (tron-tailscale.timer) runs fetch.sh every minute
 *   - fetch.sh writes /tmp/tron-tailscale.json
 *   - This QML polls that file and renders peers.
 *
 * Active peers are styled in Tron cyan; inactive (offline) peers in Clu orange/red.
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    // ── Config ──────────────────────────────────────────────────────────────
    property int    cfg_updateInterval: plasmoid.configuration.updateInterval || 60
    property string cfg_tailscalePath:  plasmoid.configuration.tailscalePath  || "tailscale"
    property bool   cfg_showTraffic:    plasmoid.configuration.showTraffic    !== false
    property bool   cfg_showRelay:      plasmoid.configuration.showRelay      !== false
    property bool   cfg_filterOffline:  plasmoid.configuration.filterOffline  || false
    property int    cfg_sortBy:         plasmoid.configuration.sortBy         || 0

    // ── Tron palette ────────────────────────────────────────────────────────
    readonly property color colBg:       "#050A0E"
    readonly property color colCard:     "#0A141E"
    readonly property color colBorder:   "#004858"
    readonly property color colCyan:     "#00F5FF"
    readonly property color colCyanMed:  "#0096A8"
    readonly property color colCyanDim:  "#003848"
    readonly property color colText:     "#80E8F0"
    readonly property color colTextDim:  "#507080"
    readonly property color colGreen:    "#00C8A0"

    // ── Clu palette (for inactive/offline peers) ────────────────────────────
    readonly property color colCluOrange: "#FF9500"
    readonly property color colCluRed:    "#FF3030"
    readonly property color colCluText:   "#FFB380"
    readonly property color colCluDim:    "#4A2010"
    readonly property color colCluBorder: "#804020"

    // ── State ───────────────────────────────────────────────────────────────
    property var    peers:       []
    property string selfHost:    ""
    property string selfIP:      ""
    property string lastUpdated: ""
    property string errorMsg:    ""
    property string infoMsg:     ""
    property bool   loading:     false

    readonly property string tmpFile: "/tmp/tron-tailscale.json"

    implicitWidth:  540
    implicitHeight: 380

    // ── Lifecycle ───────────────────────────────────────────────────────────
    Component.onCompleted: readFile()

    // ── Helpers ─────────────────────────────────────────────────────────────
    function tronColor(isOnline) { return isOnline ? colCyan : colCluOrange }
    function tronTextColor(isOnline) { return isOnline ? colText : colCluText }
    function tronBorderColor(isOnline) { return isOnline ? colCyanDim : colCluBorder }
    function tronBgColor(isOnline) { return isOnline ? colCard : "#120800" }
    function tronDimColor(isOnline) { return isOnline ? colTextDim : "#705040" }
    function tronMedColor(isOnline) { return isOnline ? colCyanMed : "#B86020" }
    function tronGlowColor(isOnline) { return isOnline ? colCyan : colCluRed }
    function tronStatusDot(isOnline) { return isOnline ? colGreen : colCluRed }

    function formatBytes(b) {
        if (b === undefined || b === null || b === 0) return "0 B"
        var bytes = Number(b)
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024*1024) return (bytes/1024).toFixed(1) + " KB"
        if (bytes < 1024*1024*1024) return (bytes/(1024*1024)).toFixed(1) + " MB"
        return (bytes/(1024*1024*1024)).toFixed(2) + " GB"
    }

    function formatDate(iso) {
        if (!iso) return "–"
        var d = new Date(iso)
        if (isNaN(d.getTime())) return iso
        return Qt.formatDateTime(d, "yyyy-MM-dd hh:mm")
    }

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
                        root.peers = []
                        return
                    }
                    try {
                        var raw = JSON.parse(xhr.responseText)
                        if (raw && raw.error) {
                            root.errorMsg = raw.error
                            root.peers = []
                            return
                        }
                        root.selfHost = (raw.Self && raw.Self.HostName) ? raw.Self.HostName : ""
                        root.selfIP   = (raw.Self && raw.Self.TailscaleIPs && raw.Self.TailscaleIPs[0])
                                        ? raw.Self.TailscaleIPs[0] : ""
                        root.peers    = root.processPeers(raw)
                        root.errorMsg = ""
                        root.lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss")
                        if (root.peers.length === 0) {
                            root.infoMsg = "No peers found."
                        }
                    } catch(e) {
                        root.errorMsg = "JSON parse error: " + e.message
                        root.peers = []
                    }
                } else {
                    root.errorMsg = "Cannot read data file (status " + xhr.status + ")"
                    root.peers = []
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
    function processPeers(raw) {
        var result = []
        var selfID = (raw.Self && raw.Self.ID) ? raw.Self.ID : ""

        if (raw.Peer) {
            for (var key in raw.Peer) {
                if (!raw.Peer.hasOwnProperty(key)) continue
                var p = raw.Peer[key]
                // skip self if present in Peer map (some versions include it)
                if (p.ID === selfID) continue

                var online = p.Online === true
                if (root.cfg_filterOffline && !online) continue

                var ip = (p.TailscaleIPs && p.TailscaleIPs[0]) ? p.TailscaleIPs[0] : "–"
                result.push({
                    id:        p.ID || key,
                    name:      p.HostName || "?",
                    dns:       p.DNSName || "",
                    ip:        ip,
                    os:        p.OS || "",
                    relay:     p.Relay || "",
                    online:    online,
                    active:    p.Active === true,
                    rx:        p.RxBytes || 0,
                    tx:        p.TxBytes || 0,
                    lastSeen:  p.LastSeen || "",
                    exitNode:  p.ExitNode === true,
                    exitNodeOption: p.ExitNodeOption === true
                })
            }
        }

        // Sorting
        switch (root.cfg_sortBy) {
            case 1: result.sort(function(a,b){ return a.ip.localeCompare(b.ip) }); break
            case 2: result.sort(function(a,b){ return (b.online?1:0) - (a.online?1:0) || a.name.localeCompare(b.name) }); break
            default: result.sort(function(a,b){ return a.name.localeCompare(b.name) }); break
        }
        return result
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
                    text: "TAILSCALE MESH"
                    font.family: "monospace"; font.pixelSize: 11
                    font.letterSpacing: 4; color: root.colCyan
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.selfHost ? (root.selfHost + "  " + root.selfIP) : ""
                    font.family: "monospace"; font.pixelSize: 9
                    color: root.colTextDim; visible: text !== ""
                }
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: root.loading ? root.colCluOrange : root.colGreen
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
                text: root.errorMsg; color: root.colCluRed
                font.pixelSize: 10; font.family: "monospace"
                wrapMode: Text.Wrap; visible: root.errorMsg !== ""
            }

            // Info
            Text {
                Layout.fillWidth: true
                text: root.infoMsg; color: root.colCluOrange
                font.pixelSize: 10; font.family: "monospace"
                wrapMode: Text.Wrap; visible: root.infoMsg !== "" && root.errorMsg === ""
            }

            // Empty / loading
            Text {
                Layout.fillWidth: true; Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.loading ? "LOADING…" : "NO PEERS"
                font.family: "monospace"; font.pixelSize: 12
                font.letterSpacing: 4; color: root.colTextDim; opacity: 0.5
                visible: root.peers.length === 0 && root.errorMsg === "" && root.infoMsg === ""
            }

            // Peer list
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: width
                contentHeight: peerColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: peerColumn
                    width: parent.width; spacing: 6

                    Repeater {
                        model: root.peers

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: peerCol.implicitHeight + 18
                            radius: 3
                            color: root.tronBgColor(modelData.online)
                            border.color: root.tronBorderColor(modelData.online)
                            border.width: 1

                            // Top glow line
                            Rectangle {
                                visible: modelData.online
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.6; height: 1
                                color: root.tronGlowColor(modelData.online); opacity: 0.5
                            }

                            ColumnLayout {
                                id: peerCol
                                anchors.fill: parent; anchors.margins: 9; spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6

                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: root.tronStatusDot(modelData.online)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.family: "monospace"; font.pixelSize: 12
                                        color: root.tronTextColor(modelData.online)
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.exitNode ? "EXIT" : ""
                                        visible: modelData.exitNode
                                        font.family: "monospace"; font.pixelSize: 8
                                        font.letterSpacing: 2
                                        color: root.colCluRed
                                    }

                                    Text {
                                        text: modelData.online ? "ONLINE" : "OFFLINE"
                                        font.family: "monospace"; font.pixelSize: 9
                                        font.letterSpacing: 2
                                        color: root.tronMedColor(modelData.online)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: modelData.dns !== "" || modelData.ip !== "–"

                                    Text {
                                        text: modelData.ip
                                        font.family: "monospace"; font.pixelSize: 10
                                        color: root.tronColor(modelData.online); opacity: 0.9
                                        Layout.preferredWidth: 110
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.dns
                                        font.family: "monospace"; font.pixelSize: 9
                                        color: root.tronDimColor(modelData.online)
                                        elide: Text.ElideRight
                                        visible: modelData.dns !== ""
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    visible: root.cfg_showRelay || root.cfg_showTraffic

                                    Text {
                                        visible: root.cfg_showRelay && modelData.relay !== ""
                                        text: "DERP " + modelData.relay
                                        font.family: "monospace"; font.pixelSize: 9
                                        font.letterSpacing: 1
                                        color: root.tronDimColor(modelData.online)
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        visible: root.cfg_showTraffic
                                        text: "↓ " + root.formatBytes(modelData.rx) +
                                              "   ↑ " + root.formatBytes(modelData.tx)
                                        font.family: "monospace"; font.pixelSize: 9
                                        color: root.tronMedColor(modelData.online)
                                    }
                                }

                                Text {
                                    visible: modelData.lastSeen !== "" && !modelData.online
                                    text: "Last seen: " + root.formatDate(modelData.lastSeen)
                                    font.family: "monospace"; font.pixelSize: 9
                                    color: root.colCluDim
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
                    text: root.peers.length + " peer" + (root.peers.length !== 1 ? "s" : "")
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
}
