#!/bin/bash
# ========================================
#  toggle-glass.sh - 7 Modes
#  dark_void → neon_purple → void_red → ember → ocean → frosted → solid_dark → dark_void
# ========================================

GENERAL_CONF="$HOME/.config/hypr/hyprland/general.conf"
CUSTOM_RULES="$HOME/.config/hypr/custom/rules.conf"
STATE_FILE="$HOME/.config/hypr/custom/.glass_state"

RED="\e[31m"
PURPLE="\e[35m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
WHITE="\e[37m"
RESET="\e[0m"

if [[ ! -f "$GENERAL_CONF" || ! -f "$CUSTOM_RULES" ]]; then
    echo -e "${YELLOW}⚠ ملفات الـ config مش موجودة!${RESET}"
    exit 1
fi

set_blur() {
    sed -i "s|size = [0-9]*|size = $1|g" "$GENERAL_CONF"
    sed -i "s|passes = [0-9]*|passes = $2|g" "$GENERAL_CONF"
    sed -i "s|brightness = [0-9.]*|brightness = $3|g" "$GENERAL_CONF"
    sed -i "s|noise = [0-9.]*|noise = $4|g" "$GENERAL_CONF"
    sed -i "s|vibrancy = [0-9.]*|vibrancy = $5|g" "$GENERAL_CONF"
}

set_border() {
    sed -i "s|col.active_border = .*|col.active_border = $1|g" "$GENERAL_CONF"
    sed -i "s|col.inactive_border = .*|col.inactive_border = $2|g" "$GENERAL_CONF"
}

set_opacity_rule() {
    sed -i '/^windowrule = opacity.*match:class \.\*/d' "$CUSTOM_RULES"
    [[ -n "$1" ]] && echo "windowrule = opacity $1 override $2 override, match:class .*" >> "$CUSTOM_RULES"
}

toggle_blur() {
    # $1 = true/false
    sed -i "s|enabled = true|enabled = $1|g" "$GENERAL_CONF"
}

# ============================
#  الوضعيات
# ============================

mode_dark_void() {
    echo -e "${PURPLE}🌑 Dark Void...${RESET}"
    toggle_blur true
    set_opacity_rule "0.75" "0.65"
    set_blur 6 2 0.8 0.03 0.2
    set_border "rgba(ffffff15)" "rgba(00000000)"
    echo "dark_void" > "$STATE_FILE"
    NOTIFY_MSG="🌑 Dark Void"
}

mode_neon_purple() {
    echo -e "${PURPLE}💜 Neon Purple...${RESET}"
    toggle_blur true
    set_opacity_rule "0.88" "0.80"
    set_blur 12 3 0.9 0.02 0.7
    set_border "rgba(bf00ffff) rgba(7b00d4ff) 45deg" "rgba(6600aa55)"
    echo "neon_purple" > "$STATE_FILE"
    NOTIFY_MSG="💜 Neon Purple"
}

mode_void_red() {
    echo -e "${RED}💀 Void Red...${RESET}"
    toggle_blur true
    set_opacity_rule "0.80" "0.70"
    set_blur 8 2 0.7 0.04 0.3
    set_border "rgba(ff0000ff) rgba(8b0000ff) 45deg" "rgba(ff000033)"
    echo "void_red" > "$STATE_FILE"
    NOTIFY_MSG="💀 Void Red"
}

mode_ember() {
    echo -e "${YELLOW}🔥 Ember...${RESET}"
    toggle_blur true
    set_opacity_rule "0.90" "0.82"
    set_blur 10 3 1.0 0.02 0.5
    set_border "rgba(ff6600ff) rgba(ff3300ff) 45deg" "rgba(ff440033)"
    echo "ember" > "$STATE_FILE"
    NOTIFY_MSG="🔥 Ember"
}

mode_ocean() {
    echo -e "${BLUE}🌊 Ocean...${RESET}"
    toggle_blur true
    set_opacity_rule "0.85" "0.75"
    set_blur 16 4 0.95 0.01 0.6
    set_border "rgba(0077ffff) rgba(00ccffff) 45deg" "rgba(004daa44)"
    echo "ocean" > "$STATE_FILE"
    NOTIFY_MSG="🌊 Ocean"
}

mode_frosted() {
    echo -e "${WHITE}☁️  Frosted macOS...${RESET}"
    toggle_blur true
    set_opacity_rule "0.88" "0.80"
    set_blur 20 5 1.1 0.01 0.3
    set_border "rgba(ffffff88) rgba(ffffff44) 45deg" "rgba(ffffff22)"
    echo "frosted" > "$STATE_FILE"
    NOTIFY_MSG="☁️ Frosted"
}

mode_solid_dark() {
    echo -e "${WHITE}⬛ Solid Dark...${RESET}"
    toggle_blur false
    set_opacity_rule "1.0" "1.0"
    set_blur 0 0 1 0 0
    set_border "rgba(444444ff)" "rgba(222222ff)"
    echo "solid_dark" > "$STATE_FILE"
    NOTIFY_MSG="⬛ Solid Dark"
}

# ============================
#  التبديل الدائري
# ============================

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "solid_dark")

case "$CURRENT" in
    dark_void)   mode_neon_purple ;;
    neon_purple) mode_void_red ;;
    void_red)    mode_ember ;;
    ember)       mode_ocean ;;
    ocean)       mode_frosted ;;
    frosted)     mode_solid_dark ;;
    solid_dark)  mode_dark_void ;;
    *)           mode_dark_void ;;
esac

hyprctl reload
notify-send "🎨 Theme Mode" "$NOTIFY_MSG" --icon=preferences-desktop-display 2>/dev/null

NEW_STATE=$(cat "$STATE_FILE")
echo -e "${GREEN}✅ الوضع الحالي: $NEW_STATE${RESET}"
