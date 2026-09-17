import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Item {
    id: root
    required property var itemID
    required property bool isGroup
    property var itemData: isGroup ? HueService.groups[itemID] : HueService.lights[itemID]
    height: 80

    onItemDataChanged: {
        if (visible && !isGroup) {
            brightnessSlider.value = HueService.lights[itemID].bri/255
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2
        RowLayout {
            Layout.preferredWidth: parent.width
            Text {
                Layout.alignment: Qt.AlignLeft
                text: itemData.name
                font.family: Config.defaultFont
                font.pixelSize: 20
                font.weight: Font.Bold
                color: Colors.overBackground
                horizontalAlignment: Text.AlignHCenter
            }
        }
        // Brightness slider - vertical
        RowLayout {
            id: brightnessContainer
            Layout.fillWidth: true
            // Layout.minimumHeight: 100
            spacing: 4

            // Slider
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignHCenter

                StyledSlider {
                    id: brightnessSlider
                    anchors.fill: parent
                    anchors.margins: 0
                    vertical: false
                    smoothDrag: true
                    value: isGroup ? HueService.groups[itemID].bri/255 : HueService.lights[itemID].bri/255
                    resizeParent: false
                    wavy: isGroup ? itemData.any_on : itemData.on
                    wavyAmplitude: (isGroup ? itemData.any_on : itemData.on) ? 1.5 * value : 0
                    wavyFrequency: (isGroup ? itemData.any_on : itemData.on) ? 8.0 * value : 0
                    scroll: false
                    iconClickable: false
                    sliderVisible: true
                    iconPos: "start"
                    icon: ""
                    updateOnRelease: HueService.updateOnRelease
                    progressColor: (isGroup ? itemData.any_on : itemData.on) ? Styling.srItem("overprimary") : Styling.srItem("focus")

                    onVisibleChanged: {
                        if (visible) {
                            value = isGroup ? HueService.groups[itemID].bri/255 : HueService.lights[itemID].bri/255
                        }
                    }

                    onValueChanged: {
                        if (isGroup) {
                          if (HueService.groups[itemID].bri !== Math.round(value*255)) {
                            HueService.setGroupBrightness(itemID, Math.round(value*255));
                          }
                        } else {
                          if (HueService.lights[itemID].bri !== Math.round(value*255)) {
                            HueService.setBrightness(itemID, Math.round(value*255));
                          }
                        }
                    }
                }
            }

            // Icon container with sync animation
            StyledRect {
                id: huePowerButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                variant: {
                    if ((isGroup ? itemData.any_on : itemData.on) && huePowerHover)
                        return "primaryfocus";
                    if (isGroup ? itemData.any_on : itemData.on)
                        return "primary";
                    if (huePowerHover)
                        return "focus";
                    return "pane";
                }
                radius: (isGroup ? itemData.any_on : itemData.on) ? Styling.radius(4) : Styling.radius(0)

                Text {
                    id: huePowerBtn
                    anchors.centerIn: parent
                    text: (isGroup ? itemData.any_on : itemData.on) ? Icons.sun : Icons.sunDim
                    textFormat: Text.RichText
                    color: huePowerButton.item
                    font.pixelSize: 20
                    font.family: Icons.font
                }

                HoverHandler {
                    id: huePowerHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isGroup) {
                          HueService.toggleGroupPower(itemData.id);
                            itemData.any_on = !itemData.any_on
                        } else {
                            HueService.togglePower(itemData.id);
                        }
                    }
                }
            }
        }
    }
}
