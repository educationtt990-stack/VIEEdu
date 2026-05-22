import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: page
    title: "📐 Toán Học Thú Vị"

    readonly property color cPrimary : "#2563EB"
    readonly property color cPrimaryLight : "#3B82F6"
    readonly property color cPrimaryDark : "#1D4ED8"
    readonly property color cViolet  : "#7C3AED"
    readonly property color cAmber   : "#F59E0B"
    readonly property color cGreen   : "#10B981"
    readonly property color cGreenLight : "#34D399"
    readonly property color cRed     : "#EF4444"
    readonly property color cRedLight : "#F87171"
    readonly property color cBg      : "#EFF6FF"
    readonly property color cCard    : "#FFFFFF"
    readonly property color cGray    : "#94A3B8"
    readonly property color cText    : "#1E293B"
    readonly property color cMuted   : "#64748B"
    readonly property color cBorder  : "#E2E8F0"
    readonly property color cShadow  : "#1E293B14"
    readonly property int   borderRadius : 14
    readonly property int   borderRadiusSm : 10
    readonly property int   borderRadiusLg : 20

    readonly property int  animFast : 150
    readonly property int  animNorm : 250
    readonly property int  animSlow : 400

    function shadowRect(radius, color) {
        return { radius: radius, color: color || cShadow }
    }

    property var jsonData: ({})
    property bool dataReady: false
    property var grades: []
    property var currentLessons: []
    property var currentChapters: []

    property int  screen    : 0
    property int  selGrade  : 0
    property int  selLesson : 0
    property string targetMode: ""        // "theory", "quiz", "practice"

    property int  qStep : 0
    property int  qHits : 0
    property bool qDone : false
    property int  qAns  : -1

    property int  pStep : 0
    property int  pHits : 0
    property bool pDone : false
    property int  pAns  : -1
    property string pDiff: "medium"       // current practice difficulty filter

    property var prog: [{tDone: false, qScore: 0, pEasy: false, pMed: false, pHard: false, done: false}]
    property var _progCache: ({})

    property var _curLesson: currentLessons.length > 0 && selLesson >= 0 && selLesson < currentLessons.length ? currentLessons[selLesson] : null

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "../../data.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                try {
                    jsonData = JSON.parse(xhr.responseText);
                    var keys = Object.keys(jsonData);
                    keys.sort(function(a,b){
                        var na = parseInt(a.match(/\d+/)[0]);
                        var nb = parseInt(b.match(/\d+/)[0]);
                        return na - nb;
                    });
                    grades = keys;
                    if (grades.length > 0) {
                        selGrade = 0;
                        buildLessonsForGrade(grades[0]);
                    }
                    dataReady = true;
                } catch(e) {
                    console.error("JSON parse error:", e);
                }
            }
        };
        xhr.send();
    }

    function buildLessonsForGrade(gradeKey, prevGradeIndex) {
        // Save current progress before switching
        var saveIdx = (prevGradeIndex !== undefined) ? prevGradeIndex : selGrade
        if (grades.length > 0 && saveIdx >= 0 && saveIdx < grades.length)
            _progCache[grades[saveIdx]] = prog.slice();

        var list = [];
        var chapters = [];
        var gradeData = jsonData[gradeKey];
        if (!gradeData || !gradeData["To\u00e1n"]) {
            prog = [{tDone: false, qScore: 0, pEasy: false, pMed: false, pHard: false, done: false}];
            currentLessons = [];
            currentChapters = [];
            return;
        }
        var monToan = gradeData["To\u00e1n"];
        var chuongKeys = Object.keys(monToan).sort();
        for (var ci = 0; ci < chuongKeys.length; ci++) {
            var chuongName = chuongKeys[ci];
            var baiKeys = Object.keys(monToan[chuongName]).sort();
            for (var bi = 0; bi < baiKeys.length; bi++) {
                var baiName = baiKeys[bi];
                var bai = monToan[chuongName][baiName];
                list.push({
                    title: baiName,
                    emoji: bai.emoji || "\ud83d\udcd8",
                    sub: bai.m\u00f4_t\u1ea3 || "",
                    theory: bai.theory || [],
                    quiz: bai.quiz || [],
                    practice: bai.practice || [],
                    chapterTitle: chuongName
                });
                chapters.push(chuongName);
            }
        }
        var n = Math.max(1, list.length);
        var cached = _progCache[gradeKey];
        if (cached && cached.length === n) {
            prog = cached;
        } else {
            var p = [];
            for (var i = 0; i < n; i++)
                p.push({ tDone: false, qScore: 0, pEasy: false, pMed: false, pHard: false, done: false });
            prog = p;
        }
        currentLessons = list;
        currentChapters = chapters;
    }

    function initProgress() {
        var arr = [];
        var n = Math.max(1, currentLessons.length);
        for (var i = 0; i < n; i++) {
            arr.push({
                tDone: false, qScore: 0, pEasy: false, pMed: false, pHard: false, done: false
            });
        }
        prog = arr;
    }

    function avgScore()  {
        var p = prog[selLesson];
        if (!p) return 0;
        var diffDone = (p.pEasy ? 1 : 0) + (p.pMed ? 1 : 0) + (p.pHard ? 1 : 0)
        var pScore = diffDone >= 3 ? 100 : diffDone * 33
        return Math.round((p.qScore + pScore) / 2)
    }
    function passed()    { return avgScore() >= 70 }

    function setProg(idx, patch) {
        var p = prog.slice()
        var cur = p[idx]
        p[idx] = {
            tDone   : (patch.tDone    !== undefined ? patch.tDone    : cur.tDone),
            qScore  : (patch.qScore   !== undefined ? patch.qScore   : cur.qScore),
            pEasy   : (patch.pEasy    !== undefined ? patch.pEasy    : cur.pEasy),
            pMed    : (patch.pMed     !== undefined ? patch.pMed     : cur.pMed),
            pHard   : (patch.pHard    !== undefined ? patch.pHard    : cur.pHard),
            done    : (patch.done     !== undefined ? patch.done     : cur.done)
        }
        prog = p
    }

    // Get practice questions filtered by difficulty
    function getPracticeByDiff(diff) {
        var lesson = currentLessons[selLesson];
        if (!lesson || !lesson.practice) return [];
        return lesson.practice.filter(function(q){ return q.difficulty === diff });
    }

    function goLesson(idx, mode) {
        selLesson = idx
        targetMode = mode || ""
        qStep=0; qHits=0; qDone=false; qAns=-1
        pStep=0; pHits=0; pDone=false; pAns=-1
        pDiff = (mode === "practice") ? "easy" : "medium"
        screen = (mode === "theory") ? 2 : (mode === "quiz") ? 3 : (mode === "practice") ? 4 : 0
    }

    function doneTheory() {
        setProg(selLesson, { tDone: true })
        screen = 1  // back to chapter selection
    }

    function submitQuiz(a) {
        if (a < 0) return
        var lesson = currentLessons[selLesson]
        if (!lesson.quiz || lesson.quiz.length === 0) return
        if (a === lesson.quiz[qStep].ans || a === parseInt(lesson.quiz[qStep].answer)) qHits++
        if (qStep + 1 < lesson.quiz.length) {
            qStep++; qAns = -1
        } else {
            var s = lesson.quiz.length > 0 ? Math.round(qHits / lesson.quiz.length * 100) : 0
            setProg(selLesson, { qScore: s })
            qDone = true
        }
    }

    function getPracticeTotal() {
        return getPracticeByDiff(pDiff).length
    }
    function isPLocked(diff) {
        if (diff === "easy") return false
        if (diff === "medium") return !prog[selLesson].pEasy
        if (diff === "hard") return !prog[selLesson].pMed
        return false
    }

    function submitPractice(a) {
        if (a < 0) return
        var practice = getPracticeByDiff(pDiff)
        if (practice.length === 0) return
        if (a === practice[pStep].ans || a === parseInt(practice[pStep].answer)) pHits++
        if (pStep + 1 < practice.length) {
            pStep++; pAns = -1
        } else {
            var nTotal = getPracticeByDiff(pDiff).length
            var s = nTotal > 0 ? Math.round(pHits / nTotal * 100) : 0
            var patch = {}
            if (s >= 70) {
                if (pDiff === "easy") patch.pEasy = true
                else if (pDiff === "medium") patch.pMed = true
                else if (pDiff === "hard") patch.pHard = true
            }
            var p = prog[selLesson]
            if ((p.pEasy || patch.pEasy) && (p.pMed || patch.pMed) && (p.pHard || patch.pHard))
                patch.done = true
            setProg(selLesson, patch)
            pDone = true
        }
    }

    function doUnlock(isFinal) {
        setProg(selLesson, { done: true })
        congratsOverlay.isFinal = isFinal
        congratsOverlay.visible = true
    }

    function retryLesson() {
        setProg(selLesson, { tDone: false, qScore: 0, pEasy: false, pMed: false, pHard: false, done: false })
        qStep=0; qHits=0; qDone=false; qAns=-1
        pStep=0; pHits=0; pDone=false; pAns=-1
        screen = 1
    }

    function lessonScore(i) {
        var p = prog[i]
        var diffDone = (p.pEasy ? 1 : 0) + (p.pMed ? 1 : 0) + (p.pHard ? 1 : 0)
        var pScore = diffDone >= 3 ? 100 : diffDone * 33
        return Math.round((p.qScore + pScore) / 2)
    }

    function allLessonsScore() {
        var total = 0, count = 0
        for (var i = 0; i < prog.length; i++) {
            if (prog[i].done) {
                total += lessonScore(i)
                count++
            }
        }
        return count > 0 ? Math.round(total / count) : 0
    }

    function completedLessons() {
        var c = 0
        for (var i = 0; i < prog.length; i++) { if (prog[i].done) c++ }
        return c
    }

    function bestLesson() {
        var best = -1, bestScore = -1
        for (var i = 0; i < prog.length; i++) {
            if (prog[i].done) {
                var s = lessonScore(i)
                if (s > bestScore) { bestScore = s; best = i }
            }
        }
        return best >= 0 ? currentLessons[best] : null
    }

    function worstLesson() {
        var worst = -1, worstScore = 101
        for (var i = 0; i < prog.length; i++) {
            if (prog[i].done) {
                var s = lessonScore(i)
                if (s < worstScore) { worstScore = s; worst = i }
            }
        }
        return worst >= 0 ? currentLessons[worst] : null
    }

    function hasInProgress() {
        for (var i = 0; i < prog.length; i++) {
            if (prog[i].tDone && !prog[i].done) return i
        }
        return -1
    }

    function getContinueLesson() {
        for (var i = 0; i < prog.length; i++) {
            if (prog[i].tDone && !prog[i].done) return { index: i, lesson: currentLessons[i] }
        }
        return null
    }

    background: Rectangle {
        color: page.cBg

        Repeater {
            model: [
                { x:0.1, y:0.1, s:180, d:25, c:"#BFDBFE", o:0.3 },
                { x:0.8, y:0.15, s:140, d:30, c:"#C7D2FE", o:0.25 },
                { x:0.05, y:0.7, s:120, d:20, c:"#FDE68A", o:0.15 },
                { x:0.85, y:0.8, s:200, d:35, c:"#A7F3D0", o:0.15 },
                { x:0.5, y:0.05, s:80, d:40, c:"#FECDD3", o:0.1 },
            ]
            delegate: Rectangle {
                id: bubble
                x: parent.width * modelData.x - modelData.s/2
                y: parent.height * modelData.y - modelData.s/2
                width: modelData.s; height: modelData.s
                radius: modelData.s/2
                color: modelData.c; opacity: 0

                SequentialAnimation on y {
                    loops: Animation.Infinite; running: true
                    NumberAnimation {
                        from: bubble.y; to: bubble.y - 30 + Math.random()*60
                        duration: 3000 + Math.random()*4000; easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: bubble.y - 30 + Math.random()*60; to: bubble.y
                        duration: 3000 + Math.random()*4000; easing.type: Easing.InOutSine
                    }
                }
                NumberAnimation on opacity {
                    from: 0; to: modelData.o; duration: 2000; easing.type: Easing.OutCubic
                }
            }
        }
    }

    component ScreenTransition : Item {
        id: stRoot
        property bool show: false
        default property alias content: stContent.children

        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: page.animNorm; easing.type: Easing.OutCubic } }

        onShowChanged: {
            if (show) { opacity = 1; stRoot.z = 1 }
            else { opacity = 0; stRoot.z = 0 }
        }

        Item { id: stContent; anchors.fill: parent }

        NumberAnimation on scale {
            id: stScaleAnim
            from: 0.96; to: 1.0; duration: page.animNorm
            easing.type: Easing.OutCubic
            running: stRoot.show
        }
    }

    Item {
        anchors.fill: parent

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 0 — DASHBOARD
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 0

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth; clip: true

                Column {
                    width: parent.width; spacing: 0
                    Item { width:1; height:28 }

                    Column {
                        x: 28; width: parent.width - 56; spacing: 4
                        Text {
                            text: "\ud83d\udcd0 To\u00e1n H\u1ecdc Th\u00fa V\u1ecb"
                            font.pixelSize: 32; font.bold: true; color: cText
                            NumberAnimation on opacity { from:0; to:1; duration:400 }
                            NumberAnimation on x { from: -20; to: 0; duration:400; easing.type:Easing.OutCubic }
                        }
                        Text {
                            text: "H\u1ecdc vui \u00b7 Hi\u1ec3u s\u00e2u \u00b7 Ti\u1ebfn xa"
                            font.pixelSize: 14; color: cMuted
                            NumberAnimation on opacity { from:0; to:1; duration:500 }
                        }
                    }
                    Item { width:1; height:32 }

                    Row {
                        x: 28; width: parent.width - 56; spacing: 12
                        Repeater {
                            model: [
                                { ico:"\ud83d\udcda", lbl:"B\u00e0i h\u1ecdc", val: currentLessons.length },
                                { ico:"\ud83d\udcdd", lbl:"\u0110\u00e3 l\u00e0m", val: completedLessons() },
                                { ico: allLessonsScore()>=70?"\ud83c\udfc6":"\ud83d\udcd6", lbl:"T\u1ed5ng th\u1ec3", val: allLessonsScore()+"%" }
                            ]
                            delegate: Rectangle {
                                width: (parent.width - 24) / 3; height: 72; radius: borderRadius
                                color: cCard
                                border.color: cBorder; border.width: 1
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.ico; font.pixelSize:20 }
                                    Text { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.val; font.pixelSize:18; font.bold:true; color:cText }
                                    Text { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.lbl; font.pixelSize:10; color:cMuted }
                                }
                            }
                        }
                    }
                    Item { width:1; height:28 }

                    Text { x: 28; text: "\u26a1 Kh\u00e1m ph\u00e1"; font.pixelSize:15; font.bold:true; color:cText }
                    Item { width:1; height:14 }

                    Grid {
                        x: 28; width: parent.width - 56
                        columns: 2; columnSpacing: 12; rowSpacing: 12
                        Repeater {
                            model: [
                                { ico:"\ud83d\udcd6", lbl:"L\u00fd thuy\u1ebft", sub:"N\u1eafm v\u1eefng ki\u1ebfn th\u1ee9c", clr:"#2563EB", clr2:"#3B82F6", mode:"theory" },
                                { ico:"\ud83d\udcdd", lbl:"B\u00e0i t\u1eadp", sub:"Ki\u1ec3m tra hi\u1ec3u b\u00e0i", clr:"#7C3AED", clr2:"#8B5CF6", mode:"quiz" },
                                { ico:"\ud83c\udfcb\ufe0f", lbl:"R\u00e8n luy\u1ec7n", sub:"D\u1ec5 \u00b7 Trung b\u00ecnh \u00b7 N\u00e2ng cao", clr:"#F59E0B", clr2:"#FBBF24", mode:"practice" },
                                { ico:"\ud83c\udfc6", lbl:"Th\u00e0nh t\u00edch", sub:"Xem k\u1ebft qu\u1ea3 h\u1ecdc t\u1eadp", clr:"#10B981", clr2:"#34D399", mode:"achievement" },
                            ]
                            delegate: Rectangle {
                                id: dashCard
                                width: (parent.width - 12) / 2; height: 120
                                radius: borderRadiusLg
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData.clr }
                                    GradientStop { position: 1.0; color: modelData.clr2 }
                                }
                                Item {
                                    anchors.fill: parent; anchors.margins: 16
                                    Column {
                                        spacing: 6
                                        Text { text: modelData.ico; font.pixelSize: 28 }
                                        Text { text: modelData.lbl; font.pixelSize: 17; font.bold: true; color: "white" }
                                        Text {
                                            text: modelData.sub
                                            font.pixelSize: 11; color: Qt.rgba(1,1,1,0.7)
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: borderRadiusLg
                                    color: "white"; opacity: dashHover ? 0.1 : 0
                                    Behavior on opacity { NumberAnimation { duration: page.animFast } }
                                }
                                property bool dashHover: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: dashHover ? 1.03 : 1.0
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: dashCard.dashHover = true
                                    onExited: dashCard.dashHover = false
                                    onClicked: {
                                        if (modelData.mode === "achievement") {
                                            screen = 5
                                        } else {
                                            targetMode = modelData.mode
                                            screen = 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item { width:1; height:28 }

                    // ── TIẾP TỤC HỌC (only when in-progress) ──
                    Text {
                        x: 28
                        text: "\u25b6 Ti\u1ebfp t\u1ee5c h\u1ecdc"
                        font.pixelSize: 15; font.bold: true; color: cText
                        visible: getContinueLesson() !== null
                    }
                    Item { width:1; height:14; visible: getContinueLesson() !== null }

                    Rectangle {
                        id: resumeCard
                        x: 28; width: parent.width - 56; height: 88; radius: borderRadiusLg
                        color: cCard
                        border.color: cPrimary; border.width: 1.5
                        visible: getContinueLesson() !== null

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 16
                            spacing: 16
                            Rectangle {
                                width: 52; height: 52; radius: 16
                                color: Qt.rgba(37/255, 99/255, 235/255, 0.1)
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        var c = getContinueLesson()
                                        return c ? c.lesson.emoji : "\ud83d\udcd6"
                                    }
                                    font.pixelSize: 24
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Text {
                                    text: {
                                        var c = getContinueLesson()
                                        return c ? c.lesson.title : ""
                                    }
                                    font.pixelSize: 14; font.bold: true; color: cText
                                }
                                Text {
                                    text: "L\u1edbp " + (grades[selGrade] || "")
                                    font.pixelSize: 11; color: cMuted
                                }
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 16
                            width: 36; height: 36; radius: 18; color: cPrimary
                            Text { anchors.centerIn: parent; text: "\u2192"; font.pixelSize: 18; color: "white"; font.bold: true }
                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                            scale: resumeCard.resumeHover ? 1.15 : 1.0
                        }
                        property bool resumeHover: false
                        Behavior on scale { NumberAnimation { duration: page.animFast } }
                        scale: resumeHover ? 1.015 : 1.0
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: resumeCard.resumeHover = true
                            onExited: resumeCard.resumeHover = false
                            onClicked: {
                                var c = getContinueLesson()
                                if (c) {
                                    selLesson = c.index
                                    screen = 2  // continue with theory
                                }
                            }
                        }
                    }

                    Item { width:1; height:24 }

                    Row {
                        x: 28; width: parent.width - 56; spacing: 10
                        Repeater {
                            model: grades
                            delegate: Rectangle {
                                width: (parent.width - (grades.length-1)*10) / grades.length
                                height: 42; radius: borderRadius
                                color: "transparent"
                                border.color: cBorder; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.replace("L\u1edbp ", "")
                                    font.pixelSize: 12; font.bold: true; color: cMuted
                                }
                                property bool ghover: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                Behavior on border.color { PropertyAnimation { duration: page.animFast } }
                                scale: ghover ? 1.05 : 1.0
                                border.color: ghover ? cPrimary : cBorder
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.ghover = true
                                    onExited: parent.ghover = false
                                        onClicked: {
                                            var oldIdx = selGrade;
                                            selGrade = index;
                                            buildLessonsForGrade(grades[index], oldIdx);
                                            selLesson = 0;
                                            screen = 1;
                                        }
                                }
                            }
                        }
                    }
                    Item { width:1; height:32 }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\u2728 Nhi\u1ec1u m\u00f4n h\u1ecdc kh\u00e1c s\u1eafp ra m\u1eaft"
                        font.pixelSize: 12; color: cGray; font.italic: true
                    }
                    Item { width:1; height:24 }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 1 — CHAPTER & GRADE SELECTION (with action buttons per mode)
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 1

            Column {
                anchors.fill: parent; spacing: 0

                Rectangle {
                    width: parent.width; height: 66
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cPrimary }
                        GradientStop { position: 1.0; color: cPrimaryLight }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        anchors.leftMargin: 18; spacing: 14
                        Rectangle {
                            width: 36; height: 36; radius: 10; color: Qt.rgba(1,1,1,0.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn:parent; text:"\u2190"; color:"white"; font.pixelSize:20; font.bold:true }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: screen=0 }
                        }
                        Text {
                            text: {
                                var m = targetMode === "theory" ? "L\u00fd thuy\u1ebft" : targetMode === "quiz" ? "B\u00e0i t\u1eadp" : targetMode === "practice" ? "R\u00e8n luy\u1ec7n" : ""
                                return "\ud83d\udcd0 " + m + " \u2014 Ch\u1ecdn l\u1edbp"
                            }
                            font.pixelSize: 18; font.bold: true; color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                ScrollView {
                    id: chScv
                    width: parent.width; height: parent.height - 66
                    contentWidth: availableWidth; clip: true

                    Column {
                        width: chScv.availableWidth; spacing: 0
                        Item { width:1; height:18 }

                        // Grade tabs
                        Row {
                            x: 26; width: chScv.availableWidth - 52; spacing: 8
                            Repeater {
                                model: grades
                                delegate: Rectangle {
                                    width: (parent.width - (grades.length-1)*8) / grades.length
                                    height: 38; radius: borderRadius
                                    color: selGrade === index ? cPrimary : "#F1F5F9"
                                    border.color: selGrade === index ? cPrimary : cBorder; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 12; font.bold: selGrade===index
                                        color: selGrade===index ? "white" : cText
                                    }
                                    property bool gh: false
                                    Behavior on scale { NumberAnimation { duration: page.animFast } }
                                    scale: gh ? 1.04 : 1.0
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onEntered: parent.gh = true
                                        onExited: parent.gh = false
                                        onClicked: {
                                            var oldIdx = selGrade;
                                            selGrade = index;
                                            buildLessonsForGrade(grades[index], oldIdx);
                                        }
                                    }
                                }
                            }
                        }
                        Item { width:1; height:20 }

                        // Chapter headers with lesson items
                        Repeater {
                            model: currentLessons
                            delegate: Column {
                                property int li: index
                                width: chScv.availableWidth; spacing: 0

                                Item {
                                    width: parent.width
                                    height: (index === 0 || currentChapters[index] !== currentChapters[index-1]) ? 32 : 0
                                    visible: height > 0
                                    Text {
                                        x: 36; y: 10
                                        text: "\ud83d\udcc2 " + currentChapters[index]
                                        font.pixelSize: 12; font.bold: true; color: cMuted
                                    }
                                }

                                Rectangle {
                                    id: chCard
                                    x: 26; width: chScv.availableWidth - 52
                                    height: 90
                                    radius: borderRadiusLg
                                    color: cCard
                                    border.color: cBorder; border.width: 1

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left; anchors.leftMargin: 16
                                        spacing: 14

                                        Rectangle {
                                            width: 44; height: 44; radius: 14
                                            color: "#EFF6FF"
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.emoji
                                                font.pixelSize: 22
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                            Text {
                                                text: modelData.title
                                                font.pixelSize: 14; font.bold: true
                                                color: cText
                                            }
                                            Text {
                                                text: modelData.sub
                                                font.pixelSize: 11; color: cMuted
                                            }
                                        }
                                    }

                                    Row {
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 14; spacing: 8

                                        Rectangle {
                                            width: 64; height: 32; radius: 16
                                            color: "#EFF6FF"
                                            visible: targetMode === "" || targetMode === "theory"
                                            Text { anchors.centerIn:parent; text:"\ud83d\udcd6 \u0110\u1ecdc"; font.pixelSize:11; color:cPrimary }
                                            property bool h: false
                                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                                            scale: h ? 1.08 : 1.0
                                            MouseArea {
                                                anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onEntered: parent.h = true
                                                onExited: parent.h = false
                                                onClicked: goLesson(li, "theory")
                                            }
                                        }
                                        Rectangle {
                                            width: 64; height: 32; radius: 16
                                            color: "#F5F3FF"
                                            visible: targetMode === "" || targetMode === "quiz"
                                            Text { anchors.centerIn:parent; text:"\ud83d\udcdd L\u00e0m"; font.pixelSize:11; color:cViolet }
                                            property bool h: false
                                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                                            scale: h ? 1.08 : 1.0
                                            MouseArea {
                                                anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onEntered: parent.h = true
                                                onExited: parent.h = false
                                                onClicked: goLesson(li, "quiz")
                                            }
                                        }
                                        Rectangle {
                                            width: 72; height: 32; radius: 16
                                            color: "#FFFBEB"
                                            visible: targetMode === "" || targetMode === "practice"
                                            Text { anchors.centerIn:parent; text:"\ud83c\udfcb\ufe0f Luy\u1ec7n"; font.pixelSize:11; color:cAmber }
                                            property bool h: false
                                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                                            scale: h ? 1.08 : 1.0
                                            MouseArea {
                                                anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onEntered: parent.h = true
                                                onExited: parent.h = false
                                                onClicked: goLesson(li, "practice")
                                            }
                                        }
                                    }
                                }
                                Item { width:1; height:12 }
                            }
                        }

                        Item { width:1; height:24 }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 2 — THEORY READER (full screen)
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 2

            Item {
                anchors.fill: parent

                Rectangle {
                    id: theoryHeader
                    anchors.top: parent.top; width: parent.width; height: 66
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cPrimary }
                        GradientStop { position: 1.0; color: cPrimaryLight }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        anchors.leftMargin: 18; spacing: 14
                        Rectangle {
                            width: 36; height: 36; radius: 10; color: Qt.rgba(1,1,1,0.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn:parent; text:"\u2190"; color:"white"; font.pixelSize:20; font.bold:true }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: screen=1 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: _curLesson ? _curLesson.title : ""
                                font.pixelSize: 16; font.bold: true; color: "white"
                            }
                            Text {
                                text: "\ud83d\udcd6 \u0110\u1ecdc l\u00fd thuy\u1ebft"
                                font.pixelSize: 11; color: Qt.rgba(1,1,1,0.7)
                            }
                        }
                    }
                }

                ScrollView {
                    id: theorySv
                    anchors.top: theoryHeader.bottom; anchors.bottom: theoryBtn.top
                    width: parent.width
                    contentWidth: availableWidth; clip: true

                    Column {
                        width: theorySv.availableWidth; spacing: 16
                        Item { width:1; height:10 }

                        Repeater {
                            model: _curLesson ? _curLesson.theory : []
                            delegate: Rectangle {
                                id: theoryCard
                                x: 26; width: theorySv.availableWidth - 52
                                height: tCol.implicitHeight + 32; radius: borderRadius
                                color: cCard; border.color: cBorder; border.width: 1

                                Column {
                                    id: tCol
                                    anchors { left:parent.left; right:parent.right; top:parent.top; margins:16 }
                                    spacing: 10
                                    Row {
                                        spacing: 8
                                        Rectangle { width:4; height:18; radius:2; color:cPrimary; anchors.verticalCenter:parent.verticalCenter }
                                        Text { text:modelData.title; font.pixelSize:15; font.bold:true; color:cPrimary }
                                    }
                                    Text {
                                        width: parent.width - 12
                                        text: modelData.content
                                        font.pixelSize: 14; color: cText
                                        wrapMode: Text.WordWrap; lineHeight: 1.65
                                    }
                                }
                            }
                        }
                        Item { width:1; height:10 }
                    }
                }

                Rectangle {
                    id: theoryBtn
                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 14
                    width: 310; height: 48; radius: 24
                    color: prog[selLesson].tDone ? cGreen : cPrimary
                    Text {
                        anchors.centerIn: parent
                        text: prog[selLesson].tDone
                            ? "\u2705 \u0110\u00e3 ho\u00e0n th\u00e0nh l\u00fd thuy\u1ebft!"
                            : "\u2705 T\u00f4i \u0111\u00e3 hi\u1ec3u"
                        font.pixelSize: 14; font.bold: true; color: "white"
                    }
                    property bool hovered: false
                    Behavior on scale { NumberAnimation { duration: page.animFast } }
                    scale: hovered ? 1.03 : 1.0
                    MouseArea {
                        anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: theoryBtn.hovered = true
                        onExited: theoryBtn.hovered = false
                        onClicked: doneTheory()
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 3 — QUIZ TAKER (full screen)
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 3

            Column {
                anchors.fill: parent; spacing: 0

                Rectangle {
                    width: parent.width; height: 66
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cViolet }
                        GradientStop { position: 1.0; color: "#8B5CF6" }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        anchors.leftMargin: 18; spacing: 14
                        Rectangle {
                            width: 36; height: 36; radius: 10; color: Qt.rgba(1,1,1,0.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn:parent; text:"\u2190"; color:"white"; font.pixelSize:20; font.bold:true }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: screen=1 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: _curLesson ? _curLesson.title : ""
                                font.pixelSize: 16; font.bold: true; color: "white"
                            }
                            Text {
                                text: "\ud83d\udcdd L\u00e0m b\u00e0i t\u1eadp"
                                font.pixelSize: 11; color: Qt.rgba(1,1,1,0.7)
                            }
                        }
                    }
                }

                Item {
                    width: parent.width; height: parent.height - 66

                    // Quiz result (after completion)
                    Column {
                        anchors.centerIn: parent; spacing: 18
                        visible: qDone

                        Text { anchors.horizontalCenter:parent.horizontalCenter; text: prog[selLesson].qScore>=70?"\ud83c\udf89":"\ud83d\udcd6"; font.pixelSize:70 }
                        Text { anchors.horizontalCenter:parent.horizontalCenter; text:"\u0110i\u1ec3m b\u00e0i t\u1eadp: " + prog[selLesson].qScore + "%"; font.pixelSize:26; font.bold:true; color:cText }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 380; height: 50; radius: 14
                            color: prog[selLesson].qScore>=70 ? "#F0FDF4" : "#FFF7ED"
                            border.color: prog[selLesson].qScore>=70 ? "#BBF7D0" : "#FED7AA"; border.width:1
                            Text {
                                anchors.centerIn: parent
                                text: prog[selLesson].qScore>=70
                                    ? "T\u1ed1t l\u1eafm! H\u00e3y chuy\u1ec3n sang b\u00e0i r\u00e8n luy\u1ec7n!"
                                    : "C\u1ea7n \u00f4n th\u00eam. H\u00e3y \u0111\u1ecdc l\u1ea1i l\u00fd thuy\u1ebft tr\u01b0\u1edbc nh\u00e9!"
                                font.pixelSize: 14; color: cText
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                            Rectangle {
                                width: 176; height: 46; radius: 23; color: "#F1F5F9"
                                border.color: cBorder; border.width: 1
                                Text { anchors.centerIn:parent; text:"\ud83d\udd04 L\u00e0m l\u1ea1i"; font.pixelSize:13; color:cText }
                                property bool h: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: h ? 1.04 : 1.0
                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.h = true
                                    onExited: parent.h = false
                                    onClicked: { qStep=0; qHits=0; qDone=false; qAns=-1 }
                                }
                            }
                            Rectangle {
                                width: 176; height: 46; radius: 23
                                color: cPrimary
                                Text { anchors.centerIn:parent; text:"\u2190 Quay l\u1ea1i"; font.pixelSize:14; font.bold:true; color:"white" }
                                property bool h: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: h ? 1.04 : 1.0
                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.h = true
                                    onExited: parent.h = false
                                    onClicked: screen=1
                                }
                            }
                        }
                    }

                    // In-progress quiz
                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 56, 540)
                        spacing: 18; visible: !qDone

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                            Repeater {
                                model: _curLesson && _curLesson.quiz ? _curLesson.quiz.length : 0
                                delegate: Rectangle {
                                    width: index<=qStep ? 30 : 12; height: 10; radius: 5
                                    color: index<=qStep ? cPrimary : cBorder
                                    Behavior on width { NumberAnimation { duration:180 } }
                                    Behavior on color { PropertyAnimation { duration:180 } }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: _curLesson ? ("C\u00e2u " + (qStep+1) + " / " + (_curLesson.quiz ? _curLesson.quiz.length : 0)) : ""
                            font.pixelSize: 12; color: cMuted
                        }

                        Rectangle {
                            width: parent.width; height: qTxt.height + 32; radius: borderRadius
                            color: "#EFF6FF"; border.color: "#BFDBFE"; border.width: 1
                            Text {
                                id: qTxt
                                anchors { left:parent.left; right:parent.right; top:parent.top; margins:16 }
                                text: _curLesson && _curLesson.quiz ? _curLesson.quiz[qStep].question : ""
                                font.pixelSize:17; font.bold:true; color:cPrimary; wrapMode:Text.WordWrap
                            }
                        }

                        Repeater {
                            model: _curLesson && _curLesson.quiz ? _curLesson.quiz[qStep].options : 0
                            delegate: Rectangle {
                                id: qOpt
                                width:parent.width; height:50; radius:12
                                color: qAns===index ? cPrimary : cCard
                                border.color: qAns===index ? cPrimary : cBorder; border.width:2
                                Behavior on color { PropertyAnimation { duration: page.animFast } }

                                Row {
                                    anchors { left:parent.left; verticalCenter:parent.verticalCenter; leftMargin:16 }
                                    spacing:14
                                    Rectangle {
                                        width:22; height:22; radius:11
                                        border.color: qAns===index?"white":cGray; border.width:2
                                        color: qAns===index?"white":"transparent"
                                        anchors.verticalCenter:parent.verticalCenter
                                        Behavior on color { PropertyAnimation { duration: page.animFast } }
                                        Behavior on border.color { PropertyAnimation { duration: page.animFast } }
                                    }
                                    Text { text:modelData; font.pixelSize:15; color:qAns===index?"white":cText; anchors.verticalCenter:parent.verticalCenter }
                                }

                                property bool hovered: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: hovered && qAns!==index ? 1.015 : 1.0

                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: qOpt.hovered = true
                                    onExited: qOpt.hovered = false
                                    onClicked: qAns=index
                                }
                            }
                        }

                        Rectangle {
                            id: quizSubmitBtn
                            anchors.horizontalCenter: parent.horizontalCenter
                            width:200; height:46; radius:23; color: qAns>=0 ? cPrimary : "#CBD5E1"
                            Text { anchors.centerIn:parent; text:"X\u00e1c nh\u1eadn \u2192"; color:"white"; font.pixelSize:14; font.bold:true }
                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                            property bool hovered: false
                            scale: hovered && qAns>=0 ? 1.05 : 1.0
                            MouseArea {
                                anchors.fill:parent
                                hoverEnabled: true
                                onEntered: quizSubmitBtn.hovered = true
                                onExited: quizSubmitBtn.hovered = false
                                cursorShape: qAns>=0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: { if (qAns>=0) submitQuiz(qAns) }
                            }
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 4 — PRACTICE with Easy/Medium/Hard difficulty tabs
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 4

            Column {
                anchors.fill: parent; spacing: 0

                Rectangle {
                    width: parent.width; height: 66
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cAmber }
                        GradientStop { position: 1.0; color: "#FBBF24" }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        anchors.leftMargin: 18; spacing: 14
                        Rectangle {
                            width: 36; height: 36; radius: 10; color: Qt.rgba(1,1,1,0.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn:parent; text:"\u2190"; color:"white"; font.pixelSize:20; font.bold:true }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: screen=1 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: _curLesson ? _curLesson.title : ""
                                font.pixelSize: 16; font.bold: true; color: "white"
                            }
                            Text {
                                text: "\ud83c\udfcb\ufe0f R\u00e8n luy\u1ec7n"
                                font.pixelSize: 11; color: Qt.rgba(1,1,1,0.7)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 48
                    color: cCard
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: cBorder }

                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: [
                                { lbl:"D\u1ec5", ico:"\ud83d\udfe2", diff:"easy" },
                                { lbl:"Trung b\u00ecnh", ico:"\ud83d\udfe0", diff:"medium" },
                                { lbl:"N\u00e2ng cao", ico:"\ud83d\udd34", diff:"hard" }
                            ]
                            delegate: Item {
                                width: parent.width / 3; height: 48

                                property bool isLocked: {
                                    if (modelData.diff === "easy") return false
                                    if (modelData.diff === "medium") return !prog[selLesson].pEasy
                                    if (modelData.diff === "hard") return !prog[selLesson].pMed
                                    return true
                                }

                                property bool isDone: {
                                    if (modelData.diff === "easy") return prog[selLesson].pEasy
                                    if (modelData.diff === "medium") return prog[selLesson].pMed
                                    if (modelData.diff === "hard") return prog[selLesson].pHard
                                    return false
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width - 20; height: 3; radius: 1.5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: pDiff === modelData.diff ? cPrimary : "transparent"
                                    Behavior on color { PropertyAnimation { duration: page.animNorm } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: isDone ? "\u2705 " : (isLocked ? "\ud83d\udd12 " : "") + modelData.ico + " " + modelData.lbl
                                    font.pixelSize: 13; font.bold: pDiff === modelData.diff
                                    color: isLocked ? "#CBD5E1" : (pDiff === modelData.diff ? cText : cMuted)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: isLocked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                                    onClicked: {
                                        if (!isLocked && pDiff !== modelData.diff) {
                                            pDiff = modelData.diff
                                            pStep = 0; pHits = 0; pDone = false; pAns = -1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width; height: parent.height - 66 - 48

                    // Lock overlay for locked difficulty
                    Column {
                        anchors.centerIn: parent; spacing: 18
                        visible: isPLocked(pDiff)
                        Text { anchors.horizontalCenter:parent.horizontalCenter; text:"\ud83d\udd12"; font.pixelSize:60 }
                        Text {
                            anchors.horizontalCenter:parent.horizontalCenter
                            text: {
                                if (pDiff === "medium") return "Ho\u00e0n th\u00e0nh m\u1ee9c D\u1ec5 tr\u01b0\u1edbc!"
                                if (pDiff === "hard") return "Ho\u00e0n th\u00e0nh m\u1ee9c Trung b\u00ecnh tr\u01b0\u1edbc!"
                                return ""
                            }
                            font.pixelSize:17; font.bold:true; color:cText
                        }
                    }

                    // Practice interface
                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 56, 540)
                        spacing: 18; visible: !pDone && !isPLocked(pDiff)

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                            Repeater {
                                model: getPracticeTotal()
                                delegate: Rectangle {
                                    width: index<=pStep ? 26 : 12; height: 10; radius: 5
                                    color: index<=pStep ? cAmber : cBorder
                                    Behavior on width { NumberAnimation { duration:180 } }
                                    Behavior on color { PropertyAnimation { duration:180 } }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\ud83c\udfcb\ufe0f  C\u00e2u " + (pStep+1) + " / " + getPracticeTotal()
                            font.pixelSize: 12; color: cMuted
                        }

                        Rectangle {
                            width: parent.width; height: pTxt.height + 32; radius: borderRadius
                            color: "#FFFBED"; border.color: "#FDE68A"; border.width: 1
                            Text {
                                id: pTxt
                                anchors { left:parent.left; right:parent.right; top:parent.top; margins:16 }
                                text: {
                                    var practice = getPracticeByDiff(pDiff)
                                    return practice.length > 0 ? practice[pStep].question : ""
                                }
                                font.pixelSize:17; font.bold:true; color:cAmber; wrapMode:Text.WordWrap
                            }
                        }

                        Repeater {
                            model: {
                                var practice = getPracticeByDiff(pDiff)
                                return practice.length > 0 ? practice[pStep].options : 0
                            }
                            delegate: Rectangle {
                                id: pOpt
                                width:parent.width; height:50; radius:12
                                color: pAns===index ? cAmber : cCard
                                border.color: pAns===index ? cAmber : cBorder; border.width:2
                                Behavior on color { PropertyAnimation { duration: page.animFast } }

                                Row {
                                    anchors { left:parent.left; verticalCenter:parent.verticalCenter; leftMargin:16 }
                                    spacing:14
                                    Rectangle {
                                        width:22; height:22; radius:11
                                        border.color: pAns===index?"white":cGray; border.width:2
                                        color: pAns===index?"white":"transparent"
                                        anchors.verticalCenter:parent.verticalCenter
                                        Behavior on color { PropertyAnimation { duration: page.animFast } }
                                        Behavior on border.color { PropertyAnimation { duration: page.animFast } }
                                    }
                                    Text { text:modelData; font.pixelSize:15; color:pAns===index?"white":cText; anchors.verticalCenter:parent.verticalCenter }
                                }

                                property bool hovered: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: hovered && pAns!==index ? 1.015 : 1.0

                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: pOpt.hovered = true
                                    onExited: pOpt.hovered = false
                                    onClicked: pAns=index
                                }
                            }
                        }

                        Rectangle {
                            id: pracSubmitBtn
                            anchors.horizontalCenter: parent.horizontalCenter
                            width:200; height:46; radius:23; color: pAns>=0 ? cAmber : "#CBD5E1"
                            Text { anchors.centerIn:parent; text:"X\u00e1c nh\u1eadn \u2192"; color:"white"; font.pixelSize:14; font.bold:true }
                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                            property bool hovered: false
                            scale: hovered && pAns>=0 ? 1.05 : 1.0
                            MouseArea {
                                anchors.fill:parent
                                hoverEnabled: true
                                onEntered: pracSubmitBtn.hovered = true
                                onExited: pracSubmitBtn.hovered = false
                                cursorShape: pAns>=0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: { if (pAns>=0) submitPractice(pAns) }
                            }
                        }
                    }

                    // Practice result
                    Column {
                        anchors.centerIn: parent; spacing: 18
                        visible: pDone

                        Text { anchors.horizontalCenter:parent.horizontalCenter; text: pHits >= Math.ceil(getPracticeTotal()*0.7)?"\ud83c\udfc6":"\ud83d\udcda"; font.pixelSize:70 }
                        Text { anchors.horizontalCenter:parent.horizontalCenter; text:"\u0110i\u1ec3m: " + Math.round(pHits / Math.max(1,getPracticeTotal())*100) + "%"; font.pixelSize:26; font.bold:true; color:cText }
                        Text {
                            anchors.horizontalCenter:parent.horizontalCenter
                            text: "\u0110\u00e3 ho\u00e0n th\u00e0nh m\u1ee9c " + (pDiff==="easy"?"D\u1ec5":pDiff==="medium"?"Trung b\u00ecnh":"N\u00e2ng cao")
                            font.pixelSize:14; color:cMuted
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 400; height: 50; radius:14
                            color: pHits >= Math.ceil(getPracticeTotal()*0.7)?"#F0FDF4":"#FFF7ED"
                            border.color: pHits >= Math.ceil(getPracticeTotal()*0.7)?"#BBF7D0":"#FED7AA"; border.width:1
                            Text {
                                anchors.centerIn: parent
                                text: pHits >= Math.ceil(getPracticeTotal()*0.7)
                                    ? "Xu\u1ea5t s\u1eafc! H\u00e3y ti\u1ebfp t\u1ee5c luy\u1ec7n \u1edf c\u1ea5p \u0111\u1ed9 kh\u00e1c!"
                                    : "C\u1ea7n c\u1ed1 g\u1eafng th\u00eam. \u00d4n l\u1ea1i l\u00fd thuy\u1ebft nh\u00e9!"
                                font.pixelSize:14; color:cText
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                            Rectangle {
                                width: 200; height: 46; radius: 23; color: "#F1F5F9"
                                border.color: cBorder; border.width: 1
                                Text { anchors.centerIn:parent; text:"\ud83d\udd04 Luy\u1ec7n l\u1ea1i"; font.pixelSize:13; color:cText }
                                property bool h: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: h ? 1.04 : 1.0
                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.h = true
                                    onExited: parent.h = false
                                    onClicked: { pStep=0; pHits=0; pDone=false; pAns=-1 }
                                }
                            }
                            Rectangle {
                                width: 176; height: 46; radius: 23
                                color: cAmber
                                Text { anchors.centerIn:parent; text:"\u2190 Quay l\u1ea1i"; font.pixelSize:14; font.bold:true; color:"white" }
                                property bool h: false
                                Behavior on scale { NumberAnimation { duration: page.animFast } }
                                scale: h ? 1.04 : 1.0
                                MouseArea {
                                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: parent.h = true
                                    onExited: parent.h = false
                                    onClicked: screen=1
                                }
                            }
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // SCREEN 5 — ACHIEVEMENT (enhanced stats)
        // ══════════════════════════════════════════════════════════════════════
        ScreenTransition {
            anchors.fill: parent
            show: screen === 5

            Item {
                anchors.fill: parent

                Rectangle {
                    id: achHeader
                    anchors.top: parent.top; width: parent.width; height: 66
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cGreen }
                        GradientStop { position: 1.0; color: cGreenLight }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        anchors.leftMargin: 18; spacing: 14
                        Rectangle {
                            width: 36; height: 36; radius: 10; color: Qt.rgba(1,1,1,0.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn:parent; text:"\u2190"; color:"white"; font.pixelSize:20; font.bold:true }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: screen=0 }
                        }
                        Text { text:"\ud83c\udfc6 Th\u00e0nh t\u00edch"; font.pixelSize:19; font.bold:true; color:"white"; anchors.verticalCenter:parent.verticalCenter }
                    }
                }

                ScrollView {
                    anchors.top: achHeader.bottom; anchors.bottom: parent.bottom
                    width: parent.width
                    contentWidth: availableWidth; clip: true

                    Column {
                        width: parent.width; spacing: 0
                        Item { width:1; height:28 }

                        // Overall grade selector
                        Row {
                            x: 26; width: parent.width - 52; spacing: 8
                            Repeater {
                                model: grades
                                delegate: Rectangle {
                                    width: (parent.width - (grades.length-1)*8) / grades.length
                                    height: 34; radius: borderRadius
                                    color: selGrade === index ? cGreen : "#F1F5F9"
                                    border.color: selGrade === index ? cGreen : cBorder; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11; font.bold: selGrade===index
                                        color: selGrade===index ? "white" : cText
                                    }
                                    property bool gh: false
                                    Behavior on scale { NumberAnimation { duration: page.animFast } }
                                    scale: gh ? 1.04 : 1.0
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onEntered: parent.gh = true
                                        onExited: parent.gh = false
                                        onClicked: {
                                            var oldIdx = selGrade;
                                            selGrade = index;
                                            buildLessonsForGrade(grades[index], oldIdx);
                                        }
                                    }
                                }
                            }
                        }

                        Item { width:1; height:24 }

                        // Trophy
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                var a = allLessonsScore()
                                if (completedLessons() === 0) return "\ud83d\udca4"
                                if (a >= 80) return "\ud83c\udfc6"
                                if (a >= 60) return "\ud83e\udd47"
                                return "\ud83d\udcd6"
                            }
                            font.pixelSize: 72
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                var n = completedLessons()
                                var t = currentLessons.length
                                if (n === 0) return "Ch\u01b0a c\u00f3 b\u00e0i h\u1ecdc n\u00e0o ho\u00e0n th\u00e0nh"
                                if (n === t) return "\u0110\u00e3 ho\u00e0n th\u00e0nh t\u1ea5t c\u1ea3 " + t + " b\u00e0i! Xu\u1ea5t s\u1eafc!"
                                return "\u0110\u00e3 ho\u00e0n th\u00e0nh " + n + "/" + t + " b\u00e0i h\u1ecdc"
                            }
                            font.pixelSize: 18; font.bold: true; color: cText
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item { width:1; height:20 }

                        // Progress bar (overall)
                        Rectangle {
                            x: 26; width: parent.width - 52; height: 18; radius: 9
                            color: cBorder
                            Rectangle {
                                width: parent.width * (currentLessons.length > 0 ? completedLessons() / currentLessons.length : 0)
                                height: 18; radius: 9
                                color: cGreen
                                Behavior on width { NumberAnimation { duration:700; easing.type:Easing.OutCubic } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: Math.round(currentLessons.length > 0 ? completedLessons() / currentLessons.length * 100 : 0) + "%"
                                font.pixelSize: 11; font.bold: true; color: "white"
                            }
                        }

                        Item { width:1; height:24 }

                        // Score cards grid
                        Text {
                            x: 26
                            text: "\ud83d\udcca Chi ti\u1ebft t\u1eebng b\u00e0i"
                            font.pixelSize: 15; font.bold: true; color: cText
                        }

                        Item { width:1; height:14 }

                        Repeater {
                            model: currentLessons
                            delegate: Rectangle {
                                x: 26; width: parent.width - 52
                                height: 100; radius: borderRadius
                                color: cCard; border.color: cBorder; border.width: 1
                                visible: prog[index].done

                                Rectangle {
                                    y: 16; x: 0
                                    width: 5; height: 68; radius: 3
                                    color: {
                                        var q = prog[index].qScore
                                        if (q >= 80) return cGreen
                                        if (q >= 60) return cAmber
                                        return cRed
                                    }
                                }

                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 16

                                    Rectangle {
                                        width: 48; height: 48; radius: 16
                                        color: "#F0FDF4"
                                        Text { anchors.centerIn: parent; text: modelData.emoji; font.pixelSize: 22 }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                        Text { text: modelData.title; font.pixelSize: 14; font.bold: true; color: cText }
                                        Text { text: modelData.sub; font.pixelSize: 11; color: cMuted }
                                    }
                                }

                                Column {
                                    anchors.right: parent.right; anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 4

                                    Text {
                                        text: prog[index].qScore + "%"
                                        font.pixelSize: 20; font.bold: true
                                        color: prog[index].qScore >= 80 ? cGreen : prog[index].qScore >= 60 ? cAmber : cRed
                                    }

                                    Row {
                                        spacing: 4
                                        Text { text:"\ud83c\udfcb\ufe0f " + (prog[index].pEasy?"\u2705":"\u274c"); font.pixelSize: 11; color: prog[index].pEasy?cGreen:cRed }
                                        Text { text:"\ud83c\udfcb\ufe0f " + (prog[index].pMed?"\u2705":"\u274c"); font.pixelSize: 11; color: prog[index].pMed?cGreen:cRed }
                                        Text { text:"\ud83c\udfcb\ufe0f " + (prog[index].pHard?"\u2705":"\u274c"); font.pixelSize: 11; color: prog[index].pHard?cGreen:cRed }
                                    }
                                }
                            }
                        }

                        // Best & worst analysis
                        Item { width:1; height:20 }

                        Rectangle {
                            x: 26; width: parent.width - 52
                            height: 80; radius: borderRadius
                            color: "#F0FDF4"; border.color: "#BBF7D0"; border.width: 1
                            visible: completedLessons() > 0

                            Row {
                                anchors.centerIn: parent; spacing: 24
                                Column {
                                    spacing: 4
                                    Text { text:"\u2b06 T\u1ed1t nh\u1ea5t"; font.pixelSize: 12; color:cGreen; font.bold:true }
                                    Text { text: bestLesson() ? bestLesson().title : ""; font.pixelSize: 13; color: cText }
                                }
                                Rectangle { width:1; height:40; color: "#BBF7D0" }
                                Column {
                                    spacing: 4
                                    Text { text:"\u2b07 C\u1ea7n c\u1ea3i thi\u1ec7n"; font.pixelSize: 12; color:cRed; font.bold:true }
                                    Text { text: worstLesson() ? worstLesson().title : ""; font.pixelSize: 13; color: cText }
                                }
                            }
                        }

                        Item { width:1; height:24 }

                        // Motivation message
                        Rectangle {
                            x: 26; width: parent.width - 52
                            height: motTxt.height + 32; radius: borderRadius
                            color: "#F8FAFC"; border.color: cBorder; border.width: 1

                            Text {
                                id: motTxt
                                anchors { left:parent.left; right:parent.right; top:parent.top; margins:16 }
                                text: {
                                    var n = completedLessons()
                                    var a = allLessonsScore()
                                    if (n === 0) return "\ud83d\ude80 H\u00e3y b\u1eaft \u0111\u1ea7u h\u1ecdc b\u00e0i \u0111\u1ea7u ti\u00ean \u0111\u1ec3 xem th\u00e0nh t\u00edch c\u1ee7a b\u1ea1n!"
                                    if (n === currentLessons.length && a >= 80) return "\ud83c\udf1f Ch\u00fac m\u1eebng! B\u1ea1n \u0111\u00e3 ho\u00e0n th\u00e0nh xu\u1ea5t s\u1eafc t\u1ea5t c\u1ea3 b\u00e0i h\u1ecdc! H\u00e3y th\u1eed th\u00e1ch b\u1ea3n th\u00e2n v\u1edbi c\u00e1c l\u1edbp kh\u00e1c!"
                                    if (n === currentLessons.length) return "\ud83c\udf93 B\u1ea1n \u0111\u00e3 ho\u00e0n th\u00e0nh t\u1ea5t c\u1ea3 b\u00e0i h\u1ecdc! H\u00e3y xem l\u1ea1i c\u00e1c b\u00e0i c\u1ea7n c\u1ea3i thi\u1ec7n \u0111\u1ec3 \u0111\u1ea1t \u0111i\u1ec3m cao h\u01a1n."
                                    if (a >= 70) return "\ud83d\udcaa B\u1ea1n \u0111ang \u0111i \u0111\u00fang h\u01b0\u1edbng! H\u00e3y ti\u1ebfp t\u1ee5c duy tr\u00ec phong \u0111\u1ed9 n\u00e0y."
                                    return "\ud83d\udca1 G\u1ee3i \u00fd: \u0110\u1ecdc l\u1ea1i l\u00fd thuy\u1ebft v\u00e0 l\u00e0m th\u00eam b\u00e0i t\u1eadp \u0111\u1ec3 c\u1ea3i thi\u1ec7n \u0111i\u1ec3m s\u1ed1."
                                }
                                font.pixelSize: 14; color: cText; wrapMode: Text.WordWrap; lineHeight: 1.5
                            }
                        }

                        // Action: switch grade
                        Item { width:1; height:20 }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 260; height: 48; radius: 24; color: cGreen
                            visible: completedLessons() > 0
                            Text { anchors.centerIn:parent; text:"\ud83d\udcda Ch\u1ecdn l\u1edbp kh\u00e1c \u0111\u1ec3 h\u1ecdc ti\u1ebfp"; font.pixelSize:13; font.bold:true; color:"white" }
                            property bool h: false
                            Behavior on scale { NumberAnimation { duration: page.animFast } }
                            scale: h ? 1.04 : 1.0
                            MouseArea {
                                anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.h = true
                                onExited: parent.h = false
                                onClicked: {
                                    screen = 0
                                    if (grades.length > 0 && selGrade + 1 < grades.length) {
                                        var oldIdx = selGrade;
                                        selGrade++;
                                        buildLessonsForGrade(grades[selGrade], oldIdx);
                                    }
                                }
                            }
                        }

                        Item { width:1; height:32 }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // CONGRATULATIONS OVERLAY
        // ══════════════════════════════════════════════════════════════════════
        Rectangle {
            id: congratsOverlay
            anchors.fill: parent; color: "#A0000000"
            visible: false; z: 999
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: page.animNorm; easing.type: Easing.OutCubic } }

            property bool isFinal: false

            onVisibleChanged: {
                if (visible) { opacity = 1; popupAnim.restart() }
                else { opacity = 0 }
            }

            MouseArea { anchors.fill: parent }

            Rectangle {
                id: congratsDialog
                anchors.centerIn: parent
                width: 460; height: 380; radius: 26; color: cCard
                clip: true
                scale: 0.85
                opacity: 0

                SequentialAnimation {
                    id: popupAnim
                    ParallelAnimation {
                        NumberAnimation { target: congratsDialog; property: "scale"; from: 0.7; to: 1.0; duration: 400; easing.type: Easing.OutBack }
                        NumberAnimation { target: congratsDialog; property: "opacity"; from: 0; to: 1; duration: 300 }
                    }
                }

                Rectangle {
                    width: parent.width; height: 140; radius: 26
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cGreen }
                        GradientStop { position: 1.0; color: cGreenLight }
                    }
                    Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:26; color:cGreen }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text { anchors.horizontalCenter:parent.horizontalCenter; text: congratsOverlay.isFinal?"\ud83c\udf93":"\ud83c\udf89"; font.pixelSize:60 }
                    }
                }

                Column {
                    anchors.top: parent.top; anchors.topMargin: 152
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 400; spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: congratsOverlay.isFinal
                            ? "Ch\u00fac m\u1eebng! Ho\u00e0n th\u00e0nh xu\u1ea5t s\u1eafc! \ud83c\udf1f"
                            : "B\u00e0i h\u1ecdc ti\u1ebfp theo \u0111\u00e3 m\u1edf kh\u00f3a! \ud83d\udd13"
                        font.pixelSize: 23; font.bold: true; color: cText
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; width: parent.width
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: congratsOverlay.isFinal
                            ? "B\u1ea1n \u0111\u00e3 ho\u00e0n th\u00e0nh c\u1ea3 " + currentLessons.length + " b\u00e0i h\u1ecdc To\u00e1n!\nCh\u00fac b\u1ea1n h\u1ecdc t\u1ed1t v\u00e0 th\u00e0nh c\u00f4ng! \ud83c\udf40"
                            : "Ti\u1ebfp t\u1ee5c duy tr\u00ec tinh th\u1ea7n h\u1ecdc t\u1eadp tuy\u1ec7t v\u1eddi!\nB\u00e0i " + (selLesson + 2) + " \u0111ang ch\u1edd b\u1ea1n ph\u00eda tr\u01b0\u1edbc! \ud83d\udcaa"
                        font.pixelSize: 14; color: cMuted
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; width: parent.width
                    }
                    Item { width:1; height:4 }
                    Rectangle {
                        id: congratsBtn
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 240; height: 48; radius: 24; color: cGreen
                        Text { anchors.centerIn:parent; text: congratsOverlay.isFinal?"\ud83c\udfe0 V\u1ec1 trang ch\u1ee7":"Ti\u1ebfp t\u1ee5c h\u1ecdc \u2192"; font.pixelSize:15; font.bold:true; color:"white" }
                        property bool hovered: false
                        Behavior on scale { NumberAnimation { duration: page.animFast } }
                        scale: hovered ? 1.04 : 1.0
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: congratsBtn.hovered = true
                            onExited: congratsBtn.hovered = false
                            onClicked: {
                                var goHome = congratsOverlay.isFinal
                                congratsOverlay.visible = false
                                congratsOverlay.isFinal = false
                                screen = goHome ? 0 : 1
                            }
                        }
                    }
                }
            }
        }

    }
}
