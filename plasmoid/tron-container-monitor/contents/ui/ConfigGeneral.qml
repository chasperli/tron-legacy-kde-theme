import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: root

    property alias cfg_updateInterval:  intervalSpin.value
    property alias cfg_podmanPath:      podmanPathField.text
    property alias cfg_showNet:         showNetCheck.checked
    property alias cfg_maxCards:        maxCardsSpin.value
    property alias cfg_sortBy:          sortCombo.currentIndex
    property alias cfg_filterStopped:   filterStoppedCheck.checked

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: "Update interval (seconds):"
        from: 10
        to:   300
        value: 60
    }

    QQC2.TextField {
        id: podmanPathField
        Kirigami.FormData.label: "podman binary path:"
        text: "podman"
        placeholderText: "/usr/bin/podman"
    }

    QQC2.ComboBox {
        id: sortCombo
        Kirigami.FormData.label: "Sort containers by:"
        model: ["Name", "CPU %", "RAM %", "RAM used"]
        currentIndex: 0
    }

    QQC2.CheckBox {
        id: showNetCheck
        Kirigami.FormData.label: "Show Net I/O bar:"
        checked: true
    }

    QQC2.CheckBox {
        id: filterStoppedCheck
        Kirigami.FormData.label: "Hide stopped containers:"
        checked: false
    }

    QQC2.SpinBox {
        id: maxCardsSpin
        Kirigami.FormData.label: "Max cards shown (0 = all):"
        from: 0
        to:   50
        value: 0
    }
}
