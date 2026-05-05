<div align="center">

# ✦ stars-dots-hypland ✦

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)](https://hyprland.org/)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-orange?style=for-the-badge)](https://quickshell.outfoxxed.me/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

My personal Hyprland dotfiles — based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) `ii` configuration with Quickshell.

</div>

---

## ✨ Features

- 🪐 **Hyprland** — Dynamic tiling Wayland compositor
- 🔮 **Quickshell** — Shell built with QML (end-4 `ii` config)
- 🎨 **Material You** — Dynamic color theming from wallpaper
- 🌙 **Dark & Minimal** aesthetic
- 🔒 **Hyprlock** — Lock screen
- 💤 **Hypridle** — Idle management
- 🎵 **EasyEffects** — Audio processing
- 📋 **Cliphist** — Clipboard history
- 🗝️ **Gnome Keyring** — Secrets management

---

## 📸 Screenshots

> Coming soon...

---

## 🚀 Installation

### Requirements

```bash
# Core
sudo pacman -S hyprland quickshell hypridle hyprlock

# Fonts
sudo pacman -S noto-fonts noto-fonts-arabic ttf-jetbrains-mono-nerd

# Audio
sudo pacman -S easyeffects pipewire pipewire-pulse wireplumber

# Clipboard
sudo pacman -S cliphist wl-clipboard

# Keyring
sudo pacman -S gnome-keyring

# Cursor
yay -S bibata-cursor-theme
```

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/Abdallah-star360/stars-dots-hypland.git
cd stars-dots-hypland

# 2. Backup your existing configs
cp -r ~/.config/hypr ~/.config/hypr.bak
cp -r ~/.config/quickshell ~/.config/quickshell.bak

# 3. Copy the dots
cp -r hypr ~/.config/
cp -r quickshell ~/.config/

# 4. Restart Hyprland
hyprctl reload
```

---

## 📁 Structure

```
stars-dots-hypland/
├── hypr/
│   ├── hyprland.conf          # Main config
│   ├── hypridle.conf          # Idle config
│   ├── hyprlock.conf          # Lock screen config
│   ├── monitors.conf          # Monitor setup
│   ├── workspaces.conf        # Workspace rules
│   ├── hyprland/
│   │   ├── keybinds.conf      # Keybindings
│   │   ├── execs.conf         # Autostart
│   │   ├── rules.conf         # Window rules
│   │   ├── env.conf           # Environment variables
│   │   └── general.conf       # General settings
│   └── custom/                # Your personal overrides
│       ├── keybinds.conf
│       ├── rules.conf
│       └── ...
└── quickshell/
    └── ii/
        ├── shell.qml          # Main shell entry
        ├── settings.qml       # Settings app
        ├── assets/            # Icons & wallpapers
        ├── modules/           # UI components
        │   ├── ii/bar/        # Top bar
        │   ├── ii/sidebarLeft/
        │   ├── ii/sidebarRight/
        │   └── settings/      # Settings pages
        ├── services/          # Background services
        └── scripts/           # Helper scripts
```

---

## ⚙️ Customization

Open the settings with `Super + I` or edit the files directly:

| What | File |
|------|------|
| Bar & appearance | `quickshell/ii/modules/settings/BarConfig.qml` |
| General settings | `quickshell/ii/modules/settings/GeneralConfig.qml` |
| Hyprland keybinds | `hypr/custom/keybinds.conf` |
| Autostart apps | `hypr/hyprland/execs.conf` |
| Monitor setup | `hypr/monitors.conf` |
| Main config | `~/.config/illogical-impulse/config.json` |

---

## 🙏 Credits

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — Original dots this is based on
- [Hyprland](https://hyprland.org/) — The compositor
- [Quickshell](https://quickshell.outfoxxed.me/) — The shell

---

<div align="center">
Made with ❤️ by <a href="https://github.com/Abdallah-star360">Abdallah-star360</a>

⭐ Star the repo if you like it!
</div>
