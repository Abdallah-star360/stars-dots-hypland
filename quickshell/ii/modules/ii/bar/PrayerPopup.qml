import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

LazyLoader {
    id: root

    property Item hoverTarget
    property var prayers: []

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        color: "transparent"
        anchors.left: true
        anchors.top: true

        implicitWidth: popupBackground.implicitWidth + 24
        implicitHeight: popupBackground.implicitHeight + 24

        mask: Region { item: popupBackground }
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        margins {
            left: root.QsWindow?.mapFromItem(root.hoverTarget, (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0).x ?? 0
            top: Appearance.sizes.barHeight
        }

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin
                rightMargin: Appearance.sizes.elevationMargin
                topMargin: Appearance.sizes.elevationMargin
                bottomMargin: Appearance.sizes.elevationMargin
            }
            implicitWidth: col.implicitWidth + margin * 2
            implicitHeight: col.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: 4

                StyledPopupHeaderRow {
                    icon: "mosque"
                    label: "مواقيت الصلاة"
                }

                Repeater {
                    model: root.prayers
                    delegate: RowLayout {
                        required property var modelData
                        spacing: 4

                        // هايلايت للصلاة الجاية
                        Rectangle {
                            visible: modelData.next
                            Layout.fillHeight: true
                            implicitWidth: 3
                            radius: 2
                            color: Appearance.colors.colPrimary
                        }

                        MaterialSymbol {
                            text: modelData.next ? "notifications_active" : "alarm"
                            iconSize: Appearance.font.pixelSize.large
                            color: modelData.next
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                        }

                        StyledText {
                            text: modelData.name
                            color: modelData.next
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                            font.bold: modelData.next
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: modelData.time + (modelData.next ? "  ←" : "")
                            color: modelData.next
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                            font.bold: modelData.next
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                }
            }
        }
    }
}
