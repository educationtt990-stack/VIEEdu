import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

TextField {
    id: searchBox

    property var stackView

    implicitWidth: 400
    height: 32

    placeholderText: "\uD83D\uDD0D Tìm nhanh..."

    property color placeholderNormal: Qt.rgba(Material.accent.r,Material.accent.g,Material.accent.b,0.5)
    property color placeholderFocused: Qt.rgba(0,0,0,0)

    placeholderTextColor: {
        if (searchBox.text.length > 0)
            return Qt.rgba(0,0,0,0)
        if (searchBox.activeFocus)
            return placeholderFocused
        return placeholderNormal
    }

    color: Material.foreground

    leftPadding: 10
    rightPadding: 10

    onTextChanged: {
        if (text.length > 0)
            popup.open()
        else
            popup.close()
    }

    onActiveFocusChanged: {
        if (!activeFocus && text.length === 0)
            popup.close()
    }

    background: Rectangle {
        radius: 6
        color: Qt.rgba(1,1,1,0.05)

        border.width: 1
        border.color: Material.accent
        opacity: searchBox.activeFocus ? 1 : 0.5

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    property list<var> menuItems: [
        { keywords: ["trang chủ", "home", "trangchu"], page: "../pages/home.qml", icon: "../../images/svg_images/sidebar_images/home.svg" },
        { keywords: ["Ghi chú", "ghichu", "notes", "time"], page: "../pages/note.qml", icon: "../../images/svg_images/sidebar_images/notes.svg" },
        { keywords: ["toán", "toán học", "toan", "toan hoc", "math", "mathematics"], page: "../pages/math.qml", icon: "../../images/svg_images/sidebar_images/math.svg" },
        { keywords: ["tiếng anh", "tieng anh", "english", "anh văn", "anhvan"], page: "../pages/english.qml", icon: "../../images/svg_images/sidebar_images/english.svg", props: {controller: englishController} }
    ]

    function matchItems(query) {
        var q = query.toLowerCase().trim()
        if (q === "") return []
        var results = []
        for (var i = 0; i < menuItems.length; i++) {
            var item = menuItems[i]
            for (var k = 0; k < item.keywords.length; k++) {
                if (item.keywords[k].indexOf(q) !== -1) {
                    results.push(item)
                    break
                }
            }
        }
        return results
    }

    function navigateTo(item) {
        popup.close()
        searchBox.text = ""
        searchBox.focus = false
        if (stackView) {
            if (item.props)
                stackView.push(item.page, item.props)
            else
                stackView.replace(item.page)
        }
    }

    Popup {
        id: popup
        x: 0
        y: parent.height + 6
        width: parent.width
        padding: 0

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 8
            color: Material.background
            border.color: Material.accent
        }

        contentItem: ColumnLayout {
            spacing: 0

            Repeater {
                model: matchItems(searchBox.text)

                delegate: ItemDelegate {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 0
                    bottomPadding: 0

                    contentItem: RowLayout {
                        spacing: 10

                        Item {
                            implicitWidth: 18
                            implicitHeight: 18
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: iconImg
                                anchors.fill: parent
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                                visible: false
                                sourceSize.width: 36
                                sourceSize.height: 36
                            }

                            ColorOverlay {
                                anchors.fill: iconImg
                                source: iconImg
                                color: Material.accent
                            }
                        }

                        Label {
                            text: modelData.keywords[0]
                            font.pixelSize: 13
                            font.capitalization: Font.Capitalize
                            color: Material.foreground
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Label {
                            text: "⏎"
                            font.pixelSize: 11
                            color: Material.accent
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    onClicked: navigateTo(modelData)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: matchItems(searchBox.text).length === 0 ? 40 : 0
                visible: Layout.preferredHeight > 0

                Label {
                    anchors.centerIn: parent
                    text: "No results found"
                    font.pixelSize: 12
                    color: "#9E9E9E"
                }
            }
        }
    }
}
