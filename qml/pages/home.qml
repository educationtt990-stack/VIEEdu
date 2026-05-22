import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Page {
    Rectangle {
        anchors.fill: parent
        color: Material.backgroundColor
    }

    Rectangle {
        id: card
        width: parent.width * 0.8
        anchors.centerIn: parent

        // 👇 QUAN TRỌNG: để card có chiều cao
        implicitHeight: content.implicitHeight + 40
        color: Material.background

        Column {
            id: content
            width: parent.width - 40
            height: parent.height - 40
            anchors.horizontalCenter: parent.horizontalCenter
            // anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 12

            Label {
                text: "VIEEdu"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                color: Material.accent
                font{
                    pointSize: 18
                    weight:Font.Black
                }
            }

            Label {
                text: "Ứng dụng học tập thông minh, tích hợp nhiều công cụ hỗ trợ"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                color: Material.foreground
                font{
                    pointSize: 13
                }
            }

            // Label {
            //     text: "📐 Toán học - Tra cứu công thức từ cơ bản đến nâng cao"
            //     color: Material.accent
            //     font.pointSize: 12
            //     width: parent.width
            //     wrapMode: Text.WordWrap
            // }
            //
            // Label {
            //     text: "📖 Ngữ Văn - Tra cứu mẫu tài liệu có sẵn, tích hợp tính năng sửa bài văn"
            //     color: Material.accent
            //     font.pointSize: 12
            //     width: parent.width
            //     wrapMode: Text.WordWrap
            // }
            //
            // Label {
            //     text: "📚 Tiếng Anh - Luyện tập từ vựng, ngữ pháp"
            //     color: Material.accent
            //     font.pointSize: 12
            //     width: parent.width
            //     wrapMode: Text.WordWrap
            // }
        }
    }
}