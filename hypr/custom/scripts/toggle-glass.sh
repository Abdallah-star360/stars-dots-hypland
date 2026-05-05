#!/bin/bash
# ========================================
#  toggle-glass.sh - 2 Modes: Solid Dark ↔ Dark Void
# ========================================

GENERAL_CONF="$HOME/.config/hypr/hyprland/general.conf"
CUSTOM_RULES="$HOME/.config/hypr/custom/rules.conf"
STATE_FILE="$HOME/.config/hypr/custom/.glass_state"

# --- دوال التعديل (نفس أسلوب سكربتك القديم) ---
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
    sed -i "s|enabled = true|enabled = $1|g" "$GENERAL_CONF"
    sed -i "s|enabled = false|enabled = $1|g" "$GENERAL_CONF"
}

# ============================
#  الوضعين
# ============================

mode_dark_void() {
    echo "🌑 Dark Void..."
    toggle_blur true
    set_opacity_rule "0.90" "0.55"
    set_blur 6 2 0.8 0.03 0.2
    set_border "rgba(255,255,255,0.08)" "rgba(0,0,0,0)"
    echo "dark_void" > "$STATE_FILE"
    NOTIFY_MSG="🌑 Dark Void Enabled"
}

mode_solid_dark() {
    echo "⬛ Solid Dark..."
    toggle_blur false
    set_opacity_rule "1.0" "1.0"
    set_blur 0 0 1 0 0
    set_border "rgba(444444ff)" "rgba(222222ff)"
    echo "solid_dark" > "$STATE_FILE"
    NOTIFY_MSG="⬛ Solid Dark Enabled"
}

# ============================
#  التبديل بينهم (Toggle)
# ============================

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "solid_dark")

if [ "$CURRENT" = "dark_void" ]; then
    mode_solid_dark
else
    mode_dark_void
fi

hyprctl reload
notify-send "🎨 Theme Mode" "$NOTIFY_MSG" --icon=preferences-desktop-display 2>/dev/null

echo "✅ الوضع الحالي: $(cat "$STATE_FILE")"