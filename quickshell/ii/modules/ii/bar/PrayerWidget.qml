import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    property string prayerName: "..."
    property string prayerTime: "--:--"
    property string prayerRemaining: ""
    property var allPrayers: []
    property bool notified: false  // عشان منبعتش الإشعار أكتر من مرة

    // الصلاة الجاية - كل دقيقة
    Process {
        id: prayerProcess
        command: ["python3", "/home/stars/.config/quickshell/ii/scripts/prayer_time.py"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data);
                    // لو اتغيرت الصلاة، reset الإشعار
                    if (obj.name !== root.prayerName) root.notified = false;
                    root.prayerName = obj.name;
                    root.prayerTime = obj.time;
                    root.prayerRemaining = obj.remaining;

                    // إشعار لو فضل 10 دقايق أو أقل
                    if (!root.notified && obj.remaining !== "غداً") {
                        let parts = obj.remaining.match(/(?:(\d+)س\s*)?(\d+)د/);
                        if (parts) {
                            let hrs = parseInt(parts[1] || "0");
                            let mins = parseInt(parts[2]);
                            let total = hrs * 60 + mins;
                            if (total <= 10) {
                                notifyProcess.running = true;
                                root.notified = true;
                            }
                        }
                    }
                } catch(e) {}
            }
        }
    }

    // إشعار
    Process {
        id: notifyProcess
        command: [
            "notify-send",
            "--icon=mosque",
            "--urgency=normal",
            `حان وقت ${root.prayerName}`,
            `الصلاة بعد 10 دقايق - ${root.prayerTime}`
        ]
        running: false
    }

    // كل المواقيت - للـ popup
    Process {
        id: allPrayersProcess
        command: ["python3", "/home/stars/.config/quickshell/ii/scripts/prayer_time.py", "--all"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.allPrayers = JSON.parse(data);
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: prayerProcess.running = true
    }

    PrayerPopup {
        id: prayerPopup
        hoverTarget: hoverArea
        prayers: root.allPrayers
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            if (containsMouse) allPrayersProcess.running = true;
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 6
        anchors.centerIn: parent

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: "mosque"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnLayer1
            text: root.prayerRemaining !== ""
                ? `${root.prayerName} ${root.prayerTime} (${root.prayerRemaining})`
                : `${root.prayerName} ${root.prayerTime}`
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
