import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: root

    property alias cfg_updateInterval:  intervalSpin.value
    property alias cfg_tailscalePath:   tailscalePathField.text
    property alias cfg_showTraffic:     showTrafficCheck.checked
    property alias cfg_showRelay:       showRelayCheck.checked
    property alias cfg_filterOffline:   filterOfflineCheck.checked
    property alias cfg_sortBy:          sortCombo.currentIndex

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: "Update interval (seconds):"
        from: 10
        to:   300
        value: 60
    }

    QQC2.TextField {
        id: tailscalePathField
        Kirigami.FormData.label: "tailscale binary path:"
        text: "tailscale"
        placeholderText: "/usr/bin/tailscale"
    }

    QQC2.ComboBox {
        id: sortCombo
        Kirigami.FormData.label: "Sort peers by:"
        model: ["Name", "IP", "Status (online first)"]
        currentIndex: 0
    }

    QQC2.CheckBox {
        id: showTrafficCheck
        Kirigami.FormData.label: "Show traffic stats:"
        checked: true
    }

    QQC2.CheckBox {
        id: showRelayCheck
        Kirigami.FormData.label: "Show DERP relay:"
        checked: true
    }

    QQC2.CheckBox {
        id: filterOfflineCheck
        Kirigami.FormData.label: "Hide offline peers:"
        checked: false
    }
}
