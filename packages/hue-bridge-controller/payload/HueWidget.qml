import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

StyledRect {
    id: huePane
    variant: "pane"
    Layout.fillWidth: true
    Layout.preferredHeight: 88
    radius: Styling.radius(4)

    property bool isPowered: HueService.on
    property var lights: HueService.lights

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: lights
            RowLayout {
                id: lightList
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                required property var modelData

                StyledRect {
                    id: lightSelect
                    variant: "internalbg"
                    Layout.preferredHeight: 80
                    Layout.fillWidth: true
                    radius: Styling.radius(0)

                    property bool expanded: false
                    //property bool hovered: expandedBtn.containsMouse

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        RowLayout {
                            Layout.preferredWidth: parent.width
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text: modelData.name //HueService.lights[modelData].name
                                font.family: Config.defaultFont
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: lightSelect.item
                                horizontalAlignment: Text.AlignHCenter
                            }
                            // StyledRect {
                            //     id: buttonBackground
                            //     Layout.alignment: Qt.AlignRight
                            //     Layout.preferredHeight: 18
                            //     Layout.preferredWidth: 32
                            //     variant: lightSelect.expanded ? (expandedBtn.containsMouse ? "primaryfocus" : "primary") : (expandedBtn.containsMouse ? "focus" : "common")
                            //     radius: Styling.radius(0)

                            //     MouseArea {
                            //         id: expandedBtn
                            //         anchors.fill: parent
                            //         hoverEnabled: true

                            //         onClicked:mouse => {
                            //             if (root.isSeparator)
                            //                 return;

                            //             if (mouse.button === Qt.LeftButton) {
                            //                 lightSelect.expanded = !lightSelect.expanded
                            //             }
                            //             return;
                            //         }
                            //     }

                            //     Text {
                            //         anchors.fill: parent
                            //         anchors.verticalCenter: buttonBackground.verticalCenter
                            //         text: lightSelect.expanded ? Icons.caretUp : Icons.caretDown
                            //         textFormat: Text.RichText
                            //         font.family: Icons.font
                            //         font.pixelSize: Config.theme.fontSize
                            //         color: buttonBackground.item
                            //         horizontalAlignment: Text.AlignHCenter
                            //     }
                            // }

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
                                    value: HueService.bri/255
                                    resizeParent: false
                                    wavy: HueService.on
                                    wavyAmplitude: HueService.on ? 1.5 * value : 0
                                    wavyFrequency: HueService.on ? 8.0 * value : 0
                                    scroll: false
                                    iconClickable: false
                                    sliderVisible: true
                                    iconPos: "start"
                                    icon: ""
                                    progressColor: HueService.on ? Styling.srItem("overprimary") : Styling.srItem("focus")

                                    property real brightnessValue: 0

                                    Component.onCompleted: {
                                        brightnessValue = HueService.bri/255;
                                    }

                                    onValueChanged: {
                                        brightnessValue = value;
                                        HueService.setBrightness(Math.round(value*255));
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
                                    if (isPowered && huePowerHover)
                                        return "primaryfocus";
                                    if (isPowered)
                                        return "primary";
                                    if (huePowerHover)
                                        return "focus";
                                    return "pane";
                                }
                                radius: isPowered ? Styling.radius(4) : Styling.radius(0)

                                Text {
                                    id: huePowerBtn
                                    anchors.centerIn: parent
                                    text: isPowered ? Icons.sun : Icons.sunDim
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
                                    onClicked: HueService.togglePower()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        HueService.widgetHelper()
    }
}
