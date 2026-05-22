import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtMultimedia

Page {
    id: root

    property var controller: notesController
    property string reminderDate: ""
    property string editingId: ""   // string UUID, "" = không edit

    Material.theme:   Material.Light
    Material.accent:  "#1565C0"
    Material.primary: "#0D47A1"

    background: Rectangle { color: "#F0F2F5" }

    property string viewMode: "list"  // "list" or "card"

    // ── Add note bar ────────────────────────────────────
    Rectangle {
        id: inputBar
        anchors { top: parent.top
left: parent.left
right: parent.right }
        height: 76
        color: "#FFFFFF"
        z: 10

        RowLayout {
            anchors { fill: parent
leftMargin: 12
rightMargin: 16
topMargin: 12
bottomMargin: 12 }
            spacing: 8

            // View toggle
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: viewToggleHover.containsMouse ? "#F0F2F5" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: root.viewMode === "list" ? "⊞" : "☰"
                    font.pixelSize: 16
                    color: "#666"
                }
                HoverHandler { id: viewToggleHover }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.viewMode = (root.viewMode === "list") ? "card" : "list"
                }
            }

            // Reminder chip
            Rectangle {
                visible: root.reminderDate !== ""
                height: 28
                width: visible ? (chipLabel.implicitWidth + 36) : 0
                radius: 14
color: "#E3F2FD"
                border { width: 1
color: "#90CAF9" }
                Behavior on width { NumberAnimation { duration: 150
easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors { fill: parent
leftMargin: 10
rightMargin: 8 }
                    spacing: 4
                    Text { text: "🔔"
font.pixelSize: 11 }
                    Label {
                        id: chipLabel
                        text: {
                            if (!root.reminderDate) return ""
                            var d = new Date(root.reminderDate)
                            return d.toLocaleString(Qt.locale(), "hh:mm dd/MM/yyyy")
                        }
                        font { pixelSize: 11
weight: Font.Medium }
                        color: "#1565C0"
                    }
                    Text {
                        text: "×"
font.pixelSize: 13
color: "#1565C0"
                        MouseArea {
                            anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                            onClicked: root.reminderDate = ""
                        }
                    }
                }
            }

            TextField {
                id: noteInput
                Layout.fillWidth: true
                placeholderText: root.editingId !== "" ? "Chỉnh sửa ghi chú..." : "Ghi chú mới..."
                placeholderTextColor: {
                    if (noteInput.text.length > 0)
                        return Qt.rgba(0,0,0,0)
                    if (noteInput.activeFocus)
                        return Qt.rgba(0,0,0,0)
                    return Qt.rgba(0,0,0,0.5)
                }
                font.pixelSize: 14
color: "#1A1A1A"
                background: Rectangle {
                    radius: 10
                    color: noteInput.activeFocus ? "#FFFFFF" : "#F5F7FA"
                    border {
                        width: noteInput.activeFocus ? 2 : 1
                        color: root.editingId !== ""
                            ? (noteInput.activeFocus ? "#E65100" : "#FFCC80")
                            : (noteInput.activeFocus ? "#1565C0" : "#DDE1E7")
                    }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                leftPadding: 14
rightPadding: 14
                onAccepted: commitNote()
            }

            // Cancel edit
            Rectangle {
                visible: root.editingId !== ""
                width: visible ? 28 : 0
height: 28
radius: 8
                color: cancelEditHover.containsMouse ? "#FFF3E0" : "transparent"
                border { width: 1
color: "#FFCC80" }
                Behavior on color { ColorAnimation { duration: 120 } }
                Text { anchors.centerIn: parent
text: "✕"
font.pixelSize: 13
color: "#E65100" }
                HoverHandler { id: cancelEditHover }
                MouseArea {
                    anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                    onClicked: cancelEdit()
                }
            }

            // Remind button
            Rectangle {
                width: 76
height: 36
radius: 10
                color: root.reminderDate !== "" ? "#E3F2FD"
                     : remindHover.containsMouse ? "#F0F2F5" : "transparent"
                border { width: 1
color: root.reminderDate !== "" ? "#90CAF9" : "#DDE1E7" }
                Behavior on color { ColorAnimation { duration: 120 } }
                RowLayout {
                    anchors.centerIn: parent
spacing: 4
                    Text { text: "🔔"
font.pixelSize: 13 }
                    Label {
                        text: "Hẹn giờ"
                        font { pixelSize: 12
weight: root.reminderDate !== "" ? Font.Medium : Font.Normal }
                        color: root.reminderDate !== "" ? "#1565C0" : "#666"
                    }
                }
                HoverHandler { id: remindHover }
                MouseArea {
                    anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                    onClicked: timePicker.open()
                }
            }

            // Confirm button
            Rectangle {
                id: addBtn
                width: 36
height: 36
radius: 10
                color: noteInput.text.trim() !== ""
                    ? (root.editingId !== "" ? "#E65100" : "#1565C0")
                    : "#C5CAD3"
                Behavior on color { ColorAnimation { duration: 150 } }
                scale: 1.0
                Behavior on scale { NumberAnimation { duration: 100
easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: root.editingId !== "" ? "✓" : "+"
                    font { pixelSize: root.editingId !== "" ? 17 : 22
weight: Font.Light }
                    color: "white"
                    Behavior on font.pixelSize { NumberAnimation { duration: 100 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: noteInput.text.trim() !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: noteInput.text.trim() !== ""
                    onPressed:  addBtn.scale = 0.90
                    onReleased: addBtn.scale = 1.0
                    onClicked:  commitNote()
                }
            }
        }
    }

    // ── Notes list view ─────────────────────────────────
    ListView {
        id: listView
        anchors { top: inputBar.bottom
bottom: parent.bottom
left: parent.left
right: parent.right }
        topMargin: 12
bottomMargin: 12
spacing: 8
        clip: true
        visible: root.viewMode === "list"
        model: controller ? controller.notes : []

        delegate: Item {
            id: delegateItem
            width: listView.width
            height: noteCard.height

            property bool isEditing: root.editingId !== "" && root.editingId === modelData.id

            Rectangle {
                id: noteCard
                anchors { left: parent.left
right: parent.right
margins: 14 }
                height: cardRow.implicitHeight + 20
                radius: 12
                color: delegateItem.isEditing ? "#FFF8F5"
                     : modelData.completed    ? "#F1F8F2"
                     : "#FFFFFF"
                border {
                    width: delegateItem.isEditing ? 2 : 1
                    color: delegateItem.isEditing ? "#E65100"
                         : modelData.completed    ? "#B9DFC0"
                         : "#E8EBF0"
                }
                Behavior on color        { ColorAnimation { duration: 180 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }

                RowLayout {
                    id: cardRow
                    anchors { left: parent.left
right: parent.right
margins: 12
verticalCenter: parent.verticalCenter }
                    spacing: 10

                    // Checkbox
                    Rectangle {
                        width: 22
height: 22
radius: 6
                        color: modelData.completed ? "#2E7D32" : "transparent"
                        border { width: 2
color: modelData.completed ? "#2E7D32" : "#BBBBBB" }
                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        opacity: delegateItem.isEditing ? 0.3 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
text: "✓"
                            font { pixelSize: 13
weight: Font.Bold }
color: "white"
                            opacity: modelData.completed ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: delegateItem.isEditing ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled: !delegateItem.isEditing
                            onClicked: { if (controller) controller.toggleNote(modelData.id) }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
spacing: 3

                        Label {
                            Layout.fillWidth: true
                            visible: !delegateItem.isEditing
                            text: modelData.text
                            font { pixelSize: 13
strikeout: modelData.completed }
                            color: modelData.completed ? "#AAAAAA" : "#1A1A1A"
                            wrapMode: Text.WordWrap
maximumLineCount: 2
elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Reminder chip on card
                        Rectangle {
                            visible: !!modelData.reminder_at && !delegateItem.isEditing
                            height: 20
                            width: reminderChipRow.implicitWidth + 16
                            radius: 10
color: "#E8F0FE"

                            RowLayout {
                                id: reminderChipRow
                                anchors.centerIn: parent
spacing: 4
                                Text { text: "🔔"
font.pixelSize: 10 }
                                Label {
                                    text: {
                                        var r = modelData.reminder_at
                                        if (!r) return ""
                                        return new Date(r).toLocaleString(Qt.locale(), "hh:mm dd/MM/yyyy")
                                    }
                                    font.pixelSize: 10
color: "#1A73E8"
                                }
                            }
                        }
                    }

                    // Buttons: edit + delete (chưa hoàn thành)
                    RowLayout {
                        spacing: 4
                        visible: !modelData.completed

                        Rectangle {
                            width: 28
height: 28
radius: 8
                            color: editBtnHover.containsMouse
                                ? (delegateItem.isEditing ? "#E8F5E9" : "#EEF2FF")
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: delegateItem.isEditing ? "✓" : "✎"
                                font.pixelSize: delegateItem.isEditing ? 14 : 13
                                color: delegateItem.isEditing
                                    ? (editBtnHover.containsMouse ? "#2E7D32" : "#4CAF50")
                                    : (editBtnHover.containsMouse ? "#3949AB" : "#9E9E9E")
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            HoverHandler { id: editBtnHover }
                            MouseArea {
                                anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (delegateItem.isEditing) commitInlineEdit(modelData.id)
                                    else startEdit(modelData.id, modelData.text, modelData.reminder_at || "")
                                }
                            }
                        }

                        Rectangle {
                            width: 28
height: 28
radius: 8
                            color: delHover.containsMouse ? "#FFEBEE" : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
text: "✕"
font.pixelSize: 12
                                color: delHover.containsMouse ? "#D32F2F" : "#BDBDBD"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            HoverHandler { id: delHover }
                            MouseArea {
                                anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (delegateItem.isEditing) cancelEdit()
                                    else if (controller) controller.deleteNote(modelData.id)
                                }
                            }
                        }
                    }

                    // Completed: chỉ delete
                    Rectangle {
                        visible: modelData.completed
                        width: 28
height: 28
radius: 8
                        color: delCompHover.containsMouse ? "#FFEBEE" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
text: "✕"
font.pixelSize: 12
                            color: delCompHover.containsMouse ? "#D32F2F" : "#BDBDBD"
                        }
                        HoverHandler { id: delCompHover }
                        MouseArea {
                            anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                            onClicked: { if (controller) controller.deleteNote(modelData.id) }
                        }
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
width: 160
height: 80
            visible: listView.count === 0
            ColumnLayout {
                anchors.centerIn: parent
spacing: 8
                Text { Layout.alignment: Qt.AlignHCenter
text: "📝"
font.pixelSize: 32 }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Chưa có ghi chú nào"
                    font.pixelSize: 13
color: "#BDBDBD"
                }
            }
        }

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    }

    // ── Notes card view ─────────────────────────────────
    Item {
        id: cardViewParent
        anchors { top: inputBar.bottom
bottom: parent.bottom
left: parent.left
right: parent.right }
        visible: root.viewMode === "card"
        clip: true

        property var notesModel: controller ? controller.notes : []

        ListView {
            id: cardListView
            anchors.fill: parent
            anchors.bottomMargin: 60
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            spacing: -40
            clip: true

            model: cardViewParent.notesModel

            delegate: Item {
                width: cardListView.width
                height: cardListView.height

                Rectangle {
                    anchors { fill: parent; margins: 20 }
                    radius: 20
                    color: modelData.completed ? "#F1F8F2" : "#FFFFFF"

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 8
                        radius: 20
                        color: modelData.completed ? "#4CAF50" : Material.accent
                    }

                    ColumnLayout {
                        anchors { fill: parent; margins: 24 }
                        spacing: 8

                        Label {
                            text: modelData.text
                            font { pixelSize: 16; weight: Font.Medium }
                            color: modelData.completed ? "#9E9E9E" : "#1A1A1A"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            visible: !!modelData.reminder_at
                            height: 22
                            width: remChip.implicitWidth + 16
                            radius: 11
                            color: "#E8F0FE"
                            Label {
                                id: remChip
                                anchors.centerIn: parent
                                text: "🔔 " + new Date(modelData.reminder_at).toLocaleString(Qt.locale(), "hh:mm dd/MM")
                                font.pixelSize: 11
                                color: "#1A73E8"
                            }
                        }

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 10
                                color: cardDoneHover.containsMouse ? "#E8F5E9" : "#F5F5F5"
                                border { width: 1; color: "#E0E0E0" }
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.completed ? "✓ Done" : "✓ Mark done"
                                    font.pixelSize: 11
                                    color: modelData.completed ? "#2E7D32" : "#757575"
                                }
                                HoverHandler { id: cardDoneHover }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (controller) controller.toggleNote(modelData.id) }
                                }
                            }

                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: cardDelHover.containsMouse ? "#FFEBEE" : "#F5F5F5"
                                border { width: 1; color: "#E0E0E0" }
                                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 13; color: "#BDBDBD" }
                                HoverHandler { id: cardDelHover }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (controller) controller.deleteNote(modelData.id) }
                                }
                            }
                        }
                    }
                }
            }

            ScrollBar.horizontal: ScrollBar { active: true }
        }

        // Counter
        Label {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
            text: (cardListView.currentIndex + 1) + " / " + cardListView.count
            font.pixelSize: 11
            color: "#BDBDBD"
        }
    }

    // ── Time + Date picker popup ────────────────────────
    Popup {
        id: timePicker
        x: Math.round((parent.width  - width)  / 2)
        y: Math.round((parent.height - height) / 2)
        width: 300
        height: popupHeight
        modal: true
focus: true

        // Tính height động: header + preview + tumbler + divider + nav + dayHeader + dayRows + divider + buttons
        property int popupHeight: {
            var firstDay = new Date(pickerYear, pickerMonth - 1, 1).getDay()
            var totalCells = firstDay + daysInMonth
            var rows = Math.ceil(totalCells / 7)
            // header(46) + sp(10) + preview(38) + sp(10) + tumbler(90) + sp(10) + div(1) + sp(12)
            // + nav(28) + sp(8) + dayHeader(20) + rows*(28+4) - 4 + sp(10) + div(1) + topMargin(14) + buttons(40) + bottomMargin(20)
            return 46 + 10 + 38 + 10 + 90 + 10 + 1 + 12 + 28 + 8 + 20 + rows * 32 - 4 + 10 + 1 + 14 + 40 + 20
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Overlay.modal: Rectangle { color: "#50000000" }

        enter: Transition {
            NumberAnimation { property: "opacity"
from: 0
to: 1
duration: 180
easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"
  from: 0.90
to: 1
duration: 200
easing.type: Easing.OutBack }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"
from: 1
to: 0
duration: 130 }
            NumberAnimation { property: "scale"
  from: 1
to: 0.90
duration: 130 }
        }

        // Trạng thái nội bộ của picker
        property int pickerDay:   new Date().getDate()
        property int pickerMonth: new Date().getMonth() + 1
        property int pickerYear:  new Date().getFullYear()

        // Số ngày trong tháng đang chọn
        property int daysInMonth: {
            return new Date(pickerYear, pickerMonth, 0).getDate()
        }

        onOpened: {
            if (root.reminderDate !== "") {
                // Load ngày/giờ đang có sẵn (khi edit note đã có reminder)
                var existing = new Date(root.reminderDate)
                pickerDay   = existing.getDate()
                pickerMonth = existing.getMonth() + 1
                pickerYear  = existing.getFullYear()
                hourTumbler.currentIndex = existing.getHours()
                minTumbler.currentIndex  = existing.getMinutes()
            } else {
                var now = new Date()
                pickerDay   = now.getDate()
                pickerMonth = now.getMonth() + 1
                pickerYear  = now.getFullYear()
                hourTumbler.currentIndex = now.getHours()
                minTumbler.currentIndex  = now.getMinutes()
            }
        }

        background: Rectangle {
            radius: 16
color: "#FFFFFF"
        }

        ColumnLayout {
            id: contentCol
            anchors { fill: parent }
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
height: 46
                color: "#F8F9FF"
radius: 16
                Rectangle {
                    anchors { bottom: parent.bottom
left: parent.left
right: parent.right }
                    height: 16
color: "#F8F9FF"
                }
                RowLayout {
                    anchors { fill: parent
leftMargin: 20
rightMargin: 16 }
                    Text { text: "📅"
font.pixelSize: 18 }
                    Label {
                        text: "Đặt nhắc nhở"
Layout.fillWidth: true
leftPadding: 8
                        font { pixelSize: 15
weight: Font.Medium }
color: "#1A1A1A"
                    }
                    Rectangle {
                        width: 28
height: 28
radius: 8
                        color: closePickerHover.containsMouse ? "#EEEEEE" : "transparent"
                        Text { anchors.centerIn: parent
text: "✕"
font.pixelSize: 12
color: "#888" }
                        HoverHandler { id: closePickerHover }
                        MouseArea {
                            anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                            onClicked: timePicker.close()
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true
height: 10 }

            // Preview box
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 210
height: 38
radius: 10
                color: "#EEF2FF"
border { width: 1
color: "#C5CAE9" }

                Label {
                    anchors.centerIn: parent
                    text: {
                        var h = String(hourTumbler.currentIndex).padStart(2, "0")
                        var m = String(minTumbler.currentIndex).padStart(2, "0")
                        var d = String(timePicker.pickerDay).padStart(2, "0")
                        var mo = String(timePicker.pickerMonth).padStart(2, "0")
                        var y = String(timePicker.pickerYear)
                        return h + ":" + m + "  " + d + "/" + mo + "/" + y
                    }
                    font { pixelSize: 18
weight: Font.Medium }
                    color: "#283593"
                }
            }

            Item { Layout.fillWidth: true
height: 10 }

            // ── Time row (Tumbler) ──
            Item {
                Layout.fillWidth: true
height: 90

                RowLayout {
                    anchors.centerIn: parent
spacing: 8

                    Tumbler {
                        id: hourTumbler
                        model: 24
visibleItemCount: 3
                        implicitWidth: 64
implicitHeight: 90
                        Component.onCompleted: currentIndex = new Date().getHours()
                        delegate: Item {
                            height: hourTumbler.height / hourTumbler.visibleItemCount
                            width: hourTumbler.width
                            Label {
                                anchors.centerIn: parent
                                text: String(modelData).padStart(2, "0")
                                font {
                                    pixelSize: Math.abs(Tumbler.displacement) < 0.5 ? 20 : 14
                                    weight: Math.abs(Tumbler.displacement) < 0.5 ? Font.Medium : Font.Normal
                                }
                                color: {
                                    var d = Math.abs(Tumbler.displacement)
                                    return d < 0.5 ? "#1565C0" : d < 1.5 ? "#888" : "#D0D0D0"
                                }
                            }
                        }
                        background: Rectangle { radius: 10
color: "#F5F7FA"
border { width: 1
color: "#E8EBF0" } }
                    }

                    Label { text: ":"
font { pixelSize: 22
weight: Font.Bold }
color: "#888"
bottomPadding: 4 }

                    Tumbler {
                        id: minTumbler
                        model: 60
visibleItemCount: 3
                        implicitWidth: 64
implicitHeight: 90
                        Component.onCompleted: currentIndex = new Date().getMinutes()
                        delegate: Item {
                            height: minTumbler.height / minTumbler.visibleItemCount
                            width: minTumbler.width
                            Label {
                                anchors.centerIn: parent
                                text: String(modelData).padStart(2, "0")
                                font {
                                    pixelSize: Math.abs(Tumbler.displacement) < 0.5 ? 20 : 14
                                    weight: Math.abs(Tumbler.displacement) < 0.5 ? Font.Medium : Font.Normal
                                }
                                color: {
                                    var d = Math.abs(Tumbler.displacement)
                                    return d < 0.5 ? "#1565C0" : d < 1.5 ? "#888" : "#D0D0D0"
                                }
                            }
                        }
                        background: Rectangle { radius: 10
color: "#F5F7FA"
border { width: 1
color: "#E8EBF0" } }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true
height: 1
color: "#F0F0F0"
Layout.topMargin: 10 }

            // ── Date navigator ──
            Item { Layout.fillWidth: true
height: 12 }

            // Month / Year navigator
            RowLayout {
                Layout.fillWidth: true
Layout.leftMargin: 16
Layout.rightMargin: 16
                spacing: 8

                Rectangle {
                    width: 28
height: 28
radius: 8
                    color: prevMHover.containsMouse ? "#F0F2F5" : "transparent"
                    Text { anchors.centerIn: parent
text: "‹"
font.pixelSize: 18
color: "#555" }
                    HoverHandler { id: prevMHover }
                    MouseArea {
                        anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (timePicker.pickerMonth === 1) {
                                timePicker.pickerMonth = 12
                                timePicker.pickerYear -= 1
                            } else {
                                timePicker.pickerMonth -= 1
                            }
                            timePicker.pickerDay = Math.min(timePicker.pickerDay, timePicker.daysInMonth)
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var months = ["Tháng 1","Tháng 2","Tháng 3","Tháng 4","Tháng 5","Tháng 6",
                                      "Tháng 7","Tháng 8","Tháng 9","Tháng 10","Tháng 11","Tháng 12"]
                        return months[timePicker.pickerMonth - 1] + " " + timePicker.pickerYear
                    }
                    font { pixelSize: 13
weight: Font.Medium }
color: "#1A1A1A"
                }

                Rectangle {
                    width: 28
height: 28
radius: 8
                    color: nextMHover.containsMouse ? "#F0F2F5" : "transparent"
                    Text { anchors.centerIn: parent
text: "›"
font.pixelSize: 18
color: "#555" }
                    HoverHandler { id: nextMHover }
                    MouseArea {
                        anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (timePicker.pickerMonth === 12) {
                                timePicker.pickerMonth = 1
                                timePicker.pickerYear += 1
                            } else {
                                timePicker.pickerMonth += 1
                            }
                            timePicker.pickerDay = Math.min(timePicker.pickerDay, timePicker.daysInMonth)
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true
height: 8 }

            // Day grid (7 cột)
            // cellW = floor((300 - 2*padding - 6*spacing) / 7) = floor((300-24-24)/7) = 36
            // gridW = 7*36 + 6*4 = 252 + 24 = 276  →  padding = (300-276)/2 = 12 mỗi bên
            Item {
                Layout.fillWidth: true
                implicitHeight: gridInner.implicitHeight

                Grid {
                    id: gridInner
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
spacing: 4

                Repeater {
                    model: ["CN","T2","T3","T4","T5","T6","T7"]
                    Label {
                        width: 36
height: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 10
color: "#AAAAAA"
                    }
                }

                // Offset: thứ mấy là ngày 1?
                Repeater {
                    model: {
                        var firstDay = new Date(timePicker.pickerYear, timePicker.pickerMonth - 1, 1).getDay()
                        return firstDay
                    }
                    Item { width: 36
height: 28 }
                }

                // Các ngày
                Repeater {
                    model: timePicker.daysInMonth
                    Rectangle {
                        width: 36
height: 28
radius: 7
                        property bool isSelected: (index + 1) === timePicker.pickerDay
                        property bool isToday: {
                            var now = new Date()
                            return (index + 1) === now.getDate()
                                && timePicker.pickerMonth === (now.getMonth() + 1)
                                && timePicker.pickerYear  === now.getFullYear()
                        }

                        color: isSelected ? "#1565C0" : dayHover.containsMouse ? "#EEF2FF" : "transparent"
                        border { width: isToday && !isSelected ? 1 : 0
color: "#90CAF9" }
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Label {
                            anchors.centerIn: parent
                            text: index + 1
                            font { pixelSize: 12
weight: isSelected ? Font.Medium : Font.Normal }
                            color: isSelected ? "white" : isToday ? "#1565C0" : "#333"
                        }

                        HoverHandler { id: dayHover }
                        MouseArea {
                            anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                            onClicked: timePicker.pickerDay = index + 1
                        }
                    }
                }
                } // end Grid
            } // end Item wrapper

            Item { Layout.fillWidth: true
height: 10 }
            Rectangle { Layout.fillWidth: true
height: 1
color: "#F0F0F0" }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
Layout.rightMargin: 16
                Layout.topMargin: 14
Layout.bottomMargin: 20
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
height: 40
radius: 10
                    color: cancelPickerHover.containsMouse ? "#F5F7FA" : "transparent"
                    border { width: 1
color: "#DDE1E7" }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Label { anchors.centerIn: parent
text: "Huỷ"
font { pixelSize: 13
weight: Font.Medium }
color: "#555" }
                    HoverHandler { id: cancelPickerHover }
                    MouseArea {
                        anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                        onClicked: timePicker.close()
                    }
                }

                Rectangle {
                    id: setBtn
                    Layout.fillWidth: true
height: 40
radius: 10
                    color: setPickerHover.containsMouse ? "#1976D2" : "#1565C0"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    scale: 1.0
                    Behavior on scale { NumberAnimation { duration: 100
easing.type: Easing.OutBack } }

                    Label { anchors.centerIn: parent
text: "Đặt giờ"
font { pixelSize: 13
weight: Font.Medium }
color: "white" }
                    HoverHandler { id: setPickerHover }
                    MouseArea {
                        anchors.fill: parent
cursorShape: Qt.PointingHandCursor
                        onPressed:  setBtn.scale = 0.95
                        onReleased: setBtn.scale = 1.0
                        onClicked: {
                            var dt = new Date(
                                timePicker.pickerYear,
                                timePicker.pickerMonth - 1,
                                timePicker.pickerDay,
                                hourTumbler.currentIndex,
                                minTumbler.currentIndex,
                                0
                            )
                            root.reminderDate = dt.toISOString()
                            timePicker.close()
                        }
                    }
                }
            } // end buttons RowLayout
        } // end ColumnLayout
    } // end Popup

    // ── Functions ───────────────────────────────────────
    function commitNote() {
        var text = noteInput.text.trim()
        if (!text || !controller) return
        if (root.editingId !== "") {
            controller.updateNote(root.editingId, text, root.reminderDate)
            cancelEdit()
        } else {
            controller.addNote(text, root.reminderDate)
            noteInput.text = ""
            root.reminderDate = ""
        }
    }

    function startEdit(id, currentText, reminderAt) {
        root.editingId = id
        root.reminderDate = reminderAt || ""
        noteInput.text = currentText
        noteInput.forceActiveFocus()
        noteInput.selectAll()
    }

    function cancelEdit() {
        root.editingId = ""
        noteInput.text = ""
        root.reminderDate = ""
    }

    function commitInlineEdit(id) {
        var text = noteInput.text.trim()
        if (!text || !controller) { cancelEdit()
return }
        controller.updateNote(id, text, root.reminderDate)
        cancelEdit()
    }
}
