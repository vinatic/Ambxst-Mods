import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config
import qs.modules.widgets.dashboard.hue

// Componente principal para el selector de fondos de pantalla.
StyledRect {
    id: root
    variant: "transparent"

    Component.onCompleted: {
        HueService.initialize()
    }

    property var groupIDs: HueService.groups != null ? Object.keys(HueService.groups) : []

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: huePane
                anchors.fill: parent

                Item {
                    anchors.fill: parent
                    visible: groupIDs.length < 1

                    Text {
                        anchors.centerIn: parent
                        text: "No lights found :p"
                        font.family: Config.defaultFont
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: Colors.overBackground
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Flickable {
                    id: lightsFlickable
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: columnLayout.implicitHeight
                    clip: true
                    interactive: true

                    ColumnLayout {
                        id: columnLayout
                        Layout.preferredHeight: 80
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: groupIDs
                            Item {
                                id: groupSelect

                                required property var modelData
                                property bool expanded: false

                                Layout.alignment: Qt.AlignTop
                                Layout.preferredHeight: expanded ? HueService.groups[modelData].lights.length * 88 + 92 : 88
                                Layout.fillWidth: true

                                Behavior on Layout.preferredHeight {
                                    enabled: Config.animDuration > 0
                                    NumberAnimation {
                                        duration: Config.animDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                StyledRect {
                                    anchors.fill: parent
                                    variant: mouseArea.containsMouse ? "focus" : "common"
                                    radius: Styling.radius(4)
                                    StyledRect {
                                      anchors.fill: parent
                                      anchors.margins: 4
                                      variant: "internalbg"
                                      radius: Styling.radius(4)
                                    }
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: groupSelect.expanded = !groupSelect.expanded
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignTop
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 4

                                    HueItem {
                                      Layout.alignment: Qt.AlignTop
                                      itemID: modelData
                                      isGroup: true
                                      width: groupSelect.width - 4
                                    }

                                    Separator {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 8
                                        Layout.rightMargin: 12
                                        visible: groupSelect.expanded
                                    }

                                    Repeater {
                                        model: HueService.groups[modelData].lights
                                        HueItem {
                                            Layout.alignment: Qt.AlignTop
                                            required property var modelData
                                            itemID: modelData
                                            isGroup: false
                                            width: groupSelect.width - 4
                                            visible: groupSelect.expanded
                                          }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        StyledRect {
          id: colorPreview
          variant: "common"
          implicitWidth: 275
          Layout.fillHeight: true
          radius: Styling.radius(4)

          StyledRect {
            anchors.fill: parent
            anchors.margins: 4
            variant: "internalbg"
            radius: Styling.radius(4)
          }
          Item {
            id: colorRectPreview
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 2
            height: 200
            Rectangle {
              id: colorRect
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter
              width: 175
              height: 175
              color: HueService.hueColor
              radius: 4
            }
          }
          ColumnLayout {
            anchors.top: colorRectPreview.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 2
            spacing: 4
            // Slider
            Item {
                id: red
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.alignment: Qt.AlignHCenter

                StyledSlider {
                    id: redSlider
                    anchors.fill: parent
                    anchors.margins: 0
                    vertical: false
                    smoothDrag: true
                    value: HueService.hueColor.r
                    resizeParent: false
                    wavy: false
                    scroll: false
                    iconClickable: false
                    sliderVisible: true
                    iconPos: "start"
                    icon: ""
                    updateOnRelease: HueService.updateOnRelease
                    progressColor: Colors.red

                    onValueChanged: {
                        HueService.hueColor.r = value
                        colorRect.color = HueService.hueColor
                    }
                }
            }

            // Slider
            Item {
                id: green
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.alignment: Qt.AlignHCenter

                StyledSlider {
                    id: greenSlider
                    anchors.fill: parent
                    anchors.margins: 0
                    vertical: false
                    smoothDrag: true
                    value: HueService.hueColor.g
                    resizeParent: false
                    wavy: false
                    scroll: false
                    iconClickable: false
                    sliderVisible: true
                    iconPos: "start"
                    icon: ""
                    updateOnRelease: HueService.updateOnRelease
                    progressColor: Colors.green

                    onValueChanged: {
                        HueService.hueColor.g = value
                        colorRect.color = HueService.hueColor
                    }
                }
            }

            // Slider
            Item {
                id: blue
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.alignment: Qt.AlignHCenter

                StyledSlider {
                    id: blueSlider
                    anchors.fill: parent
                    anchors.margins: 0
                    vertical: false
                    smoothDrag: true
                    value: HueService.hueColor.b
                    resizeParent: false
                    wavy: false
                    scroll: false
                    iconClickable: false
                    sliderVisible: true
                    iconPos: "start"
                    icon: ""
                    updateOnRelease: HueService.updateOnRelease
                    progressColor: Colors.blue

                    onValueChanged: {
                        HueService.hueColor.b = value
                        colorRect.color = HueService.hueColor
                    }
                }
            }

          }
        }
    }
}
