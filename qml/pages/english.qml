import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Page {
    id: root
    property var controller
    property string selectedContent: ""

    // ── internal state ──────────────────────────────────────────────
    property int    selectedGrade:   0
    property string selectedSection: ""
    property string selectedTopic:   ""
    property int    layoutIndex:     0       // 0=home, 1=topic list, 2=detail

    Material.theme:   Material.Light
    Material.primary: "#1565C0"
    Material.accent:  "#1565C0"

    background: Rectangle { color: "#F5F5F5" }

    // ── lấy dữ liệu từ controller (đã được bind qua context property) ──
    readonly property var gradeData: controller ? controller.gradeData : ({})
    readonly property var sectionsList: controller ? controller.sections : ["Theory", "Exercises", "AI Practice"]
    readonly property var sectionIcons: controller ? controller.sectionIcons : ({})
    readonly property var sectionColors: controller ? controller.sectionColors : ({})
    readonly property var sectionBg: controller ? controller.sectionBg : ({})

    // ── helper: lấy danh sách topics từ gradeData ─────────────────────
    function getTopicsForGrade(grade) {
        if (controller && controller.getTopicsForGrade)
            return controller.getTopicsForGrade(grade)
        var topics = gradeData[grade] || []
        if (typeof topics === 'object' && !Array.isArray(topics)) {
            // Nếu gradeData trả về QVariantMap cần xử lý
            var result = []
            for (var key in topics) {
                if (topics.hasOwnProperty(key))
                    result.push(topics[key])
            }
            return result
        }
        return topics
    }

    // ── kiểm tra dữ liệu đã load chưa ─────────────────────────────────
    property bool dataReady: Object.keys(gradeData).length > 0

    // ── listening overlay ─────────────────────────────────────────
    Item {
        id: listeningOverlay
        anchors.fill: parent
        z: 9999
        visible: false
        enabled: false

        opacity: 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        function show() { visible = true; enabled = true; opacity = 1.0 }
        function hide() { opacity = 0.0 }

        onOpacityChanged: {
            if (opacity === 0.0) { visible = false; enabled = false }
        }

        Connections {
            target: controller
            function onListeningVisibleChanged() {
                if (controller.listeningVisible) listeningOverlay.show()
                else listeningOverlay.hide()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#80000000"

            MouseArea { anchors.fill: parent }
        }

        Rectangle {
            id: listeningCard
            anchors.centerIn: parent
            width: 280; height: 170
            radius: 16
            color: "#1565C0"

            scale: listeningOverlay.opacity > 0.5 ? 1.0 : 0.85
            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "🔊"
                    font.pixelSize: 36
                    color: "white"
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Hãy lắng nghe..."
                    font { pixelSize: 16; weight: Font.Medium }
                    color: "white"
                }

                Item { Layout.preferredHeight: 4 }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Button {
                        implicitWidth: 90; implicitHeight: 34
                        text: "🔁 Repeat"
                        font { pixelSize: 12; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text; color: "#1565C0"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 17
                            color: parent.pressed ? "#E3F2FD" : "white"
                        }
                        onClicked: {
                            if (controller)
                                controller.repeatSpeak()
                        }
                    }

                    Button {
                        implicitWidth: 90; implicitHeight: 34
                        text: "OK"
                        font { pixelSize: 12; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text; color: "#1565C0"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 17
                            color: parent.pressed ? "#E3F2FD" : "white"
                        }
                        onClicked: {
                            if (controller)
                                controller.dismissSpeak()
                        }
                    }
                }
            }
        }
    }

    // ── helpers ─────────────────────────────────────────────────────
    function openLayout2(grade, section) {
        selectedGrade   = grade
        selectedSection = section
        selectedTopic   = ""
        layoutIndex     = 1
        bcGradePopup.close()
        bcSectionPopup.close()
    }

    function openDetail(topic) {
        selectedTopic = topic
        layoutIndex   = 2
    }

    function goBack() {
        if (layoutIndex === 2) {
            layoutIndex = 1
            return
        }
        layoutIndex       = 0
        selectedGrade     = 0
        selectedSection   = ""
        selectedTopic     = ""
        bcGradePopup.close()
        bcSectionPopup.close()
    }

    function navTitle() {
        if (layoutIndex === 2 && selectedTopic !== "")
            return selectedTopic
        if (selectedGrade === 0) return "English Learning"
        return "Grade " + selectedGrade
    }

    function contentTitle() {
        if (selectedGrade === 0) return ""
        if (selectedTopic !== "" && selectedSection !== "")
            return selectedTopic + " · " + selectedSection
        if (selectedSection === "")
            return "Grade " + selectedGrade + " — All sections"
        return "Grade " + selectedGrade + " · " + selectedSection
    }

    function topicRows() {
        if (selectedGrade === 0) return []
        var topics = getTopicsForGrade(selectedGrade)
        var rows = []
        if (selectedSection === "") {
            for (var i = 0; i < topics.length; i++)
                for (var j = 0; j < sectionsList.length; j++)
                    rows.push({ num: i+1, topic: topics[i], sec: sectionsList[j] })
        } else {
            for (var k = 0; k < topics.length; k++)
                rows.push({ num: k+1, topic: topics[k], sec: selectedSection })
        }
        return rows
    }

    // ── loading indicator while data loads ───────────────────────────
    Loader {
        anchors.fill: parent
        active: !dataReady
        sourceComponent: loadingIndicator
        z: 100
    }

    Component {
        id: loadingIndicator
        Rectangle {
            color: "#F5F5F5"
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                BusyIndicator {
                    running: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "Loading curriculum data..."
                    font.pixelSize: 14
                    color: "#757575"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // ── root stack: three levels ────────────────────────────────────
    StackLayout {
        anchors.fill: parent
        currentIndex: layoutIndex

        // ════════════════════════════════════════════════════════════
        //  LAYOUT 0 — Home
        // ════════════════════════════════════════════════════════════
        Item {
            Rectangle {
                id: l0AppBar
                width: parent.width
                height: 64
                color: Material.primary
                z: 2



                Column {
                    anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Label {
                        text: "English Learning"
                        font { pixelSize: 20; weight: Font.Medium }
                        color: "white"
                    }
                    Label {
                        text: "Secondary school curriculum · grades 10 – 12"
                        font.pixelSize: 12
                        color: "#CCE3F2FD"
                    }
                }
            }

            ScrollView {
                anchors { top: l0AppBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 0

                    Item { Layout.preferredHeight: 20 }

                    Label {
                        Layout.leftMargin: 16
                        text: "SELECT GRADE"
                        font { pixelSize: 11; weight: Font.Medium; letterSpacing: 0.8 }
                        color: "#757575"
                    }

                    Item { Layout.preferredHeight: 8 }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 10

                        Repeater {
                            model: {
                                var grades = []
                                for (var g in gradeData) {
                                    if (gradeData.hasOwnProperty(g))
                                        grades.push(parseInt(g))
                                }
                                grades.sort(function(a,b){return a-b})
                                return grades
                            }
                            delegate: GradeCard {
                                grade:          modelData
                                unitCount:      getTopicsForGrade(modelData).length
                                Layout.fillWidth: true
                                onClicked:      openLayout2(modelData, "")
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 24 }

                    Label {
                        Layout.leftMargin: 16
                        text: "BROWSE BY SECTION — opens in " + (Object.keys(gradeData).length > 0 ? "grade " + Object.keys(gradeData)[0] : "first grade")
                        font { pixelSize: 11; weight: Font.Medium; letterSpacing: 0.8 }
                        color: "#757575"
                    }

                    Item { Layout.preferredHeight: 8 }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 10

                        Repeater {
                            model: sectionsList
                            delegate: SectionChip {
                                label:          modelData
                                chipColor:      sectionColors[modelData] || "#3949AB"
                                chipBg:         sectionBg[modelData] || "#E8EAF6"
                                Layout.fillWidth: true
                                onClicked: {
                                    var firstGrade = 0
                                    for (var g in gradeData) {
                                        if (gradeData.hasOwnProperty(g)) {
                                            firstGrade = parseInt(g)
                                            break
                                        }
                                    }
                                    openLayout2(firstGrade, modelData)
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 24 }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        //  LAYOUT 1 — Topic list
        // ════════════════════════════════════════════════════════════
        Item {
            Rectangle {
                id: l1AppBar
                width: parent.width
                height: l1NavRow.height + breadcrumbRow.height
                color: Material.primary
                z: 2



                RowLayout {
                    id: l1NavRow
                    width: parent.width
                    height: 56
                    spacing: 0

                    RoundButton {
                        Layout.leftMargin: 4
                        flat: true
                        display: AbstractButton.IconOnly
                        ToolTip.visible: hovered; ToolTip.text: "Go back"

                        contentItem: Text {
                            text: "←"
                            font.pixelSize: 22
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? "#33FFFFFF"
                                 : parent.hovered  ? "#1AFFFFFF" : "transparent"
                        }
                        onClicked: goBack()
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        text: navTitle()
                        font { pixelSize: 18; weight: Font.Medium }
                        color: "white"
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: breadcrumbRow
                    anchors.top: l1NavRow.bottom
                    width: parent.width
                    height: 36
                    color: "#2D000000"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        BreadcrumbSegment {
                            id: bcGradeSegment
                            label: selectedGrade > 0 ? "Grade " + selectedGrade : "Grade"
                            onSegmentClicked: bcGradePopup.open()
                        }

                        Label {
                            text: "›"
                            color: "#80FFFFFF"
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        BreadcrumbSegment {
                            id: bcSectionSegment
                            label: selectedSection !== "" ? selectedSection : "All sections"
                            onSegmentClicked: bcSectionPopup.open()
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Popup {
                        id: bcGradePopup
                        x: bcGradeSegment.x
                        y: breadcrumbRow.height
                        width: 160
                        padding: 0
                        contentItem: Column {
                            Repeater {
                                model: {
                                    var grades = []
                                    for (var g in gradeData) {
                                        if (gradeData.hasOwnProperty(g))
                                            grades.push(parseInt(g))
                                    }
                                    grades.sort(function(a,b){return a-b})
                                    return grades
                                }
                                delegate: BcDropItem {
                                    itemText:  "Grade " + modelData
                                    isSelected: selectedGrade === modelData
                                    onItemClicked: {
                                        selectedGrade = modelData
                                        bcGradePopup.close()
                                    }
                                }
                            }
                        }
                        background: Rectangle {
                            color: "white"; radius: 8

                        }
                    }

                    Popup {
                        id: bcSectionPopup
                        x: bcSectionSegment.x
                        y: breadcrumbRow.height
                        width: 160
                        padding: 0
                        contentItem: Column {
                            BcDropItem {
                                itemText: "All sections"
                                isSelected: selectedSection === ""
                                onItemClicked: { selectedSection = ""; bcSectionPopup.close() }
                            }
                            Repeater {
                                model: sectionsList
                                delegate: BcDropItem {
                                    itemText:   modelData
                                    isSelected: selectedSection === modelData
                                    onItemClicked: { selectedSection = modelData; bcSectionPopup.close() }
                                }
                            }
                        }
                        background: Rectangle {
                            color: "white"; radius: 8

                        }
                    }
                }
            }

            ScrollView {
                anchors { top: l1AppBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 0

                    Item { Layout.preferredHeight: 16 }

                    Label {
                        Layout.leftMargin: 16
                        text: contentTitle()
                        font { pixelSize: 18; weight: Font.Medium }
                        color: "#212121"
                    }

                    Label {
                        Layout.leftMargin: 16; Layout.topMargin: 2
                        text: {
                            if (selectedGrade === 0) return ""
                            var topics = getTopicsForGrade(selectedGrade)
                            if (selectedSection === "")
                                return topics.length + " units · " + sectionsList.length + " sections each"
                            return topics.length + " units available"
                        }
                        font.pixelSize: 13
                        color: "#757575"
                    }

                    Item { Layout.preferredHeight: 12 }

                    Repeater {
                        id: topicRepeater
                        model: topicRows()

                        signal topicSelected(string topic, string sec)

                        onTopicSelected: function(topic, sec) {
                            root.selectedContent = topic + " · " + sec
                            root.selectedTopic   = topic
                            root.selectedSection = sec
                            root.layoutIndex     = 2
                            if (root.controller)
                                root.controller.openTopic(root.selectedGrade, topic, sec)
                        }

                        delegate: Rectangle {
                            required property var modelData
                            id: tcDelegate
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 6
                            implicitHeight: 60
                            radius: 8
                            color: tcMa.containsPress ? "#F5F5F5"
                                 : tcMa.containsMouse ? "#FAFAFA" : "white"
                            border { width: tcMa.containsMouse ? 1 : 0.5; color: tcMa.containsMouse ? Material.primary : "#E0E0E0" }

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                spacing: 12

                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: "#E3F2FD"
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.num
                                        font { pixelSize: 13; weight: Font.Bold }
                                        color: "#1565C0"
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: modelData.topic
                                        font { pixelSize: 14; weight: Font.Medium }
                                        color: "#212121"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    RowLayout {
                                        spacing: 4
                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: sectionColors[modelData.sec] || "#3949AB"
                                        }
                                        Label {
                                            text: modelData.sec
                                            font.pixelSize: 12
                                            color: sectionColors[modelData.sec] || "#3949AB"
                                        }
                                    }
                                }

                                Label {
                                    text: "›"
                                    font { pixelSize: 20 }
                                    color: "#BDBDBD"
                                }
                            }

                            MouseArea {
                                id: tcMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var data = tcDelegate.modelData
                                    if (typeof data !== "object" || data === null) return
                                    var topic = String(data.topic)
                                    var sec   = String(data.sec)
                                    if (!topic || !sec) return
                                    topicRepeater.topicSelected(topic, sec)
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 20 }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        //  LAYOUT 2 — Detail / Content
        // ════════════════════════════════════════════════════════════
        Item {
            Rectangle {
                id: l2AppBar
                width: parent.width
                height: 56
                color: Material.primary
                z: 2



                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    RoundButton {
                        Layout.leftMargin: 4
                        flat: true
                        display: AbstractButton.IconOnly
                        ToolTip.visible: hovered; ToolTip.text: "Go back"

                        contentItem: Text {
                            text: "←"
                            font.pixelSize: 22
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? "#33FFFFFF"
                                 : parent.hovered  ? "#1AFFFFFF" : "transparent"
                        }
                        onClicked: goBack()
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        text: navTitle()
                        font { pixelSize: 18; weight: Font.Medium }
                        color: "white"
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.rightMargin: 16
                        text: sectionIcons[selectedSection] || ""
                        font.pixelSize: 20
                        color: "white"
                    }
                }
            }

            ScrollView {
                id: detailScroll
                anchors { top: l2AppBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
                contentWidth: availableWidth
                clip: true

                Connections {
                    target: root
                    function onLayoutIndexChanged() {
                        if (root.layoutIndex === 2)
                            detailScroll.ScrollBar.vertical.position = 0
                    }
                }

                ColumnLayout {
                    id: detailContent
                    width: detailScroll.availableWidth
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: sectionBg[selectedSection] || "#F5F5F5"

                        Label {
                            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            text: (selectedSection || "") + " · " + (selectedTopic || "")
                            font { pixelSize: 13; weight: Font.Medium }
                            color: sectionColors[selectedSection] || "#757575"
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1
                            color: "#E0E0E0"
                        }
                    }

                    Item { Layout.preferredHeight: 8 }

                    Loader {
                        id: theoryLoader
                        Layout.fillWidth: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        active: selectedSection === "Theory"
                        sourceComponent: theoryView
                    }

                    Loader {
                        id: exercisesLoader
                        Layout.fillWidth: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        active: selectedSection === "Exercises"
                        sourceComponent: exercisesView
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        active: selectedSection === "AI Practice"
                        sourceComponent: aiPracticeView
                    }

                    Item { Layout.preferredHeight: 32 }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    //  COMPONENT: Theory View (giữ nguyên như cũ)
    // ═════════════════════════════════════════════════════════════════
    Component {
        id: theoryView

        ColumnLayout {
            spacing: 0
            width: parent ? parent.width : implicitWidth

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 8
                text: "📖 VOCABULARY"
                font { pixelSize: 11; weight: Font.Bold; letterSpacing: 1.0 }
                color: "#757575"
            }

            Item { Layout.preferredHeight: 8 }

            Repeater {
                model: controller ? controller.currentVocabulary : []
                delegate: vocabCard
            }

            Item { Layout.preferredHeight: 20 }

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 8
                text: "📝 GRAMMAR"
                font { pixelSize: 11; weight: Font.Bold; letterSpacing: 1.0 }
                color: "#757575"
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12; Layout.rightMargin: 12
                implicitHeight: grammarLabel.implicitHeight + 24
                radius: 8
                color: "#FFF8E1"
                border { width: 1; color: "#FFE082" }

                Label {
                    id: grammarLabel
                    anchors { fill: parent; margins: 12 }
                    textFormat: Text.RichText
                    text: controller ? controller.currentGrammar : ""
                    font.pixelSize: 14
                    color: "#4E342E"
                    wrapMode: Text.WordWrap
                }
            }

            Component {
                id: vocabCard

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.bottomMargin: 6
                    implicitHeight: 56
                    radius: 8
                    color: vcMouse.containsPress ? "#F5F5F5"
                         : vcMouse.containsMouse ? "#FAFAFA" : "white"
                    border { width: 1; color: "#E0E0E0" }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 12

                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                spacing: 6
                                Label {
                                    text: modelData.word
                                    font { pixelSize: 15; weight: Font.Bold }
                                    color: "#1565C0"
                                }
                                Label {
                                    text: "(" + (modelData.pos || "") + ")"
                                    font.pixelSize: 12
                                    color: "#9E9E9E"
                                }
                            }
                            Label {
                                text: modelData.meaning || ""
                                font.pixelSize: 13
                                color: "#424242"
                            }
                        }

                        Label {
                            text: modelData.ipa || ""
                            font { pixelSize: 13; italic: true }
                            color: "#757575"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        RoundButton {
                            implicitWidth: 32; implicitHeight: 32
                            flat: true
                            ToolTip.visible: hovered; ToolTip.text: "Pronounce"

                            contentItem: Text {
                                text: "🔊"
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 16
                                color: parent.pressed ? "#BBDEFB"
                                     : parent.hovered  ? "#E3F2FD" : "transparent"
                            }
                            onClicked: {
                                if (root.controller)
                                    root.controller.speakWord(modelData.word)
                            }
                        }
                    }

                    MouseArea {
                        id: vcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.controller)
                                root.controller.speakWord(modelData.word)
                        }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    //  COMPONENT: Exercises View (giữ nguyên như cũ)
    // ═════════════════════════════════════════════════════════════════
    Component {
        id: exercisesView

        ColumnLayout {
            id: exRoot
            spacing: 0
            width: parent ? parent.width : implicitWidth

            property string exMode: "all"
            property bool   submitted: false
            property int    correctCount: 0
            property int    answeredCount: 0

            function getScoreColor() {
                if (!submitted || answeredCount === 0) return "transparent"
                var pct = correctCount / Math.max(1, answeredCount)
                if (pct >= 0.7) return "#4CAF50"
                if (pct >= 0.4) return "#FF9800"
                return "#F44336"
            }

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 8
                text: "PRACTICE EXERCISES"
                font { pixelSize: 11; weight: Font.Bold; letterSpacing: 1.0 }
                color: "#757575"
            }

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 4
                text: exMode === "all" ? "Fill-in-the-blank · Multiple choice · Flashcards"
                     : "Review vocabulary from this lesson"
                font.pixelSize: 12
                color: "#9E9E9E"
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12; Layout.rightMargin: 12
                Layout.preferredHeight: 36
                radius: 18
                color: "#EEEEEE"

                RowLayout {
                    anchors.fill: parent
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 2
                        radius: 16
                        color: exRoot.exMode === "all" ? "white" : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Label {
                            anchors.centerIn: parent
                            text: "All Exercises"
                            font { pixelSize: 12; weight: Font.Medium }
                            color: exRoot.exMode === "all" ? "#1565C0" : "#757575"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { exRoot.exMode = "all"; exRoot.submitted = false }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 2
                        radius: 16
                        color: exRoot.exMode === "vocab" ? "white" : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Label {
                            anchors.centerIn: parent
                            text: "Flashcard Review"
                            font { pixelSize: 12; weight: Font.Medium }
                            color: exRoot.exMode === "vocab" ? "#1565C0" : "#757575"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: exRoot.exMode = "vocab"
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }

            ColumnLayout {
                id: allExMode
                visible: exRoot.exMode === "all"
                spacing: 0
                Layout.fillWidth: true

                property var exList: controller ? controller.currentExercises : []
                property int totalEx: exList.length
                property int currentIndex: 0

                property var exAnswered: ({})
                property var exCorrect: ({})
                property var exInput: ({})
                property bool showingFeedback: false

                Timer {
                    id: autoNextTimer
                    interval: 1200
                    repeat: false
                    onTriggered: {
                        allExMode.showingFeedback = false
                        if (allExMode.currentIndex < allExMode.totalEx - 1) {
                            allExMode.goTo(allExMode.currentIndex + 1)
                        } else {
                            allExMode.recountScore()
                            exRoot.submitted = true
                        }
                    }
                }

                function answerAndAdvance(idx, isCorrect) {
                    exAnswered[idx] = true
                    exCorrect[idx]  = isCorrect
                    exAnsweredChanged()
                    exCorrectChanged()
                    exInputChanged()
                    showingFeedback = true
                    autoNextTimer.restart()
                }

                function getCorrectAns(idx) {
                    var ex = exList[idx]
                    if (!ex) return ""
                    var opts = ex.options || []
                    var ans = (ex.answer || "")
                    if (ans === "A") return opts[0] || ""
                    if (ans === "B") return opts[1] || ""
                    if (ans === "C") return opts[2] || ""
                    if (ans === "D") return opts[3] || ""
                    return ""
                }

                function normalize(s) {
                    return String(s).trim().toLowerCase()
                }

                function submitAll() {
                    for (var i = 0; i < allExMode.totalEx; i++) {
                        var ex = exList[i]
                        if (!ex) continue
                        if (exAnswered[i]) {
                            exCorrect[i] = evaluateEx(i)
                        } else {
                            exAnswered[i] = true
                            exCorrect[i] = false
                        }
                    }
                    exRoot.submitted = true
                    recountScore()
                }

                function evaluateEx(idx) {
                    var ex = exList[idx]
                    if (!ex) return false
                    var t = ex.type || "fill-blank"
                    if (t === "fill-blank") {
                        var input = (exInput[idx] || "").toString()
                        return normalize(input) === normalize(ex.answer || "")
                    }
                    if (t === "multiple-choice") {
                        var optIdx = exInput[idx] !== undefined ? parseInt(exInput[idx]) : -1
                        if (optIdx < 0) return false
                        var opts = ex.options || []
                        var ans = (ex.answer || "")
                        var correctOpt = ans === "A" ? 0 : ans === "B" ? 1 : ans === "C" ? 2 : ans === "D" ? 3 : -1
                        return optIdx === correctOpt
                    }
                    return false
                }

                function recountScore() {
                    var c = 0, a = 0
                    for (var i = 0; i < allExMode.totalEx; i++) {
                        if (exAnswered[i]) a++
                        if (exCorrect[i]) c++
                    }
                    exRoot.correctCount = c
                    exRoot.answeredCount = a
                }

                function goTo(idx) {
                    if (idx < 0 || idx >= allExMode.totalEx) return
                    currentIndex = idx
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.preferredHeight: 4
                    radius: 2
                    color: "#E0E0E0"
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: allExMode.totalEx > 0 ? parent.width * (allExMode.currentIndex + 1) / allExMode.totalEx : 0
                        radius: 2
                        color: "#1565C0"
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }

                Item { Layout.preferredHeight: 6 }

                Label {
                    Layout.leftMargin: 16
                    text: "Exercise " + (allExMode.totalEx > 0 ? (allExMode.currentIndex + 1) : 0) + " of " + allExMode.totalEx
                    font { pixelSize: 12; weight: Font.Medium }
                    color: "#757575"
                }

                Rectangle {
                    id: exCard
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    implicitHeight: exCardBody.implicitHeight + 24
                    radius: 8
                    color: {
                        if (allExMode.totalEx === 0) return "transparent"
                        var idx = allExMode.currentIndex
                        if (exRoot.submitted) return exCorrect[idx] ? "#F1F8E9" : "#FFF3E0"
                        return "white"
                    }
                    border {
                        width: exRoot.submitted ? 2 : 1
                        color: {
                            if (allExMode.totalEx === 0) return "transparent"
                            var idx = allExMode.currentIndex
                            if (exRoot.submitted) return exCorrect[idx] ? "#A5D6A7" : "#FFAB91"
                            return "#E0E0E0"
                        }
                    }

                    readonly property var curEx: allExMode.totalEx > 0 ? allExMode.exList[allExMode.currentIndex] : null
                    readonly property string exType: curEx ? (curEx.type || "fill-blank") : ""
                    readonly property bool exAnswered: curEx ? (allExMode.exAnswered[allExMode.currentIndex] || false) : false
                    readonly property bool exCorrect: curEx ? (allExMode.exCorrect[allExMode.currentIndex] || false) : false

                    ColumnLayout {
                        id: exCardBody
                        anchors { left: parent.left; right: parent.right; top: parent.top
                                  leftMargin: 14; rightMargin: 14; topMargin: 10; bottomMargin: 14 }
                        spacing: 10

                        Rectangle {
                            visible: exCard.curEx !== null
                            Layout.preferredHeight: 20
                            implicitWidth: badgeLabel.implicitWidth + 12
                            radius: 10
                            color: exCard.exType === "fill-blank" ? "#E3F2FD"
                                 : exCard.exType === "multiple-choice" ? "#E8F5E9"
                                 : "#FFF3E0"

                            Label {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: exCard.exType === "fill-blank" ? "Fill in the blank"
                                    : exCard.exType === "multiple-choice" ? "Multiple choice"
                                    : "Flashcard"
                                font { pixelSize: 10; weight: Font.Medium }
                                color: exCard.exType === "fill-blank" ? "#1565C0"
                                     : exCard.exType === "multiple-choice" ? "#2E7D32"
                                     : "#E65100"
                            }
                        }

                        Label {
                            visible: exCard.curEx !== null
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            text: exCard.exType === "flashcard" ? (exCard.curEx ? (exCard.curEx.front || "") : "")
                                 : (exCard.curEx ? (exCard.curEx.question || "") : "")
                            font { pixelSize: 14; weight: exCard.exType === "flashcard" ? Font.Bold : Font.Normal }
                            color: "#212121"
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            visible: allExMode.totalEx === 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            text: "No exercises available for this topic."
                            font.pixelSize: 13
                            color: "#9E9E9E"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        function checkFillBlank() {
                            if (exCard.exAnswered) return
                            var idx = allExMode.currentIndex
                            var input = fbInput.text
                            allExMode.exInput[idx] = input
                            var ok = allExMode.normalize(input) === allExMode.normalize(exCard.curEx.answer || "")
                            allExMode.answerAndAdvance(idx, ok)
                        }

                        TextField {
                            id: fbInput
                            visible: exCard.exType === "fill-blank" && !exRoot.submitted
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            placeholderText: "Type your answer..."
                            font.pixelSize: 13
                            text: {
                                var saved = allExMode.exInput[allExMode.currentIndex] || ""
                                return saved
                            }
                            placeholderTextColor: {
                                if (fbInput.text.length > 0)
                                    return Qt.rgba(0,0,0,0)        // 🔥 có text → ẩn hoàn toàn
                                if (fbInput.activeFocus)
                                    return Qt.rgba(0,0,0,0)        // focus → mờ
                                return Qt.rgba(0,0,0,0.5)             // idle → rõ
                            }
                            background: Rectangle {
                                radius: 6
                                color: "white"
                                border { width: 1; color: fbInput.activeFocus ? "#1565C0" : "#E0E0E0" }
                            }
                            onTextChanged: {
                                allExMode.exInput[allExMode.currentIndex] = text
                            }
                            onAccepted: exCardBody.checkFillBlank()
                        }

                        Button {
                            visible: exCard.exType === "fill-blank" && !exRoot.submitted
                            implicitWidth: 80; implicitHeight: 32
                            text: exCard.exAnswered ? "Checked" : "Check"
                            enabled: !exCard.exAnswered && fbInput.text.trim() !== ""
                            font { pixelSize: 12; weight: Font.Medium }
                            contentItem: Label {
                                text: parent.text; color: "white"; font: parent.font
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: parent.enabled ? "#1565C0" : "#BDBDBD"
                            }
                            onClicked: exCardBody.checkFillBlank()
                        }

                        Repeater {
                            visible: exCard.exType === "multiple-choice"
                            model: exCard.curEx ? (exCard.curEx.options || []) : []

                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                readonly property string correctAns: allExMode.getCorrectAns(allExMode.currentIndex)
                                readonly property bool isSelected: {
                                    var saved = allExMode.exInput[allExMode.currentIndex]
                                    return saved !== undefined ? (parseInt(saved) === index) : false
                                }

                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 6
                                color: {
                                    if (exRoot.submitted)
                                        return modelData === correctAns ? "#C8E6C9" : "white"
                                    if (isSelected)
                                        return modelData === correctAns ? "#C8E6C9" : "#FFCDD2"
                                    return "white"
                                }
                                border {
                                    width: (exRoot.submitted && modelData === correctAns) || isSelected ? 2 : 1
                                    color: {
                                        if (exRoot.submitted && modelData === correctAns) return "#43A047"
                                        if (isSelected && modelData === correctAns) return "#43A047"
                                        if (isSelected) return "#E53935"
                                        return "#E0E0E0"
                                    }
                                }

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    spacing: 6
                                    Label {
                                        text: String.fromCharCode(65 + index) + "."
                                        font { pixelSize: 13; weight: Font.Bold }
                                        color: "#424242"
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: 13; color: "#212121"; wrapMode: Text.WordWrap
                                    }
                                    Label {
                                        text: "✓"
                                        visible: (exRoot.submitted || isSelected) && modelData === correctAns
                                        font { pixelSize: 14; weight: Font.Bold }
                                        color: "#2E7D32"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: 1
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !allExMode.exAnswered[allExMode.currentIndex] && !exRoot.submitted
                                    onClicked: {
                                        var idx = allExMode.currentIndex
                                        allExMode.exInput[idx] = index
                                        allExMode.exInputChanged()
                                        allExMode.answerAndAdvance(idx, modelData === correctAns)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: fbAnsLabel.implicitHeight + 12
                            radius: 6
                            visible: exCard.exType === "flashcard" && exCard.exAnswered
                            color: "#FFF8E1"
                            border { width: 1; color: "#FFE082" }

                            Label {
                                id: fbAnsLabel
                                anchors { fill: parent; margins: 8 }
                                text: exCard.curEx ? (exCard.curEx.back || "") : ""
                                font { pixelSize: 13; weight: Font.Bold }
                                color: "#E65100"
                                wrapMode: Text.WordWrap
                            }
                        }

                        Label {
                            visible: exCard.exType === "flashcard"
                            text: exCard.exAnswered ? "Tap to hide" : "Tap to reveal"
                            font { pixelSize: 11; italic: true }
                            color: "#BDBDBD"
                        }

                        Rectangle {
                            visible: exCard.exAnswered && exCard.exType !== "flashcard"
                            Layout.fillWidth: true
                            Layout.preferredHeight: feedbackRow.implicitHeight + 12
                            radius: 8
                            color: exCard.exCorrect ? "#E8F5E9" : "#FFF3E0"
                            border { width: 1; color: exCard.exCorrect ? "#A5D6A7" : "#FFAB91" }

                            RowLayout {
                                id: feedbackRow
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 6; bottomMargin: 6 }
                                spacing: 8

                                Label {
                                    text: exCard.exCorrect ? "✅" : "❌"
                                    font.pixelSize: 18
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: exCard.exCorrect ? "Chính xác!" : "Chưa đúng"
                                        font { pixelSize: 13; weight: Font.Bold }
                                        color: exCard.exCorrect ? "#2E7D32" : "#BF360C"
                                    }
                                    Label {
                                        visible: !exCard.exCorrect
                                        text: {
                                            if (exCard.exType === "multiple-choice")
                                                return "Đáp án: " + allExMode.getCorrectAns(allExMode.currentIndex)
                                            if (exCard.exType === "fill-blank")
                                                return "Đáp án: " + (exCard.curEx ? (exCard.curEx.answer || "") : "")
                                            return ""
                                        }
                                        font { pixelSize: 12; weight: Font.Medium }
                                        color: "#E65100"
                                        wrapMode: Text.WordWrap
                                    }
                                }
                                Rectangle {
                                    visible: allExMode.showingFeedback
                                    width: 6; height: 6; radius: 3
                                    color: exCard.exCorrect ? "#4CAF50" : "#FF7043"
                                    SequentialAnimation on opacity {
                                        running: allExMode.showingFeedback
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 500 }
                                        NumberAnimation { to: 1.0; duration: 500 }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: exCard.exType === "flashcard"
                        cursorShape: exCard.exType === "flashcard" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: exCard.exType === "flashcard" && !exRoot.submitted
                        onClicked: {
                            var idx = allExMode.currentIndex
                            allExMode.exAnswered[idx] = !allExMode.exAnswered[idx]
                        }
                    }
                }

                Item { Layout.preferredHeight: 10 }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    spacing: 8
                    visible: allExMode.totalEx > 0 && !exRoot.submitted
                             && exCard.exType === "flashcard"

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        enabled: allExMode.currentIndex > 0
                        text: "← Trước"
                        font { pixelSize: 13; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text; font: parent.font
                            color: parent.enabled ? "#1565C0" : "#BDBDBD"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 8; color: parent.enabled ? "#E3F2FD" : "#F5F5F5"
                            border { width: 1; color: parent.enabled ? "#1565C0" : "#E0E0E0" }
                        }
                        onClicked: allExMode.goTo(allExMode.currentIndex - 1)
                    }

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        enabled: exCard.exAnswered
                        text: allExMode.currentIndex < allExMode.totalEx - 1 ? "Tiếp →" : "Kết thúc"
                        font { pixelSize: 13; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text; font: parent.font
                            color: parent.enabled ? "#1565C0" : "#BDBDBD"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 8; color: parent.enabled ? "#E3F2FD" : "#F5F5F5"
                            border { width: 1; color: parent.enabled ? "#1565C0" : "#E0E0E0" }
                        }
                        onClicked: {
                            if (allExMode.currentIndex < allExMode.totalEx - 1)
                                allExMode.goTo(allExMode.currentIndex + 1)
                            else {
                                allExMode.recountScore(); exRoot.submitted = true
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 12 }

                Rectangle {
                    id: scoreBigCard
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.preferredHeight: scoreBigBody.implicitHeight + 32
                    radius: 16
                    visible: exRoot.submitted
                    color: "white"
                    border { width: 2; color: scoreAccent() }

                    function scoreAccent() {
                        var pct = exRoot.answeredCount > 0 ? exRoot.correctCount / exRoot.answeredCount : 0
                        if (pct >= 0.7) return "#43A047"
                        if (pct >= 0.4) return "#FF9800"
                        return "#E53935"
                    }

                    ColumnLayout {
                        id: scoreBigBody
                        anchors { left: parent.left; right: parent.right; top: parent.top
                                  leftMargin: 20; rightMargin: 20; topMargin: 16 }
                        spacing: 12

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 44
                            text: {
                                var pct = exRoot.answeredCount > 0 ? exRoot.correctCount / exRoot.answeredCount : 0
                                if (pct >= 0.9) return "🏆"
                                if (pct >= 0.7) return "🎉"
                                if (pct >= 0.4) return "💪"
                                return "📖"
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 88; height: 88; radius: 44
                            color: scoreBigCard.scoreAccent()
                            Label {
                                anchors.centerIn: parent
                                text: {
                                    var pct = exRoot.answeredCount > 0
                                        ? Math.round(exRoot.correctCount / exRoot.answeredCount * 100) : 0
                                    return pct + "%"
                                }
                                font { pixelSize: 22; weight: Font.Bold }
                                color: "white"
                            }
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: exRoot.correctCount + " / " + exRoot.answeredCount + " câu đúng"
                            font { pixelSize: 15; weight: Font.Medium }
                            color: "#424242"
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                var pct = exRoot.answeredCount > 0 ? exRoot.correctCount / exRoot.answeredCount : 0
                                if (pct >= 0.9) return "Xuất sắc! Bạn nắm rất chắc bài này 🌟"
                                if (pct >= 0.7) return "Làm tốt lắm! Tiếp tục phát huy nhé 👍"
                                if (pct >= 0.4) return "Khá ổn! Ôn thêm một chút sẽ tốt hơn 💡"
                                return "Hãy đọc lại phần Theory và thử lại nhé 📚"
                            }
                            font.pixelSize: 13
                            color: "#616161"
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.bottomMargin: 4
                            implicitWidth: 160; implicitHeight: 38
                            text: "🔄  Làm lại"
                            font { pixelSize: 13; weight: Font.Medium }
                            contentItem: Label {
                                text: parent.text; color: "white"; font: parent.font
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 19; color: scoreBigCard.scoreAccent()
                            }
                            onClicked: {
                                exRoot.submitted    = false
                                exRoot.correctCount = 0
                                exRoot.answeredCount= 0
                                allExMode.currentIndex   = 0
                                allExMode.exAnswered     = ({})
                                allExMode.exCorrect      = ({})
                                allExMode.exInput        = ({})
                                allExMode.showingFeedback= false
                                autoNextTimer.stop()
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 16 }
            }

            ColumnLayout {
                id: vocabMode
                visible: exRoot.exMode === "vocab"
                spacing: 0
                Layout.fillWidth: true

                property var vocabList: controller ? controller.currentVocabulary : []
                property int vocabIndex: 0
                property bool vocabFlipped: false

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.preferredHeight: 6
                    radius: 3
                    color: "#E0E0E0"

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: vocabMode.vocabList.length > 0
                            ? parent.width * (vocabMode.vocabIndex + 1) / vocabMode.vocabList.length
                            : 0
                        radius: 3
                        color: "#1565C0"
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }

                Item { Layout.preferredHeight: 8 }

                Label {
                    Layout.leftMargin: 16
                    text: vocabMode.vocabList.length > 0
                        ? "Word " + (vocabMode.vocabIndex + 1) + " of " + vocabMode.vocabList.length
                        : "No vocabulary"
                    font { pixelSize: 12; weight: Font.Medium }
                    color: "#757575"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.preferredHeight: 220
                    radius: 14
                    color: vocabMode.vocabFlipped ? "#FFF8E1" : "white"
                    border {
                        width: 2
                        color: vocabMode.vocabFlipped ? "#FFE082" : "#E0E0E0"
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: !vocabMode.vocabFlipped && vocabMode.vocabList.length > 0

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: vocabMode.vocabList.length > 0
                                    ? vocabMode.vocabList[vocabMode.vocabIndex].word || ""
                                    : ""
                                font { pixelSize: 28; weight: Font.Bold }
                                color: "#1565C0"
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: vocabMode.vocabList.length > 0
                                    ? "(" + (vocabMode.vocabList[vocabMode.vocabIndex].pos || "") + ")"
                                    : ""
                                font.pixelSize: 14
                                color: "#9E9E9E"
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 20
                                text: "Tap to reveal"
                                font { pixelSize: 11; italic: true }
                                color: "#BDBDBD"
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            visible: vocabMode.vocabFlipped && vocabMode.vocabList.length > 0

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: vocabMode.vocabList.length > 0
                                    ? vocabMode.vocabList[vocabMode.vocabIndex].meaning || ""
                                    : ""
                                font { pixelSize: 22; weight: Font.Medium }
                                color: "#E65100"
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: vocabMode.vocabList.length > 0
                                    ? vocabMode.vocabList[vocabMode.vocabIndex].ipa || ""
                                    : ""
                                font { pixelSize: 16; italic: true }
                                color: "#757575"
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: vocabMode.vocabList.length > 0
                                    ? "(" + (vocabMode.vocabList[vocabMode.vocabIndex].pos || "") + ")"
                                    : ""
                                font.pixelSize: 14
                                color: "#9E9E9E"
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: vocabMode.vocabList.length === 0
                            text: "No vocabulary words in this lesson."
                            font.pixelSize: 14
                            color: "#9E9E9E"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (vocabMode.vocabList.length > 0)
                                vocabMode.vocabFlipped = !vocabMode.vocabFlipped
                        }
                    }
                }

                Item { Layout.preferredHeight: 12 }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 160; implicitHeight: 38
                    visible: vocabMode.vocabList.length > 0
                    text: "Speak: " + (vocabMode.vocabList.length > 0
                        ? vocabMode.vocabList[vocabMode.vocabIndex].word || "" : "")

                    font { pixelSize: 13; weight: Font.Medium }
                    contentItem: Label {
                        text: parent.text
                        color: "white"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 19
                        color: parent.pressed ? "#0D47A1" : "#1565C0"
                    }
                    onClicked: {
                        if (root.controller && vocabMode.vocabList.length > 0)
                            root.controller.speakWord(vocabMode.vocabList[vocabMode.vocabIndex].word)
                    }
                }

                Item { Layout.preferredHeight: 12 }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    spacing: 12

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        enabled: vocabMode.vocabIndex > 0
                        text: "← Previous"

                        font { pixelSize: 13; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text
                            color: parent.enabled ? "#1565C0" : "#BDBDBD"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 8
                            color: parent.enabled ? "#E3F2FD" : "#F5F5F5"
                            border { width: 1; color: parent.enabled ? "#1565C0" : "#E0E0E0" }
                        }
                        onClicked: {
                            if (vocabMode.vocabIndex > 0) {
                                vocabMode.vocabIndex--
                                vocabMode.vocabFlipped = false
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        enabled: vocabMode.vocabIndex < vocabMode.vocabList.length - 1
                        text: "Next →"

                        font { pixelSize: 13; weight: Font.Medium }
                        contentItem: Label {
                            text: parent.text
                            color: parent.enabled ? "#1565C0" : "#BDBDBD"
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 8
                            color: parent.enabled ? "#E3F2FD" : "#F5F5F5"
                            border { width: 1; color: parent.enabled ? "#1565C0" : "#E0E0E0" }
                        }
                        onClicked: {
                            if (vocabMode.vocabIndex < vocabMode.vocabList.length - 1) {
                                vocabMode.vocabIndex++
                                vocabMode.vocabFlipped = false
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 16 }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                    implicitWidth: 140; implicitHeight: 32
                    text: "Start Over"

                    font { pixelSize: 12; weight: Font.Medium }
                    contentItem: Label {
                        text: parent.text
                        color: "#757575"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 16
                        color: parent.pressed ? "#E0E0E0" : "transparent"
                        border { width: 1; color: "#E0E0E0" }
                    }
                    onClicked: {
                        vocabMode.vocabIndex = 0
                        vocabMode.vocabFlipped = false
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    //  COMPONENT: AI Practice View
    // ═════════════════════════════════════════════════════════════════
    Component {
        id: aiPracticeView

        ColumnLayout {
            spacing: 0
            width: parent ? parent.width : implicitWidth

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 8
                text: "🤖 AI PRACTICE — " + (selectedTopic || "").toUpperCase()
                font { pixelSize: 11; weight: Font.Bold; letterSpacing: 1.0 }
                color: "#757575"
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12; Layout.rightMargin: 12
                implicitHeight: Math.max(120, aiText.implicitHeight + 24)
                radius: 8
                color: "#FFF3E0"
                border { width: 1; color: "#FFCC80" }

                StackLayout {
                    anchors { fill: parent; margins: 12 }
                    currentIndex: controller && controller.aiLoading ? 1 : 0

                    Flickable {
                        clip: true
                        contentHeight: aiText.implicitHeight
                        interactive: aiText.implicitHeight > height

                        Label {
                            id: aiText
                            width: parent.width
                            textFormat: Text.RichText
                            text: controller ? controller.aiResponse : ""
                            font.pixelSize: 14
                            color: "#4E342E"
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            BusyIndicator {
                                Layout.alignment: Qt.AlignHCenter
                                running: true
                                implicitWidth: 32; implicitHeight: 32
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: "AI is thinking..."
                                font.pixelSize: 12
                                color: "#A1887F"
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12; Layout.rightMargin: 12
                Layout.preferredHeight: 48
                radius: 24
                color: "white"
                border { width: 1; color: "#E0E0E0" }

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 4 }
                    spacing: 8

                    TextField {
                        id: aiInput
                        Layout.fillWidth: true
                        placeholderText: "Ask the AI tutor anything..."
                        font.pixelSize: 14
                        background: null
                        onAccepted: sendAiMessage()
                    }

                    RoundButton {
                        implicitWidth: 36; implicitHeight: 36
                        flat: true
                        enabled: aiInput.text.trim() !== ""

                        contentItem: Text {
                            text: "➤"
                            font.pixelSize: 18
                            color: aiInput.text.trim() !== "" ? "#1565C0" : "#BDBDBD"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 18
                            color: parent.pressed ? "#BBDEFB"
                                 : parent.hovered && parent.enabled ? "#E3F2FD" : "transparent"
                        }
                        onClicked: sendAiMessage()
                    }
                }
            }

            Label {
                Layout.leftMargin: 16; Layout.topMargin: 8
                text: "💡 <i>Powered by Qwen 3.7-max via OpenRouter</i>"
                font.pixelSize: 11
                color: "#BDBDBD"
            }

            function sendAiMessage() {
                if (aiInput.text.trim() === "" || !root.controller) return
                root.controller.aiChat(selectedTopic, aiInput.text.trim())
                aiInput.text = ""
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    //  INLINE COMPONENTS
    // ═════════════════════════════════════════════════════════════════

    component GradeCard: Rectangle {
        id: gradeCard
        property int    grade:     10
        property int    unitCount: 8
        signal clicked

        implicitHeight: 110
        radius: 12
        color: gradeCardMa.containsPress ? "#BBDEFB"
             : gradeCardMa.containsMouse ? "#E3F2FD" : "white"
        border { width: gradeCardMa.containsMouse ? 2 : 1; color: gradeCardMa.containsMouse ? "#1565C0" : "#E0E0E0" }

        Behavior on color { ColorAnimation { duration: 120 } }



        Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 44; height: 44
                radius: 22
                color: "#E3F2FD"
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    anchors.centerIn: parent
                    text: gradeCard.grade
                    font { pixelSize: 18; weight: Font.Bold }
                    color: "#1565C0"
                }
            }
            Label {
                text: "Grade " + gradeCard.grade
                font { pixelSize: 14; weight: Font.Medium }
                color: "#212121"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: gradeCard.unitCount + " units"
                font.pixelSize: 11
                color: "#9E9E9E"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            id: gradeCardMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: gradeCard.clicked()
        }
    }

    component SectionChip: Rectangle {
        id: sc
        property string label:     "Theory"
        property string chipColor: "#3949AB"
        property string chipBg:    "#E8EAF6"
        signal clicked

        implicitHeight: 52
        radius: 26
        color: scMa.containsPress ? Qt.darker(chipBg, 1.1)
             : scMa.containsMouse ? chipBg : "white"
        border { width: scMa.containsMouse ? 2 : 1; color: scMa.containsMouse ? chipColor : "#E0E0E0" }

        Behavior on color { ColorAnimation { duration: 120 } }



        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 8

            Rectangle {
                width: 32; height: 32; radius: 16
                color: sc.chipBg
                Label {
                    anchors.centerIn: parent
                    text: sc.label === "Theory"    ? "📖"
                        : sc.label === "Exercises" ? "✏️" : "🤖"
                    font.pixelSize: 15
                    color: sc.chipColor
                }
            }
            Label {
                text: sc.label
                font { pixelSize: 13; weight: Font.Medium }
                color: "#212121"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: scMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sc.clicked()
        }
    }

    component BreadcrumbSegment: Rectangle {
        id: bs
        property string label: "Grade 10"
        signal segmentClicked

        implicitWidth:  contentLabel.implicitWidth + 28
        implicitHeight: 36
        color: bsMa.containsMouse ? "#1AFFFFFF" : "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
            spacing: 4
            Label {
                id: contentLabel
                text: bs.label
                font { pixelSize: 13; weight: Font.Medium }
                color: "white"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: "▾"
                font.pixelSize: 11
                color: "#B3FFFFFF"
            }
        }

        MouseArea {
            id: bsMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bs.segmentClicked()
        }
    }

    component BcDropItem: Rectangle {
        id: bdi
        property string itemText:  ""
        property bool   isSelected: false
        signal itemClicked

        width: parent ? parent.width : 160
        height: 44
        color: bdiMa.containsMouse ? "#E3F2FD" : "white"

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: "#F0F0F0"
            visible: true
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
            spacing: 8

            Label {
                text: bdi.itemText
                font { pixelSize: 14; weight: bdi.isSelected ? Font.Medium : Font.Normal }
                color: bdi.isSelected ? "#1565C0" : "#212121"
                Layout.fillWidth: true
            }
            Label {
                text: "✓"
                font.pixelSize: 14
                color: "#1565C0"
                visible: bdi.isSelected
            }
        }

        MouseArea {
            id: bdiMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bdi.itemClicked()
        }
    }
}
