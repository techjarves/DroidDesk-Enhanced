<p align="center">
  <img src="app/assets/icons/logo.png" width="120" height="120" alt="DroidDesk Logo" style="border-radius: 28px;">
</p>

<h1 align="center">DroidDesk Enhanced</h1>

<p align="center">
  <b>Turn any Android phone into a high-performance Linux desktop workstation.</b><br>
  Not an emulator. Not VNC. Native kernel execution with hardware-accelerated X11 rendering.
</p>

<p align="center">
  <a href="https://github.com/techjarves/DroidDesk/releases/latest"><img src="https://img.shields.io/github/v/release/techjarves/DroidDesk?style=for-the-badge&color=6366F1" alt="Latest Release"></a>
  <a href="https://github.com/techjarves/DroidDesk/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-10B981?style=for-the-badge" alt="License"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20ARM64-38BDF8?style=for-the-badge" alt="Platform">
</p>

---

## 🚀 Overview

**DroidDesk Enhanced** brings full Linux desktop capability directly to your Android device with advanced customization, dynamic light/dark themeing, and modern edge-to-edge UI support. Connect your phone to any monitor via USB-C or wireless bridge, and it transforms instantly into a desktop computer running real Linux applications—from **VS Code** and **LibreOffice** to **Wireshark**, **Metasploit**, and offline **Local AI** models.

Unplug your phone, and your entire workstation stays with you.

---

## ✨ Key Features

- ⚡ **Direct Kernel & Hardware Acceleration**: Uses Turnip & Zink Vulkan drivers for Snapdragon / Adreno GPUs with fallbacks for Mesa software rendering.
- 🎨 **Adaptive Light & Dark Theme System**: Seamlessly switch between dark and light modes live across all screens, cards, and modal sheets.
- 🌗 **Pre-Installation Onboarding Theme Switcher**: Toggle your preferred aesthetic right from the initial setup screens before installation.
- 📱 **Edge-to-Edge System Bar Integration**: Clean, transparent Android status bar overlays with adaptive icon brightness on Android 11 through Android 15.
- 🖥️ **One-Tap Desktop Essentials**: Automated installation of **XFCE4**, **LXQt**, **MATE**, or **KDE Plasma** desktop environments.
- 🔒 **Dual Architecture**: Supports **Rooted Chroot** (Ubuntu 24.04 LTS) and **Non-Rooted Native Termux/TUR** userspaces.
- 💻 **Embedded X11 Server**: Renders through an embedded Termux:X11 display server directly on `DISPLAY=:0` without VNC lag.

---

## 🛠️ What You Can Run

| Category | Supported Tools |
|---|---|
| **Development** | Full VS Code (Python, Node.js, C++, Extensions), Git, Claude Code, Vim, Neovim |
| **Productivity** | LibreOffice Suite (Writer, Calc, Impress), Firefox, Chromium |
| **Security & Auditing** | Wireshark, Metasploit Framework, Nmap |
| **Media & AI** | Blender (3D modeling), Local Offline LLMs (Ollama / Llama.cpp), GIMP |

---

## 📱 Quick Start

### Option A: Standalone Android App (Recommended)

1. Download the latest compiled **[Release APK](https://github.com/techjarves/DroidDesk/releases/latest)**.
2. Install the APK on your Android phone (ARM64, Android 8.0+).
3. Select your theme (Light/Dark) on the onboarding screen.
4. Pick your desktop environment (XFCE4, LXQt, MATE, or KDE Plasma) and tap **Install Essentials**.

### Option B: Manual Termux Setup Script

If you prefer installing inside an existing Termux terminal environment:

```bash
curl -sL https://raw.githubusercontent.com/orailnoor/DroidDesk/main/termux-linux-setup.sh -o setup.sh
bash setup.sh
```

Launch the desktop:
```bash
bash ~/start-x11.sh
```

---

## 🖥️ Display & Monitor Output

- **Direct USB-C Display**: Connect a USB-C to HDMI adapter directly to phones supporting DisplayPort Alt mode.
- **Raspberry Pi Bridge**: Use a Raspberry Pi Zero 2W connected via USB tethering to mirror the desktop to any HDMI monitor.

---

## 🤝 Credits & Acknowledgments

DroidDesk is built on the incredible work of the open-source Linux and Android community:

- **Original Creator & Architect**: **[orailnoor](https://youtube.com/@orailnoor)** ([GitHub: @orailnoor](https://github.com/orailnoor/DroidDesk))
  *Designed the original DroidDesk Linux setup scripts, Termux integration, embedded X11 architecture, and standalone app core.*

- **Customizations & Enhancements**: **[techjarves](https://github.com/techjarves/DroidDesk)**
  *Implemented the dynamic Light & Dark theme engine, pre-installation onboarding theme selector, status bar edge-to-edge transparent integration, high-contrast terminal bottom sheet, UI contrast overhauls, and distribution releases.*

- **Upstream Open Source Projects**:
  - [Termux](https://github.com/termux/termux-app) & [Termux:X11](https://github.com/termux/termux-x11)
  - [Termux User Repository (TUR)](https://github.com/termux-user-repository/tur)
  - [Ubuntu / Canonical](https://ubuntu.com)

---

## 📄 License & Legal Notice

DroidDesk is independent open-source software licensed under the **[GNU General Public License v3.0](LICENSE)**. 

> [!NOTE]
> DroidDesk is an independent project and is not affiliated with or endorsed by Termux, Termux:X11, TUR, Canonical, or Ubuntu. All trademarks belong to their respective owners.
