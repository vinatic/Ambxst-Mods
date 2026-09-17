import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.widgets.dashboard.hue

StyledRect {
    id: huePane
    variant: "pane"

    property var groupIDs: HueService.groups != null ? Object.keys(HueService.groups) : []

    Layout.fillWidth: true
    Layout.preferredHeight: groupIDs.length * 88
    radius: Styling.radius(4)
    visible: groupIDs.length >= 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4

        Repeater {
            model: groupIDs
            Item {
                required property var modelData
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                StyledRect {
                  anchors.fill: parent
                  variant: "internalbg"
                  radius: Styling.radius(4)
                }
                HueItem {
                    anchors.fill: parent
                    itemID: modelData
                    isGroup: true
                }
            }
        }
    }

    Component.onCompleted: {
        HueService.initialize()
    }

}
