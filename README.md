<p align="center">
  <img src="assets/icons/app_logo.png" width="128" height="128" alt="C-Studio Logo" />
</p>

<h1 align="center">C-Studio</h1>

<p align="center">
  <b>Modern, Lightweight & 100% Offline C Development IDE with Local AI</b><br>
  <i>A plug-and-play desktop environment designed for C programming students, educators, and software developers.</i>
</p>

<p align="center">
  <a href="https://github.com/EmirCakir7/C-Studio/releases/latest"><img src="https://img.shields.io/github/v/release/EmirCakir7/C-Studio?color=blue&label=Release" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/Platform-Windows%20x64-0078D6?logo=windows" alt="Platform" />
  <img src="https://img.shields.io/badge/Framework-Flutter%20Desktop-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Compiler-TCC%2064--bit-success" alt="Compiler" />
  <img src="https://img.shields.io/badge/AI%20Engine-Qwen%202.5%20Coder%201.5B-purple?logo=openai" alt="AI Model" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 🚀 Overview

**C-Studio** is a fast, modern, and completely portable integrated development environment (IDE) built specifically for C programming. 

Unlike traditional IDEs that require heavy installations, complex environment variables (`PATH`), or active internet connections, **C-Studio runs instantly from a single folder**. It comes pre-bundled with an embedded **64-bit Tiny C Compiler (TCC)** and a **100% offline Local AI coding tutor** powered by `llama.cpp` and `Qwen 2.5 Coder 1.5B Instruct`.

---

## 📦 Download & Quick Start

