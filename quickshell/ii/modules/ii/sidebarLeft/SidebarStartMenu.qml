pragma ComponentBehavior: Bound
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.startMenu
import qs.modules.waffle.startMenu.startPage
import qs.modules.waffle.startMenu.searchPage

Item {
    id: root
    anchors.fill: parent

    property bool searching: false
    property string searchText: LauncherSearch.query

    StartMenuContext {
        id: context
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { searchBar.text = ""; return }
        if (event.key === Qt.Key_Backspace) {
            searchBar.forceFocus()
            if (event.modifiers & Qt.ControlModifier) {
                let text = searchBar.text; let pos = searchBar.searchInput.cursorPosition
                if (pos > 0) {
                    let left = text.slice(0, pos); let match = left.match(/(\s*\S+)\s*$/)
                    let deleteLen = match ? match[0].length : 1
                    searchBar.text = text.slice(0, pos - deleteLen) + text.slice(pos)
                    searchBar.searchInput.cursorPosition = pos - deleteLen
                }
            } else {
                if (searchBar.searchInput.cursorPosition > 0) {
                    searchBar.text = searchBar.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.text.slice(searchBar.searchInput.cursorPosition)
                    searchBar.searchInput.cursorPosition -= 1
                }
            }
            searchBar.searchInput.cursorPosition = searchBar.text.length
            event.accepted = true; return
        }
        if (event.text && event.text.length === 1 &&
            event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return &&
            event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) {
            if (!searchBar.searchInput.activeFocus) {
                searchBar.forceFocus()
                searchBar.text = searchBar.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.text.slice(searchBar.searchInput.cursorPosition)
                searchBar.searchInput.cursorPosition += 1
                event.accepted = true; context.setCurrentIndex(0)
            }
        }
        if (event.key === Qt.Key_Down) {
            context.setCurrentIndex(Math.min(context.currentIndex + 1, Math.max(0, LauncherSearch.results.length - 1)))
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            context.setCurrentIndex(Math.max(context.currentIndex - 1, 0))
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Search bar
        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            horizontalPadding: 8
            verticalPadding: 8
            Synchronizer on searching { property alias target: root.searching }
            focus: true
            text: root.searchText
            onTextChanged: LauncherSearch.query = text
            onAccepted: context.accepted()
        }

        // Search page
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.searching
            active: root.searching
            sourceComponent: SearchPageContent { context: context }
        }

        // Start page apps - Flickable بيشغل بس لما مش searching
        Flickable {
            id: appsFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.searching
            contentWidth: width
            contentHeight: 900
            flickableDirection: Flickable.VerticalFlick
            clip: true

            StartPageApps {
                id: startApps
                width: parent.width
                height: 900
            }

            onVisibleChanged: {
                if (visible) {
                    contentY = 1
                    contentY = 0
                }
            }


        }

        // Footer ثابت في الأسفل دايماً
        Item {
            Layout.fillWidth: true
            visible: !root.searching
            implicitHeight: 63

            StartUserButton {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
            }

            WBorderlessButton {
                id: pwrBtn
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: 40
                implicitHeight: 40
                contentItem: Item {
                    FluentIcon {
                        anchors.centerIn: parent
                        icon: "power"
                        implicitSize: 20
                    }
                }
                onClicked: pwrMenu.open()
                WMenu {
                    id: pwrMenu
                    x: -pwrMenu.implicitWidth / 2 + pwrBtn.implicitWidth / 2
                    y: -pwrMenu.implicitHeight - 4
                    Action { icon.name: "lock-closed"; text: Translation.tr("Lock"); onTriggered: Session.lock() }
                    Action { icon.name: "weather-moon"; text: Translation.tr("Sleep"); onTriggered: Session.suspend() }
                    Action { icon.name: "power"; text: Translation.tr("Shut down"); onTriggered: Session.poweroff() }
                    Action { icon.name: "arrow-counterclockwise"; text: Translation.tr("Restart"); onTriggered: Session.reboot() }
                }
            }
        }
    }
}
