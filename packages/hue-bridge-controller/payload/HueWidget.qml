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
    Layout.preferredHeight: 88 * groupIDs.length
    radius: Styling.radius(4)
    visible: groupIDs.length <= 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: groupIDs
            HueItem {
                Layout.alignment: Qt.AlignTop
                required property var modelData
                itemID: modelData
                isGroup: true
                Layout.fillWidth: true
              }
        }
    }

    Component.onCompleted: {
        HueService.getGroupsHelper()
    }

}