Get the pre-built portable binaries directly from [**GitHub Releases**](https://github.com/EmirCakir7/C-Studio/releases/latest):

| Package | Size | Description |
| :--- | :--- | :--- |
| [**`C-Studio-v1.0.0-Windows-x64-With-AI.zip`**](https://github.com/EmirCakir7/C-Studio/releases/download/v1.0.0/C-Studio-v1.0.0-Windows-x64-With-AI.zip) | **~900 MB** | **All-in-One (Recommended):** Pre-packaged with the offline AI model (`Qwen2.5-Coder-1.5B`). Zero configuration or internet required. Extract and launch `CStudio.exe`! |
| [**`C-Studio-v1.0.0-Windows-x64-Slim.zip`**](https://github.com/EmirCakir7/C-Studio/releases/download/v1.0.0/C-Studio-v1.0.0-Windows-x64-Slim.zip) | **~30 MB** | **Lightweight (AI-Ready):** Ultra-compact download. The local AI runtime is included; simply drop any compatible GGUF model into `ai/models/` whenever you wish to enable the AI assistant. |

### Running the App:
1. Download either the **With-AI** or **Slim** zip package.
2. Extract the archive to any folder (or USB drive).
3. Double-click **`CStudio.exe`** to launch. **No installer or setup required!**

---

## ✨ Key Features

### ⚡ Zero-Configuration Portable C Compiler (TCC 64-bit)
- Compile and execute your C code in milliseconds with a single keystroke (`F5`).
- Runs directly from any directory or removable drive without modifying system variables.
- Includes standard C library headers and Windows API definitions.
- Custom dual-buffered runtime (`cstudio_runtime.h`) guarantees immediate flush for `printf` and smooth interactive input for `scanf`.

### 🖥️ Interactive Live Terminal
- Real-time `stdout` and `stderr` execution stream.
- Full interactive console input support (`scanf`, `getchar`, `fgets`).
- Dedicated process control buttons: Run, Stop, Clear, and return code status reporting.

### 🤖 100% Offline Local AI Assistant (Qwen 2.5 Coder 1.5B)
- **Zero Cloud Dependencies:** No internet connection, API keys, subscriptions, or telemetry required.
- **Privacy First:** Your code never leaves your local machine.
- **Dedicated C Tutor:** Strictly filtered to assist with programming, algorithmic logic, bug detection, and code improvement.
- **One-Click Code Insertion:** Apply assistant-generated code solutions directly into your active editor with a single click.

### 🛠️ Smart Error Advisor
- Parses compiler warnings and errors into clear, educational explanations:
  - 📍 **Where:** Exact file path, line number, and column.
  - ❓ **Why:** Understand the root cause behind syntax or logical issues.
  - 🛠️ **How to Fix:** Step-by-step instructions and code snippets demonstrating the fix.
- **Auto-Fix Integration:** One-click automated resolution for common student errors (missing semicolons, unmatched brackets, missing header `#include`s).

### ⌨️ Special Keys Toolbar
- Quick-access touch/click bar for frequently needed programming symbols on international keyboards: `{}`, `[]`, `\`, `|`, `~`, `->`, `;`.

### 🌐 Bilingual Interface (English & Turkish)
- Seamlessly toggle the entire UI, terminal notices, compiler advisor, and AI assistant between English and Turkish.
- Option to configure the AI tutor language independently from the IDE interface language.

### 📁 Multi-Project & File Management
- Manage multiple projects simultaneously with tabbed switching.
- Create, rename, delete, import, and export `.c` source files and `.h` header files.
- Built-in starter templates (Empty, Hello World, Calculator, Number Guessing Game, Loops & Arrays, Structs & Memory Management).

### 💾 Automatic Background Saving
- Protects your work by automatically persisting unsaved edits to disk in real-time.

---

## 🚀 How to Add AI to the Slim Edition

If you prefer to start with the compact **Slim Edition (~30 MB)**:

1. Download the recommended model file (~881 MB):  
   🔗 [Download `qwen2.5-coder-1.5b-instruct-q3_k_m.gguf` from Hugging Face](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q3_k_m.gguf)
2. Place the downloaded `.gguf` file inside the `C-Studio/ai/models/` folder.
3. Restart `CStudio.exe`. C-Studio will automatically detect the model and enable the AI assistant immediately!

---

## 🛠️ Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.13 or newer)
- Windows 10 / 11 (64-bit)
- Visual Studio 2022 (with **Desktop development with C++** workload)
- Git

### Build Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/EmirCakir7/C-Studio.git
   cd C-Studio
   ```

2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Download the local AI model (optional for compilation, required for AI assistant):
   - Download [`qwen2.5-coder-1.5b-instruct-q3_k_m.gguf`](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF)
   - Save it into `ai/models/`

4. Run or build the application:
   ```bash
   # Run in debug mode:
   flutter run -d windows

   # Build standalone release binary:
   flutter build windows --release
   ```

The compiled binary will be generated in `build/windows/x64/runner/Release/`.

---

## 📂 Project Architecture

```
C-Studio/
├── lib/
│   ├── models/            # Project, compiler, and diagnostic data models
│   ├── services/          # Compiler service, local AI service, language, auto-save
│   ├── widgets/           # Code editor, terminal, AI chat panel, project explorer
│   └── main.dart          # Main IDE workspace, tabs, layout & window manager
├── assets/
│   └── icons/             # Custom application branding and icon assets
├── ai/
│   ├── runtime/           # llama-server.exe and multi-architecture CPU DLLs
│   └── models/            # GGUF AI models directory & model documentation
├── compiler/              # Portable 64-bit Tiny C Compiler (TCC), headers & libs
└── windows/               # Native Windows C++ Runner, window config & version resources
```

---

## 🎖️ Attributions & Acknowledgements

C-Studio is built with deep gratitude upon the work of several outstanding open-source projects and communities:

| Project | Author / Maintainer | Role in C-Studio | License |
| :--- | :--- | :--- | :--- |
| **[Tiny C Compiler (TCC)](https://bellard.org/tcc/)** | **Fabrice Bellard** & TCC Contributors | Embedded ultra-fast 64-bit portable C compiler | [LGPL v2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html) |
| **[llama.cpp](https://github.com/ggerganov/llama.cpp)** | **Georgi Gerganov** & Contributors | 100% offline local LLM inference engine (`llama-server`) | [MIT License](https://github.com/ggerganov/llama.cpp/blob/master/LICENSE) |
| **[Qwen 2.5 Coder](https://github.com/QwenLM/Qwen2.5-Coder)** | **Qwen Team / Alibaba Cloud** | AI code reasoning and intelligent error diagnostics | [Apache 2.0](https://github.com/QwenLM/Qwen2.5-Coder/blob/main/LICENSE) |
| **[Flutter](https://flutter.dev/)** | **Google** & Contributors | Modern, reactive cross-platform desktop UI framework | [BSD 3-Clause](https://github.com/flutter/flutter/blob/master/LICENSE) |
| **[LLVM OpenMP (libomp)](https://openmp.llvm.org/)** | **LLVM Foundation** | Multi-threaded CPU acceleration for inference runtime | [Apache 2.0 with LLVM Exception](https://llvm.org/LICENSE.txt) |

---

## 👨‍💻 Author & Maintainer

- **Emir Çakır**
  - GitHub: [@EmirCakir7](https://github.com/EmirCakir7)
  - Project Repository: [https://github.com/EmirCakir7/C-Studio](https://github.com/EmirCakir7/C-Studio)

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.  
Third-party components bundled with the application (TCC, llama.cpp, Qwen models, etc.) are distributed under their respective open-source licenses as indicated above.
