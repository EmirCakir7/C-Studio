<p align="center">
  <img src="assets/icons/app_logo.png" width="112" height="112" alt="C-Studio Logo" />
</p>

<h1 align="center">C-Studio</h1>

<p align="center">
  <b>Modern, Lightweight C IDE with Offline AI & Google Gemini Cloud</b><br>
  <i>A plug-and-play development environment for students, educators, and developers.</i>
</p>

<p align="center">
  <a href="https://github.com/EmirCakir7/C-Studio/releases/latest"><img src="https://img.shields.io/github/v/release/EmirCakir7/C-Studio?color=blue&label=Latest%20Release" alt="Release" /></a>
  <img src="https://img.shields.io/badge/Platform-Windows%20x64%20%7C%20Android-0078D6" alt="Platforms" />
  <img src="https://img.shields.io/badge/Compiler-TCC%2064--bit-success" alt="Compiler" />
  <img src="https://img.shields.io/badge/Local%20AI-Qwen%202.5%20Coder%203B-purple" alt="Local AI" />
  <img src="https://img.shields.io/badge/Cloud%20AI-Google%20Gemini%20API-orange" alt="Gemini" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## ⚡ Highlights

* **🚀 Zero-Configuration:** No path setup or environment variables required. Extract and run `CStudio.exe` instantly!
* **⚙️ Built-in Offline Compiler:** Pre-bundled 64-bit Tiny C Compiler (TCC) for millisecond compile times (`F5`) and live interactive terminal.
* **🤖 Dual AI Assistance:**
  * **Offline Local AI:** Bundled **Qwen 2.5 Coder 3B Instruct** running 100% locally on your CPU/RAM with on-demand Start/Stop memory management.
  * **Free Cloud AI:** Optional **Google Gemini API** (`gemini-2.0-flash` / `gemini-1.5-flash`) for zero RAM overhead.
* **📱 Cross-Platform:** Available for **Windows x64** and **Android** (`.apk`).
* **🌐 Multilingual Support:** English, 🇹🇷 Türkçe, 🇩🇪 Deutsch, plus custom language pack importer and creator tool (`.cstudio-lang`).
* **💡 Smart Error Advisor:** Human-readable compiler error diagnostics (Where, Why, How to fix) with 1-click auto-fixes.

---

## 📦 Downloads

| Edition | Size | What's Included |
| :--- | :---: | :--- |
| **[Windows - With AI (3B)](https://github.com/EmirCakir7/C-Studio/releases/latest)** | **~2.1 GB** | **Recommended:** Pre-bundled with **Qwen 2.5 Coder 3B**. Extract and code with full offline AI! |
| **[Windows - Slim Edition](https://github.com/EmirCakir7/C-Studio/releases/latest)** | **~35 MB** | **Ultra-Light:** Portable compiler and IDE. Includes **1-click in-app 3B model downloader** or Gemini API mode. |
| **[Android - Release APK](https://github.com/EmirCakir7/C-Studio/releases/latest)** | **~51 MB** | Full mobile C IDE with cloud GCC compilation and special C touch bar. |

---

## 🚀 Quick Start (Windows)

1. Download **`C-Studio-Windows-x64-With-AI.zip`** or **`C-Studio-Windows-x64-Slim.zip`**.
2. Extract the ZIP anywhere (even a USB drive).
3. Run **`CStudio.exe`** — you are ready to code!

> 💡 **Tip for Slim Edition:** Click the download card in the AI panel to download the 3B model with 1 click, or switch to Google Gemini API in Settings.

---

## 🗺️ Roadmap & Upcoming Features

* [ ] 🇨🇳 Official Chinese, 🇪🇸 Spanish, and 🇷🇺 Russian native translations.
* [ ] Android Google Play Store release.
* [ ] Enhanced GDB visual debugger integration.

> ⚠️ **Note (Custom Translations):** The custom translation tool is currently in beta. Some community-created language files may have minor formatting inconsistencies or fallback strings while active development continues.

---

## 📄 License & Credits

Distributed under the **MIT License**.  
Crafted with ❤️ by **Emir Çakır** & open-source contributors. Built using Flutter, TCC (Fabrice Bellard), llama.cpp, Qwen 2.5 Coder, and Google Gemini API.
