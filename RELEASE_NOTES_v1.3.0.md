## 🌟 C-Studio v1.3.0 Release Notes

### 🚀 What's New

1. **Dual AI Engine: Local Qwen 3B + Google Gemini API**
   - **Qwen 2.5 Coder 3B (Sweet Spot):** The built-in local AI model has been upgraded from 1.5B to **Qwen 2.5 Coder 3B Instruct**. It gives much smarter and more instructive answers on C pointers, dynamic memory (`malloc`/`free`) and algorithm logic, without straining your computer's resources.
   - **Google Gemini API (Cloud):** For those who want zero system and RAM load, support for the **Google Gemini API** (`gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-4-argon`) has been added. With a free API key from Google AI Studio you can get instant analysis from the cloud.
   - **On-Demand Start / Stop Controls:** The chat screen now has a **"Start AI"** button, a live RAM loading status, a progress bar, and a **"Stop"** button to free the RAM whenever you want.

2. **Two Separate Windows Editions:**
   - **`C-Studio-v1.3.0-Windows-x64-With-AI.zip` (~2.1 GB):** **Recommended / Plug-and-Play.** Comes fully bundled with the Qwen 2.5 Coder 3B model. No internet required, it runs offline right away.
   - **`C-Studio-v1.3.0-Windows-x64-Slim.zip` (~36 MB):** **Ultra-Light.** Contains all compiler and IDE tools except the AI weights. You can download the 3B model directly inside the app with the **one-click download button**, or use the Google Gemini API mode.

3. **Refreshed & Simplified Documentation:**
   - The GitHub `README.md` page is now much clearer, more polished and more concise.

---

### ⚠️ Important Notice: Translation Tool & Custom Language Packs (Beta)
The language creator tool (`C-Studio_Language_Creator.exe`) and the `.cstudio-lang` importer that ship with the app are currently in **active development (Beta)**. Community translations may not yet work 100% completely or flawlessly in every window of the app, and minor visual or fallback text issues may appear in some places. Language support will mature further in upcoming updates.

---

### 🗺️ Planned for the Next Release (Upcoming Roadmap)
- 📱 **Official Android Release:** An Android version with a touch-friendly special symbol bar and a GNU GCC cloud compiler will be officially released in the next major update.
- 🌐 **Official Language Expansions:** Official local language packs for 🇨🇳 Chinese (Simplified), 🇪🇸 Spanish and 🇷🇺 Russian.
- 🐞 **Visual Debugger:** Integrated GDB visual debugger support.

---

### 🎖️ Credits & Attributions

* **Fabrice Bellard & TCC Team** – Creators of the embedded 64-bit Tiny C Compiler engine at the heart of C-Studio, which compiles in milliseconds.
* **Georgi Gerganov & the llama.cpp Community** – The open-source GGUF inference engine that powers the offline local AI server (`llama-server.exe`).
* **Qwen Team (Alibaba Cloud)** – Developers of the **Qwen 2.5 Coder 3B** model, which delivers outstanding C coding ability despite its compact size.
* **Google DeepMind & Google Gemini Team** – The next-generation **Gemini 3.8 / 3.6 API** architecture that provides an ultra-fast cloud AI experience.
* **Flutter & Dart Community (Google)** – The modern and fluid UI foundation.
