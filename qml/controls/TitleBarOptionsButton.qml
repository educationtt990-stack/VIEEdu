import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string iconSource: ""
    property var stackView   // 🔥 nhận từ main.qml

    implicitWidth: 50
    implicitHeight: 50

    // ================= BUTTON =================
    Button {
        id: btn
        anchors.fill: parent
        flat: true
        hoverEnabled: true

        property bool pressedState: false
        scale: pressedState ? 0.94 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        onPressed: pressedState = true
        onReleased: pressedState = false
        onCanceled: pressedState = false

        onClicked: menu.open()

        background: Rectangle {
            radius: 10
            color: btn.pressed
                   ? Qt.rgba(Material.accent.r, Material.accent.g, Material.accent.b, 0.18)
                   : btn.hovered
                     ? Qt.rgba(1,1,1,0.06)
                     : "transparent"
        }

        contentItem: Item {
            anchors.fill: parent

            Item {
                width: 18
                height: 18
                anchors.centerIn: parent

                Image {
                    id: img
                    anchors.fill: parent
                    source: root.iconSource
                    fillMode: Image.PreserveAspectFit
                    opacity: 0

                    // rotation: menu.open ? 90 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 180 }
                    }
                    smooth: true
                    sourceSize.width: 96
                    sourceSize.height: 96
                }

                ColorOverlay {
                    anchors.fill: img
                    source: img
                    color: Material.accent
                }
            }
        }
    }

    // ================= DROPDOWN =================
    Popup {
        id: menu

        x: parent.width - width
        y: parent.height + 6
        // width: 180

        modal: false
        focus: true

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: Material.background
            border.color: Material.accent
        }

        Column {
            width: parent.width
            spacing: 4

            SidebarButton {
                text: "Cài đặt"
                iconSource: "../../images/svg_images/titlebar_images/settings.svg"
                onClicked: {
                    if (root.stackView)
                        root.stackView.replace(Qt.resolvedUrl("../pages/settings.qml"))
                    menu.close()
                }
            }

            SidebarButton {
                text: "Thoát"
                iconSource: "../../images/svg_images/titlebar_images/power.svg"
                onClicked: {
                    menu.close()
                    Qt.quit()
                }
            }
        }
    }
}