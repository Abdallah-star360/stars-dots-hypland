import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    anchors.fill: parent

    property var allApps: []
    property var customCats: []
    property string currentCat: "All"
    property string searchText: ""
    property bool editMode: false
    property bool gridView: false
    property bool loading: true
    property string appsBuffer: ""
    property string customBuf: ""
    property string savePath: "/home/stars/.config/quickshell/ii/scripts/appmenu_custom.json"

    ListModel { id: appsModel }

    property var catNames: ({
        "All": "الكل", "AudioVideo": "الصوت والفيديو",
        "Development": "التطوير", "Education": "التعليم",
        "Game": "الألعاب", "Graphics": "الجرافيكس",
        "Network": "الإنترنت", "Office": "المكتب",
        "Settings": "الإعدادات", "System": "النظام",
        "Utility": "الأدوات", "Science": "العلوم",
        "Other": "أخرى"
    })

    property var catIcons: ({
        "All": "apps", "AudioVideo": "music_note",
        "Development": "code", "Education": "school",
        "Game": "sports_esports", "Graphics": "brush",
        "Network": "wifi", "Office": "description",
        "Settings": "settings", "System": "terminal",
        "Utility": "build", "Science": "science",
        "Other": "folder"
    })

    property var knownCats: ["AudioVideo","Development","Education","Game","Graphics","Network","Office","Settings","System","Utility","Science"]

    // ====================================================
    // FIX 1: Process منفصل لفتح التطبيقات بشكل صح
    // ====================================================
    Process {
        id: launchProcess
        property string execCmd: ""
        command: ["bash", "-c", launchProcess.execCmd]
        running: false
    }

    function launchApp(execStr) {
        // تنظيف الـ exec من placeholder arguments
        let cmd = execStr.replace(/%[uUfFdDnNickvm]/g, "").trim()
        launchProcess.execCmd = cmd
        launchProcess.running = true
    }

    Timer {
        id: searchTimer
        interval: 250
        onTriggered: updateModel()
    }

    onSearchTextChanged: searchTimer.restart()
    onCurrentCatChanged: updateModel()

    function updateModel() {
        if (allApps.length === 0) return
        let source = currentCat === "All" ? allApps : allApps.filter(a => a.cat === currentCat)
        if (searchText) {
            let lower = searchText.toLowerCase()
            source = source.filter(a => a.name.toLowerCase().includes(lower))
        }
        appsModel.clear()
        for (let app of source) appsModel.append(app)
    }

    function getAllCats() {
        let used = new Set(allApps.map(a => a.cat))
        let cats = ["All"]
        for (let c of knownCats) if (used.has(c)) cats.push(c)
        for (let c of customCats) cats.push(c)
        if (used.has("Other") && !cats.includes("Other")) cats.push("Other")
        return cats
    }

    function getCatName(cat) { return catNames[cat] || cat }
    function getCatIcon(cat) { return catIcons[cat] || "folder" }

    function moveAppTo(app, newCat) {
        for (let a of allApps) if (a.exec === app.exec) { a.cat = newCat; break }
        allAppsChanged()
        updateModel()
        saveData()
    }

    Process {
        id: appsProcess
        command: ["bash", "-c",
            "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | while read f; do " +
            "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "exec_line=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ *%[uUfFdDnNickvm]//g' | xargs); " +
            "icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2-); " +
            "type=$(grep -m1 '^Type=' \"$f\" | cut -d= -f2-); " +
            "cats=$(grep -m1 '^Categories=' \"$f\" | cut -d= -f2-); " +
            "if [ \"$type\" = \"Application\" ] && [ \"$nodisplay\" != \"true\" ] && [ -n \"$name\" ] && [ -n \"$exec_line\" ]; then " +
            "cat=Other; " +
            "for c in AudioVideo Development Education Game Graphics Network Office Settings System Utility Science; do " +
            "if echo \"$cats\" | grep -q \"$c\"; then cat=$c; break; fi; done; " +
            "printf '%s|%s|%s|%s\\n' \"$name\" \"$exec_line\" \"$icon\" \"$cat\"; " +
            "fi; done | sort -t'|' -k1,1"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.appsBuffer += data + "\n"
                let lines = root.appsBuffer.split("\n")
                root.appsBuffer = lines.pop()
                for (let line of lines) {
                    if (!line.trim()) continue
                    let parts = line.split("|")
                    if (parts.length >= 4 && parts[0] && parts[1]) {
                        root.allApps.push({
                            name: parts[0], exec: parts[1],
                            icon: parts[2] || "", cat: parts[3] || "Other"
                        })
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.allAppsChanged()
                root.loading = false
                loadCustomProcess.running = true
                updateModel()
            }
        }
    }

    Process {
        id: loadCustomProcess
        command: ["bash", "-c", "cat \"" + root.savePath + "\" 2>/dev/null || echo '{}'"]
        running: false
        stdout: SplitParser {
            onRead: data => root.customBuf += data
        }
        onRunningChanged: {
            if (!running) {
                try {
                    let d = JSON.parse(root.customBuf || "{}")
                    root.customCats = d.customCats || []
                    if (d.appCats) {
                        for (let app of root.allApps) {
                            if (d.appCats[app.exec]) app.cat = d.appCats[app.exec]
                        }
                        root.allAppsChanged()
                        updateModel()
                    }
                } catch(e) {}
                root.customBuf = ""
            }
        }
    }

    // ====================================================
    // FIX 2: الحفظ عن طريق ملف مؤقت بدل تمرير JSON في command
    // ====================================================
    property string tempSavePath: "/tmp/appmenu_save.json"

    FileView {
        id: saveFileView
        path: root.tempSavePath
        blockAllReads: true
    }

    function saveData() {
        let appCats = {}
        for (let app of allApps) appCats[app.exec] = app.cat
        let jsonStr = JSON.stringify({ customCats: root.customCats, appCats: appCats }, null, 2)
        // اكتب الـ JSON في ملف مؤقت الأول
        saveTempProcess.jsonContent = jsonStr
        saveTempProcess.running = true
    }

    Process {
        id: saveTempProcess
        property string jsonContent: ""
        // استخدام printf بدل echo عشان يتعامل مع الـ special characters صح
        command: ["bash", "-c",
            "printf '%s' \"$JSON_DATA\" > \"" + root.tempSavePath + "\" && " +
            "mkdir -p \"$(dirname '" + root.savePath + "')\" && " +
            "cp \"" + root.tempSavePath + "\" \"" + root.savePath + "\""
        ]
        environment: ({"JSON_DATA": saveTempProcess.jsonContent})
        running: false
    }

    // ====================================================
    // FIX 3: متغير للـ drag منفصل عن الـ view
    // ====================================================
    property var draggedApp: null
    property bool isDragging: false
    property point dragPos: Qt.point(0, 0)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Search + buttons row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8
                    MaterialSymbol { text: "search"; iconSize: Appearance.font.pixelSize.large; color: Appearance.colors.colOnSurfaceVariant }
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "ابحث..."
                        background: null
                        color: Appearance.colors.colOnLayer1
                        placeholderTextColor: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        onTextChanged: root.searchText = text
                    }
                    MaterialSymbol {
                        visible: searchField.text.length > 0
                        text: "close"; iconSize: 16; color: Appearance.colors.colOnSurfaceVariant
                        MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                    }
                }
            }

            RippleButton {
                implicitWidth: 36; implicitHeight: 36; buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer2
                onClicked: root.gridView = !root.gridView
                MaterialSymbol { anchors.centerIn: parent; text: root.gridView ? "view_list" : "grid_view"; iconSize: 18; color: Appearance.colors.colOnSurfaceVariant }
            }

            RippleButton {
                implicitWidth: 36; implicitHeight: 36; buttonRadius: Appearance.rounding.full
                colBackground: root.editMode ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                onClicked: root.editMode = !root.editMode
                MaterialSymbol { anchors.centerIn: parent; text: root.editMode ? "check" : "edit"; iconSize: 18; color: root.editMode ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant }
            }
        }

        // Tabs row
        Item {
            Layout.fillWidth: true
            implicitHeight: 34

            Flickable {
                id: tabsFlickable
                anchors.fill: parent
                contentWidth: tabsRow.implicitWidth
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                clip: true

                WheelHandler {
                    onWheel: event => {
                        tabsFlickable.contentX = Math.max(0,
                            Math.min(tabsFlickable.contentWidth - tabsFlickable.width,
                                tabsFlickable.contentX - event.angleDelta.y * 0.5))
                    }
                }

                Row {
                    id: tabsRow
                    spacing: 4
                    height: parent.height

                    Repeater {
                        model: root.getAllCats()
                        delegate: Item {
                            required property string modelData
                            height: 34
                            width: tabBtn.implicitWidth + (root.editMode && root.customCats.includes(modelData) ? 26 : 0)

                            RippleButton {
                                id: tabBtn
                                property bool active: root.currentCat === modelData
                                implicitHeight: 30
                                implicitWidth: tabInner.implicitWidth + 16
                                anchors.verticalCenter: parent.verticalCenter
                                buttonRadius: Appearance.rounding.full
                                colBackground: active ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                colBackgroundHover: active ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                                onClicked: root.currentCat = modelData

                                RowLayout {
                                    id: tabInner
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol { text: root.getCatIcon(modelData); iconSize: 13; color: tabBtn.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant }
                                    StyledText { text: root.getCatName(modelData); color: tabBtn.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.small }
                                }
                            }

                            RippleButton {
                                visible: root.editMode && root.customCats.includes(modelData)
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 22; implicitHeight: 22
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colError
                                onClicked: {
                                    let idx = root.customCats.indexOf(modelData)
                                    if (idx >= 0) {
                                        for (let a of root.allApps) if (a.cat === modelData) a.cat = "Other"
                                        root.customCats.splice(idx, 1)
                                        root.customCatsChanged()
                                        root.allAppsChanged()
                                        updateModel()
                                        if (root.currentCat === modelData) root.currentCat = "All"
                                        saveData()
                                    }
                                }
                                MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 11; color: Appearance.colors.colOnError }
                            }
                        }
                    }

                    RippleButton {
                        visible: root.editMode
                        implicitWidth: 30; implicitHeight: 30
                        anchors.verticalCenter: parent.verticalCenter
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        onClicked: newCatDialog.open()
                        MaterialSymbol { anchors.centerIn: parent; text: "add"; iconSize: 18; color: Appearance.colors.colPrimary }
                    }
                }
            }
        }

        // Apps area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            clip: true

            // Loading indicator
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.loading
                spacing: 10
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "sync"; iconSize: 32; color: Appearance.colors.colPrimary
                    NumberAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: root.loading }
                }
                StyledText { text: root.allApps.length + " تطبيق..."; color: Appearance.colors.colOnSurfaceVariant }
            }

            // Drop zone
            Rectangle {
                id: dropZone
                visible: root.editMode && root.isDragging
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
                height: 44
                radius: Appearance.rounding.small
                color: dropArea.containsDrag ? Qt.rgba(
                    Appearance.colors.colPrimary.r,
                    Appearance.colors.colPrimary.g,
                    Appearance.colors.colPrimary.b, 0.15)
                    : "transparent"
                border.width: 2
                border.color: Appearance.colors.colPrimary
                opacity: 0.9
                z: 10

                StyledText {
                    anchors.centerIn: parent
                    text: "افلت هنا لتغيير القسم"
                    color: Appearance.colors.colPrimary
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                // ====================================================
                // FIX 4: MouseArea بسيطة للـ drop بدل DropArea
                // ====================================================
                MouseArea {
                    anchors.fill: parent
                    onReleased: {
                        if (root.draggedApp) {
                            moveTargetDialog.app = root.draggedApp
                            moveTargetDialog.open()
                        }
                        root.draggedApp = null
                        root.isDragging = false
                    }
                }
            }

            ListView {
                id: listView
                anchors { fill: parent; margins: 4; bottomMargin: (root.editMode && root.isDragging) ? 56 : 4 }
                visible: !root.gridView && !root.loading
                model: appsModel
                spacing: 2
                clip: true
                delegate: AppDelegate { width: listView.width; isGrid: false }
            }

            GridView {
                id: gridViewComp
                anchors { fill: parent; margins: 4; bottomMargin: (root.editMode && root.isDragging) ? 56 : 4 }
                visible: root.gridView && !root.loading
                model: appsModel
                cellWidth: width / 3
                cellHeight: 80
                clip: true
                delegate: AppDelegate { width: gridViewComp.cellWidth; height: gridViewComp.cellHeight; isGrid: true }
            }
        }

        StyledText {
            text: root.loading
                ? ("جاري التحميل... " + root.allApps.length)
                : root.editMode
                    ? (root.isDragging ? "افلت على المنطقة الزرقاء..." : "اسحب أو اضغط يمين لنقل التطبيق")
                    : (appsModel.count + " تطبيق")
            color: root.editMode ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    // ====================================================
    // FIX 5: AppDelegate المصلح - فصل الـ click عن الـ drag
    // ====================================================
    component AppDelegate: Item {
        required property var modelData
        property bool isGrid: false
        implicitHeight: isGrid ? 80 : 44

        // الخلفية والـ hover effect
        Rectangle {
            id: delegateBg
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: "transparent"

            states: [
                State {
                    name: "hovered"
                    when: delegateMouse.containsMouse && !delegateMouse.pressed
                    PropertyChanges { target: delegateBg; color: Qt.rgba(
                        Appearance.colors.colOnLayer1.r,
                        Appearance.colors.colOnLayer1.g,
                        Appearance.colors.colOnLayer1.b, 0.06) }
                },
                State {
                    name: "pressed"
                    when: delegateMouse.pressed
                    PropertyChanges { target: delegateBg; color: Qt.rgba(
                        Appearance.colors.colOnLayer1.r,
                        Appearance.colors.colOnLayer1.g,
                        Appearance.colors.colOnLayer1.b, 0.12) }
                }
            ]
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        MouseArea {
            id: delegateMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            // متغيرات للـ drag
            property point pressPos: Qt.point(0, 0)
            property bool dragStarted: false

            onPressed: event => {
                pressPos = Qt.point(event.x, event.y)
                dragStarted = false
                if (root.editMode && event.button === Qt.LeftButton) {
                    root.draggedApp = modelData
                }
            }

            onPositionChanged: event => {
                if (root.editMode && root.draggedApp) {
                    let dx = event.x - pressPos.x
                    let dy = event.y - pressPos.y
                    if (Math.sqrt(dx*dx + dy*dy) > 8) {
                        dragStarted = true
                        root.isDragging = true
                    }
                }
            }

            onReleased: event => {
                if (!dragStarted) {
                    // كان click مش drag
                    if (event.button === Qt.RightButton && root.editMode) {
                        moveTargetDialog.app = modelData
                        moveTargetDialog.open()
                    } else if (event.button === Qt.LeftButton && !root.editMode) {
                        // FIX 1: استخدام launchApp بدل Quickshell.execDetached
                        GlobalStates.sidebarLeftOpen = false
                        root.launchApp(modelData.exec)
                    }
                }
                if (!moveTargetDialog.visible) {
                    root.draggedApp = null
                    root.isDragging = false
                }
                dragStarted = false
            }
        }

        // List view content
        RowLayout {
            visible: !isGrid
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10
            Item {
                implicitWidth: 26; implicitHeight: 26; Layout.alignment: Qt.AlignVCenter
                Image { id: li; anchors.fill: parent; source: modelData.icon.startsWith("/") ? modelData.icon : ("image://icon/" + modelData.icon); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                MaterialSymbol { anchors.centerIn: parent; visible: !li.visible; text: "apps"; iconSize: 20; color: Appearance.colors.colOnSurfaceVariant }
            }
            StyledText { Layout.fillWidth: true; text: modelData.name; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.normal; elide: Text.ElideRight }
            StyledText { visible: root.editMode; text: root.getCatName(modelData.cat); color: Appearance.colors.colPrimary; font.pixelSize: 10 }
        }

        // Grid view content
        ColumnLayout {
            visible: isGrid
            anchors.centerIn: parent
            spacing: 4
            Item {
                implicitWidth: 36; implicitHeight: 36; Layout.alignment: Qt.AlignHCenter
                Image { id: gi; anchors.fill: parent; source: modelData.icon.startsWith("/") ? modelData.icon : ("image://icon/" + modelData.icon); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                MaterialSymbol { anchors.centerIn: parent; visible: !gi.visible; text: "apps"; iconSize: 28; color: Appearance.colors.colOnSurfaceVariant }
            }
            StyledText { Layout.maximumWidth: 70; text: modelData.name; color: Appearance.colors.colOnLayer1; font.pixelSize: 10; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; maximumLineCount: 2 }
        }
    }

    // Dialog نقل تطبيق
    Dialog {
        id: moveTargetDialog
        property var app: null
        title: app ? ("نقل \"" + app.name + "\"") : ""
        anchors.centerIn: parent
        width: 260
        onClosed: {
            root.draggedApp = null
            root.isDragging = false
        }

        ColumnLayout {
            width: parent.width; spacing: 4
            Repeater {
                model: root.getAllCats().filter(c => c !== "All" && c !== (moveTargetDialog.app ? moveTargetDialog.app.cat : ""))
                delegate: RippleButton {
                    required property string modelData
                    Layout.fillWidth: true; implicitHeight: 40; buttonRadius: Appearance.rounding.small
                    onClicked: { root.moveAppTo(moveTargetDialog.app, modelData); moveTargetDialog.close() }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8
                        MaterialSymbol { text: root.getCatIcon(modelData); iconSize: 16; color: Appearance.colors.colOnSurfaceVariant }
                        StyledText { text: root.getCatName(modelData); color: Appearance.colors.colOnLayer1 }
                    }
                }
            }
        }
        standardButtons: Dialog.Cancel
    }

    // Dialog قسم جديد
    Dialog {
        id: newCatDialog
        title: "قسم جديد"
        anchors.centerIn: parent; width: 260
        ColumnLayout {
            width: parent.width; spacing: 8
            StyledText { text: "اسم القسم:"; color: Appearance.colors.colOnLayer1 }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 38; radius: Appearance.rounding.small; color: Appearance.colors.colLayer2
                TextField {
                    id: newCatField
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    background: null; color: Appearance.colors.colOnLayer1
                    placeholderText: "مثال: المفضلة"
                    font.family: Appearance.font.family.main
                }
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            let name = newCatField.text.trim()
            if (name && !root.customCats.includes(name) && !root.getAllCats().includes(name)) {
                root.customCats.push(name)
                root.catNames[name] = name
                root.catIcons[name] = "folder"
                root.customCatsChanged()
                saveData()
            }
            newCatField.text = ""
        }
        onRejected: newCatField.text = ""
    }
}
