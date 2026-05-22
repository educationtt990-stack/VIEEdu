import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: flick.width
            spacing: 0
            leftPadding: 32
            rightPadding: 32
            topPadding: 32
            bottomPadding: 32

            Label {
                text: "Cài đặt giao diện"
                font { pixelSize: 22; weight: Font.Bold }
                color: Material.foreground
                bottomPadding: 24
            }

            // ── Theme ────────────────────────────────────
            Label {
                text: "Chủ đề"
                font { pixelSize: 13; weight: Font.Medium }
                color: Material.accent
                bottomPadding: 8
            }

            Repeater {
                model: [
                    { label: "Tự động (theo Windows)", value: 0 },
                    { label: "Sáng",                    value: 1 },
                    { label: "Tối",                     value: 2 },
                ]

                delegate: RowLayout {
                    height: 36
                    spacing: 10

                    RadioButton {
                        id: radio
                        checked: settingsController.themeMode === modelData.value
                        onCheckedChanged: {
                            if (checked) settingsController.themeMode = modelData.value
                        }
                        ButtonGroup.group: themeGroup
                    }

                    Label {
                        text: modelData.label
                        font.pixelSize: 13
                        color: Material.foreground
                    }
                }
            }

            ButtonGroup { id: themeGroup }

            Item { height: 28 }

            // ── Accent Color ─────────────────────────────
            Label {
                text: "Màu nhấn"
                font { pixelSize: 13; weight: Font.Medium }
                color: Material.accent
                bottomPadding: 8
            }

            RowLayout {
                height: 36
                spacing: 10

                RadioButton {
                    checked: settingsController.accentMode === 0
                    onCheckedChanged: {
                        if (checked) settingsController.accentMode = 0
                    }
                    ButtonGroup.group: accentGroup
                }

                Label {
                    text: "Tự động (màu Windows)"
                    font.pixelSize: 13
                    color: Material.foreground
                }
            }

            RowLayout {
                height: 36
                spacing: 10

                RadioButton {
                    checked: settingsController.accentMode === 1
                    onCheckedChanged: {
                        if (checked) settingsController.accentMode = 1
                    }
                    ButtonGroup.group: accentGroup
                }

                Label {
                    text: "Tùy chỉnh"
                    font.pixelSize: 13
                    color: Material.foreground
                }
            }

            ButtonGroup { id: accentGroup }

            Item { height: 12 }

            // ── Color presets ────────────────────────────
            Item {
                width: parent.width
                height: visible ? flowAccent.implicitHeight + 4 : 0
                visible: settingsController.accentMode === 1

                Flow {
                    id: flowAccent
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Repeater {
                        model: settingsController.colorPresets

                        delegate: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 20
                            color: modelData

                            border {
                                width: settingsController.customAccent === modelData ? 3 : 1
                                color: settingsController.customAccent === modelData
                                       ? Material.foreground
                                       : Qt.rgba(0,0,0,0.12)
                            }

                            Behavior on border.width { NumberAnimation { duration: 100 } }

                            TapHandler {
                                onTapped: settingsController.customAccent = modelData
                            }
                        }
                    }
                }
            }

            Item { height: 28 }

            // ── Primary Color ────────────────────────────
            Label {
                text: "Màu chính (Primary)"
                font { pixelSize: 13; weight: Font.Medium }
                color: Material.accent
                bottomPadding: 8
            }

            RowLayout {
                height: 36
                spacing: 10

                RadioButton {
                    checked: settingsController.primaryMode === 0
                    onCheckedChanged: {
                        if (checked) settingsController.primaryMode = 0
                    }
                    ButtonGroup.group: primaryGroup
                }

                Label {
                    text: "Tự động (theo Accent)"
                    font.pixelSize: 13
                    color: Material.foreground
                }
            }

            RowLayout {
                height: 36
                spacing: 10

                RadioButton {
                    checked: settingsController.primaryMode === 1
                    onCheckedChanged: {
                        if (checked) settingsController.primaryMode = 1
                    }
                    ButtonGroup.group: primaryGroup
                }

                Label {
                    text: "Tùy chỉnh"
                    font.pixelSize: 13
                    color: Material.foreground
                }
            }

            ButtonGroup { id: primaryGroup }

            Item { height: 12 }

            Item {
                width: parent.width
                height: visible ? flowPrimary.implicitHeight + 4 : 0
                visible: settingsController.primaryMode === 1

                Flow {
                    id: flowPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Repeater {
                        model: settingsController.colorPresets

                        delegate: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 20
                            color: modelData

                            border {
                                width: settingsController.customPrimary === modelData ? 3 : 1
                                color: settingsController.customPrimary === modelData
                                       ? Material.foreground
                                       : Qt.rgba(0,0,0,0.12)
                            }

                            Behavior on border.width { NumberAnimation { duration: 100 } }

                            TapHandler {
                                onTapped: settingsController.customPrimary = modelData
                            }
                        }
                    }
                }
            }

            Item { height: 28 }

            // ── Preview ──────────────────────────────────
            Label {
                text: "Xem trước"
                font { pixelSize: 13; weight: Font.Medium }
                color: Material.accent
                bottomPadding: 8
            }

            Rectangle {
                width: parent.width
                height: 80
                radius: 10
                color: Material.background

                border { width: 1; color: Qt.rgba(0,0,0,0.08) }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    RowLayout {
                        spacing: 12
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                            implicitWidth: 20; implicitHeight: 20; radius: 10
                            color: Material.accent
                        }

                        Label {
                            text: "Accent"
                            font { pixelSize: 12 }
                            color: Material.accent
                        }
                    }

                    RowLayout {
                        spacing: 12
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                            implicitWidth: 20; implicitHeight: 20; radius: 10
                            color: Material.primary
                        }

                        Label {
                            text: "Primary"
                            font { pixelSize: 12 }
                            color: Material.primary
                        }
                    }


                }
            }

            Item { height: 28 }

            // ── Reset ────────────────────────────────────
            Button {
                text: "Đặt lại mặc định"
                flat: true
                font.pixelSize: 12
                onClicked: {
                    settingsController.themeMode = 0
                    settingsController.accentMode = 0
                    settingsController.customAccent = "#1565C0"
                    settingsController.primaryMode = 0
                    settingsController.customPrimary = "#1565C0"

                }
            }
        }
    }
}
