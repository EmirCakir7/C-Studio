<p align="center">
  <img src="assets/icons/app_logo.png" width="112" height="112" alt="C-Studio Logo" />
</p>

<h1 align="center">C-Studio</h1>

<p align="center">
  <b>Modern, Lightweight C IDE with Offline Local AI & Google Gemini Cloud</b><br>
  <i>A plug-and-play development environment for students, educators, and developers.</i>
</p>

<p align="center">
  <a href="https://github.com/EmirCakir7/C-Studio/releases/latest"><img src="https://img.shields.io/github/v/release/EmirCakir7/C-Studio?color=blue&label=Latest%20Release" alt="Release" /></a>
  <img src="https://img.shields.io/badge/Platform-Windows%20x64-0078D6" alt="Platforms" />
  <img src="https://img.shields.io/badge/Compiler-TCC%2064--bit-success" alt="Compiler" />
  <img src="https://img.shields.io/badge/Local%20AI-Qwen%202.5%20Coder%203B-purple" alt="Local AI" />
  <img src="https://img.shields.io/badge/Cloud%20AI-Google%20Gemini%203.8%20API-orange" alt="Gemini" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## ⚡ Highlights

* **🚀 Zero-Configuration:** No path setup or environment variables required. Extract and run `CStudio.exe` instantly!
* **⚙️ Built-in Offline Compiler:** Pre-bundled 64-bit Tiny C Compiler (TCC) for millisecond compile times (`F5`) and live interactive terminal.
* **🤖 Dual AI Assistance:**
  * **Offline Local AI:** Bundled **Qwen 2.5 Coder 3B Instruct** running 100% locally on your CPU/RAM with on-demand Start/Stop memory management.
  * **Free Cloud AI:** Optional **Google Gemini API** (`gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-4-argon`) for zero RAM overhead.
* **🌐 Multilingual Support:** English, 🇹🇷 Türkçe, 🇩🇪 Deutsch, plus custom language pack importer and creator tool (`.cstudio-lang`).
* **💡 Smart Error Advisor:** Human-readable compiler error diagnostics (Where, Why, How to fix) with 1-click auto-fixes.

---

## 📦 Downloads (Windows x64)

| Edition | Size | What's Included |
| :--- | :---: | :--- |
| **[Windows - With AI (3B)](https://github.com/EmirCakir7/C-Studio/releases/latest)** | **~2.1 GB** | **Recommended:** Pre-bundled with **Qwen 2.5 Coder 3B**. Extract and code with full offline AI! |
| **[Windows - Slim Edition](https://github.com/EmirCakir7/C-Studio/releases/latest)** | **~35 MB** | **Ultra-Light:** Portable compiler and IDE. Includes **1-click in-app 3B model downloader** or Gemini API mode. |

### Quick Start:
1. Download **`C-Studio-Windows-x64-With-AI.zip`** or **`C-Studio-Windows-x64-Slim.zip`**.
2. Extract the archive anywhere (even on a USB flash drive).
3. Run **`CStudio.exe`** — no installer required!

> 💡 **Tip for Slim Edition:** Click the download card in the AI panel to download the 3B model with 1 click, or enter your free Google Gemini API key in Settings.

---

## 🗺️ Roadmap & Upcoming Features

* [ ] 📱 **Official Android Release:** Native Android mobile edition with cloud compiler & touchscreen coding bar is planned for the next major release.
* [ ] 🌐 **Official Language Expansions:** Native 🇨🇳 Chinese (Simplified), 🇪🇸 Spanish, and 🇷🇺 Russian translations.
* [ ] 🐞 **Visual Debugger:** Integrated GDB visual debugging support.

> ⚠️ **Note (Custom Translations):** The custom language pack creator and translation importer are currently in active beta development. User translations may not cover 100% of all UI strings or may contain minor formatting inconsistencies or fallback text as localization support matures.

---

## 🎖️ Credits & Acknowledgements

C-Studio is made possible thanks to world-class open-source projects and developer communities:

* **Emir Çakır** ([@EmirCakir7](https://github.com/EmirCakir7)) – Project Creator, Lead Developer, and System Architect.
* **[Fabrice Bellard](https://bellard.org/) & TCC Team** – Creators and maintainers of the **Tiny C Compiler (TCC)**, providing the embedded, ultra-fast 64-bit compilation engine.
* **[Georgi Gerganov](https://github.com/ggerganov) & [llama.cpp](https://github.com/ggerganov/llama.cpp)** – The groundbreaking C/C++ offline LLM inference framework powering C-Studio's local offline AI engine (`llama-server.exe`).
* **[Qwen Team (Alibaba Cloud)](https://github.com/QwenLM)** – Creators of the remarkable **Qwen 2.5 Coder** model family (`Qwen2.5-Coder-3B-Instruct`), delivering state-of-the-art C coding intelligence in compact weights.
* **[Google DeepMind](https://deepmind.google/) & Google Gemini Team** – Developers of the **Google Gemini API** (`gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-4-argon`), enabling blazing-fast cloud AI coding capabilities.
* **[Flutter](https://flutter.dev) & Dart Community** – The cross-platform framework by Google enabling high-performance desktop graphics and responsive layouts.
* **Open Source Contributors** – Sincere appreciation to authors of `google_fonts`, `file_picker`, `path`, and community contributors who help translate and test C-Studio.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for details.
