## 🌟 C-Studio v1.3.0 Sürüm Notları / Release Notes

### 🚀 Neler Yeni? (What's New)

1. **Çift Yapay Zeka Motoru: Yerel Qwen 3B + Google Gemini API**
   - **Qwen 2.5 Coder 3B (Sweet Spot):** Dahili yerel yapay zeka modeli 1.5B'den **Qwen 2.5 Coder 3B Instruct** sürümüne yükseltildi. C işaretçileri (pointers), dinamik bellek (`malloc`/`free`) ve algoritma mantığında çok daha zeki ve öğretici yanıtlar verirken bilgisayar kaynaklarını yormaz.
   - **Google Gemini API (Bulut / Cloud):** Sıfır sistem ve RAM yükü isteyenler için **Google Gemini API** (`gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-4-argon`) desteği eklendi. Google AI Studio'dan alacağınız ücretsiz API anahtarınızla anında buluttan analiz alabilirsiniz.
   - **İsteğe Bağlı Başlatma / Durdurma Kontrolleri:** Sohbet ekranına **"Yapay Zekayı Başlat"** butonu, canlı RAM yükleme durumu, ilerleme çubuğu ve RAM'i istediğiniz an sıfırlamak için **"Durdur"** butonu eklendi.

2. **2 Ayrı Windows Sürümü (Two Windows Editions):**
   - **`C-Studio-v1.3.0-Windows-x64-With-AI.zip` (~2.1 GB):** **Önerilen / Tak-Çalıştır.** Qwen 2.5 Coder 3B modeliyle tam paketlenmiş olarak gelir. İnternet gerektirmez, doğrudan çevrimdışı çalışır.
   - **`C-Studio-v1.3.0-Windows-x64-Slim.zip` (~36 MB):** **Ultra Hafif.** Yapay zeka ağırlıkları hariç tüm derleyici ve IDE araçlarını içerir. İçerisindeki **tek tuşla indirme butonuyla** 3B modeli uygulama içinden doğrudan indirebilir veya Google Gemini API modunu kullanabilirsiniz.

3. **Yenilenen & Sadeleştirilen Dokümantasyon:**
   - GitHub `README.md` sayfası çok daha anlaşılır, şık ve özet hale getirildi.

---

### ⚠️ Önemli Uyarı: Çeviri Aracı & Özel Dil Paketleri (Beta)
Uygulama ile birlikte gelen dil oluşturma aracı (`C-Studio_Language_Creator.exe`) ve `.cstudio-lang` içe aktarıcısı şu anda **aktif geliştirme (Beta)** aşamasındadır. Topluluk tarafından yapılan çeviriler henüz uygulamanın tüm pencerelerinde %100 eksiksiz veya kusursuz çalışmayabilir, bazı alanlarda küçük görsel veya yedek metin hataları görülebilir. Dil desteği sonraki güncellemelerde daha da olgunlaştırılacaktır.

---

### 🗺️ Sonraki Sürümde Planlananlar (Upcoming Roadmap)
- 📱 **Resmi Android Sürümü:** Dokunmatik özel sembol barı ve GNU GCC bulut derleyicisi içeren Android sürümü sonraki büyük güncellemede resmi olarak yayınlanacaktır.
- 🌐 **Resmi Dil Genişlemeleri:** Resmi 🇨🇳 Çince (Basitleştirilmiş), 🇪🇸 İspanyolca ve 🇷🇺 Rusça yerel dil paketleri.
- 🐞 **Görsel Hata Ayıklayıcı:** Entegre GDB görsel debugger desteği.

---

### 🎖️ Katkıda Bulunanlar & Teşekkürler (Credits & Attributions)

* **Emir Çakır** ([@EmirCakir7](https://github.com/EmirCakir7)) – Proje Kurucusu, Baş Geliştirici ve Sistem Mimarı.
* **Fabrice Bellard & TCC Ekibi** – C-Studio'nun kalbinde yer alan gömülü ve milisaniyeler içinde derleme yapan 64-bit Tiny C Compiler motorunun yaratıcıları.
* **Georgi Gerganov & llama.cpp Topluluğu** – Çevrimdışı yerel yapay zeka sunucusunu (`llama-server.exe`) sağlayan açık kaynaklı GGUF çıkarım motoru.
* **Qwen Ekibi (Alibaba Cloud)** – Kompakt boyutuna rağmen olağanüstü C kodlama yeteneği sunan **Qwen 2.5 Coder 3B** modelinin geliştiricileri.
* **Google DeepMind & Google Gemini Ekibi** – Ultra hızlı bulut yapay zeka deneyimi sunan yeni nesil **Gemini 3.8 / 3.6 API** mimarisi.
* **Flutter & Dart Topluluğu (Google)** – Modern ve akıcı arayüz altyapısı.
