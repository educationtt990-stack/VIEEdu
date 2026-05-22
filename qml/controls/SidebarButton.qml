import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Button {
    id: control

    // ===== API =====
    property url iconSource: ""
    property bool active: false

    implicitWidth: 130
    implicitHeight: 48

    hoverEnabled: true

    // ===== COLORS =====
    property color borderHover: Qt.rgba(1, 1, 1, 0.12)
    property color borderActive: Material.accent

    property color bgHover: Qt.rgba(Material.foreground.r,
                                    Material.foreground.g,
                                    Material.foreground.b, 0.06)

    property color bgPressed: Qt.rgba(Material.accent.r,
                                      Material.accent.g,
                                      Material.accent.b, 0.15)

    property color textColor: Material.foreground
    property color textActive: Material.accent

    // ===== SCALE ANIMATION =====
    property real scaleFactor: control.down ? 0.97 : 1.0

    scale: scaleFactor

    Behavior on scaleFactor {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }

    // ===== BACKGROUND =====
    background: Rectangle {
        clip: true
        radius: 10

        // ❗ bình thường = transparent hoàn toàn
        color: control.down ? bgPressed :
               control.hovered ? bgHover :
               (control.active ? Qt.rgba(Material.accent.r, Material.accent.g, Material.accent.b, 0.08)
                               : "transparent")

        border.width: (control.hovered || control.down || control.active) ? 1 : 0
        border.color: control.active ? borderActive : borderHover

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on border.width {
            NumberAnimation { duration: 100 }
        }
    }

    // ===== CONTENT =====
    contentItem: Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ICON
        Item {
            width: 20
            height: 20

            Image {
                id: iconImg
                anchors.fill: parent
                source: control.iconSource
                fillMode: Image.PreserveAspectFit
                visible: false
                smooth: true
                sourceSize.width: 96
                sourceSize.height: 96
            }

            ColorOverlay {
                anchors.fill: iconImg
                source: iconImg
                color: control.active ? textActive : Material.accent
            }
        }

        // TEXT
        Text {
            text: control.text
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter

            color: control.active ? textActive : textColor

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }
    }
}