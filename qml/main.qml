import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs
import "controls"

ApplicationWindow {
    id: window
    width: 1000
    height: 700
    visible: true
    title: "VIEEDU"
    onClosing: (close) => {
        close.accepted = false
        window.hide()
    }

    property int currentIndex: 0

    property string effectiveAccent: settingsController ? (settingsController.accentMode === 1 ? settingsController.customAccent : accentColor) : accentColor
    property bool effectiveDark: settingsController ? (settingsController.themeMode === 1 ? false : settingsController.themeMode === 2 ? true : isDark) : isDark
    property string effectivePrimary: settingsController ? (settingsController.primaryMode === 1 ? settingsController.customPrimary : effectiveAccent) : effectiveAccent

    Material.theme: effectiveDark ? Material.Dark : Material.Light
    Material.accent: effectiveAccent
    Material.primary: effectivePrimary

    // ================= MAIN LAYOUT =================
    ColumnLayout {
        spacing: 0
        anchors.fill: parent

        // ================= TITLEBAR =================
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: Qt.darker(Material.backgroundColor, 1.2)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                // ===== LOGO =====
                Item {
                    width: 48
                    height: 48

                    Image {
                        id: iconImg
                        anchors.fill: parent
                        source: "../images/svg_images/titlebar_images/logo.svg"
                        fillMode: Image.PreserveAspectFit
                        visible: false
                        smooth: true
                        sourceSize.width: 96
                        sourceSize.height: 96
                    }

                    ColorOverlay {
                        anchors.fill: iconImg
                        source: iconImg
                        color: Material.accent
                    }
                }

                // ===== TITLE =====
                Column {
                    Layout.alignment: Qt.AlignVCenter

                    Label {
                        text: "VIEEdu"
                        color: Material.accent
                        font.pointSize: 15
                    }

                    Label {
                        text: "Phiên bản 1.0"
                        color: Material.primary
                        font.pointSize: 9
                    }
                }

                // ===== SPACER =====
                Item {
                    Layout.fillWidth: true
                }

                // ===== SEARCH =====
                TitleBarSearch {
                    Layout.alignment: Qt.AlignVCenter
                    stackView: stackView
                }

                // ===== SPACER =====
                Item {
                    Layout.fillWidth: true
                }

                // ===== OPTIONS BUTTON =====
                TitleBarOptionsButton {
                    iconSource: "../../images/svg_images/titlebar_images/settings.svg"
                    stackView: stackView   // 🔥 QUAN TRỌNG
                }
            }
        }

        // ================= BODY =================
        RowLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ===== SIDEBAR =====
            Rectangle {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                color: Qt.darker(Material.backgroundColor, 1.2)

                ScrollView {
                    anchors.fill: parent
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        SidebarButton {
                            text: "Trang chủ"
                            iconSource: "../../images/svg_images/sidebar_images/home.svg"
                            onClicked: stackView.replace("pages/home.qml")
                        }

                        SidebarButton {
                            text: "Ghi chú"
                            iconSource: "../../images/svg_images/sidebar_images/notes.svg"
                            onClicked: stackView.replace("pages/note.qml")
                        }

                        ToolSeparator {
                            height: 11
                            width: parent.width
                        }

                        SidebarButton {
                            text: "Toán học";
                            iconSource: "../../images/svg_images/sidebar_images/math.svg"
                            onClicked: stackView.replace("pages/math.qml")
                        }
                        SidebarButton {
                            text: "Tiếng Anh"
                            iconSource: "../../images/svg_images/sidebar_images/english.svg"
                            onClicked: stackView.push(
                                "pages/english.qml",
                                {
                                    controller: englishController
                                }
                            )
                        }
                    }
                }
            }

            // ===== CONTENT =====
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Material.backgroundColor

                StackView {
                    id: stackView
                    anchors.fill: parent
                    initialItem: "pages/home.qml"
                }
            }
        }
    }

    // ── Independent reminder notification window ──
    Component {
        id: reminderComponent

        Window {
            id: notif
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
            width: 380
            height: 88
            visible: false
            color: "transparent"

            property string noteId: ""
            property string titleText: ""
            property string timeText: ""
            property color bgColor: Qt.darker(Material.backgroundColor, 1.15)
            property color accent: Material.accent

            function popup(id, title, time) {
                noteId = id
                titleText = title
                timeText = time
                x = Screen.desktopAvailableWidth - width - 16
                y = 16
                visible = true
                slideIn.start()
                closeTimer.restart()
            }

            NumberAnimation {
                id: slideIn
                target: notif
                property: "x"
                from: Screen.desktopAvailableWidth
                to: Screen.desktopAvailableWidth - width - 16
                duration: 350
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: slideOut
                target: notif
                property: "x"
                to: Screen.desktopAvailableWidth
                duration: 250
                easing.type: Easing.InCubic
                onFinished: destroy()
            }

            Timer {
                id: closeTimer
                interval: 6000
                onTriggered: slideOut.start()
            }

            // Card background
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: notif.bgColor

                // Accent left bar
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 5; radius: 2.5
                    anchors.leftMargin: 6; anchors.topMargin: 10; anchors.bottomMargin: 10
                    color: notif.accent
                }

                // Subtle border
                Rectangle {
                    anchors.fill: parent; radius: 14
                    color: "transparent"
                    border.color: Qt.rgba(notif.accent.r, notif.accent.g, notif.accent.b, 0.25)
                    border.width: 1
                }

                RowLayout {
                    anchors { fill: parent; margins: 14; leftMargin: 18 }
                    spacing: 10

                    Label { text: "⏰"; font.pointSize: 22 }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Label {
                            text: notif.titleText
                            font.bold: true
                            font.pointSize: 11
                            color: notif.accent
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: notif.timeText
                            color: Qt.rgba(0.5,0.5,0.5,0.8)
                            font.pointSize: 9
                        }
                    }

                    ToolButton {
                        text: "✕"
                        font.pointSize: 12
                        implicitWidth: 26; implicitHeight: 26
                        onClicked: slideOut.start()
                    }
                }

                // Click anywhere → raise main window
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        window.raise()
                        window.requestActivate()
                        stackView.replace("pages/note.qml")
                        slideOut.start()
                    }
                }
            }
        }
    }

    Connections {
        target: notesController
        function onReminderDue(noteId, title, reminderAt) {
            // Play sound (handled in Python via winsound)
            window.raise()
            window.requestActivate()
            var obj = reminderComponent.createObject(null)
            obj.popup(noteId, title, reminderAt)
        }
    }
}
