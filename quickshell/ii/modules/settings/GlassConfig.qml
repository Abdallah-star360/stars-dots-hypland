import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Helper process to run sed commands
    property var sedProcess: null

    function runSed(command) {
        Quickshell.execDetached(["bash", "-c", command])
    }

    function setBlurValue(key, value) {
        runSed(`sed -i "s|${key} = [0-9.]*|${key} = ${value}|g" "$HOME/.config/hypr/hyprland/general.conf"`)
        Quickshell.execDetached(["bash", "-c", "hyprctl reload"])
    }

    function setOpacity(key, value) {
        runSed(`sed -i "s|${key} = [0-9.]*|${key} = ${value}|g" "$HOME/.config/hypr/hyprland/general.conf"`)
        Quickshell.execDetached(["bash", "-c", "hyprctl reload"])
    }

    // --- Blur ---
    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Blur")

        ConfigSwitch {
            buttonIcon: "blur_on"
            text: Translation.tr("Enable blur")
            checked: true
            onCheckedChanged: {
                var val = checked ? "true" : "false"
                Quickshell.execDetached(["bash", "-c",
                    `sed -i '/blur {/,/^    }/ s|enabled = .*|enabled = ${val}|' "$HOME/.config/hypr/hyprland/general.conf" && hyprctl reload`
                ])
            }
        }

        ConfigSlider {
            buttonIcon: "blur_circular"
            text: Translation.tr("Size")
            from: 1
            to: 20
            value: 14
            usePercentTooltip: false
            onValueChanged: setBlurValue("size", Math.round(value))
        }

        ConfigSlider {
            buttonIcon: "filter_2"
            text: Translation.tr("Passes")
            from: 1
            to: 8
            value: 4
            usePercentTooltip: false
            onValueChanged: setBlurValue("passes", Math.round(value))
        }

        ConfigSlider {
            buttonIcon: "light_mode"
            text: Translation.tr("Brightness")
            from: 0.1
            to: 1.5
            value: 0.95
            onValueChanged: setBlurValue("brightness", value.toFixed(2))
        }

        ConfigSlider {
            buttonIcon: "grain"
            text: Translation.tr("Noise")
            from: 0
            to: 0.1
            value: 0.02
            onValueChanged: setBlurValue("noise", value.toFixed(3))
        }

        ConfigSlider {
            buttonIcon: "colors"
            text: Translation.tr("Vibrancy")
            from: 0
            to: 1
            value: 0.6
            onValueChanged: setBlurValue("vibrancy", value.toFixed(2))
        }
    }

    // --- Opacity ---
    ContentSection {
        icon: "opacity"
        title: Translation.tr("Window Opacity")

        ConfigSlider {
            buttonIcon: "select_window"
            text: Translation.tr("Active window")
            from: 0.1
            to: 1
            value: 0.92
            onValueChanged: setOpacity("active_opacity", value.toFixed(2))
        }

        ConfigSlider {
            buttonIcon: "deselect"
            text: Translation.tr("Inactive window")
            from: 0.1
            to: 1
            value: 0.85
            onValueChanged: setOpacity("inactive_opacity", value.toFixed(2))
        }
    }

    // --- Border ---
    ContentSection {
        icon: "border_outer"
        title: Translation.tr("Border")

        ConfigSpinBox {
            icon: "line_weight"
            text: Translation.tr("Border size")
            value: 1
            from: 0
            to: 10
            stepSize: 1
            onValueChanged: {
                Quickshell.execDetached(["bash", "-c",
                    `sed -i "s|border_size = [0-9]*|border_size = ${value}|g" "$HOME/.config/hypr/hyprland/general.conf" && hyprctl reload`
                ])
            }
        }
    }
}
