import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/app_language_service.dart';

class ProjectTemplate {
  final String id;
  final String title;
  final String? titleEn;
  final String? titleDe;
  final String description;
  final String? descriptionEn;
  final String? descriptionDe;
  final String initialCode;
  final String? initialCodeEn;
  final String? initialCodeDe;

  const ProjectTemplate({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleDe,
    required this.description,
    this.descriptionEn,
    this.descriptionDe,
    required this.initialCode,
    this.initialCodeEn,
    this.initialCodeDe,
  });

  String getDisplayTitle([dynamic arg]) {
    final lang = AppLanguageService();
    if (lang.isCustomLanguage) {
      final custom = lang.customTranslations[titleEn ?? title] ?? lang.customTranslations[title];
      if (custom != null && custom.trim().isNotEmpty) return custom;
    }
    if (arg is String) {
      if (arg == 'de') return titleDe ?? titleEn ?? title;
      if (arg == 'en') return titleEn ?? title;
      return title;
    }
    final bool isTr = arg is bool ? arg : true;
    return isTr ? title : (titleEn ?? title);
  }

  String getDisplayDescription([dynamic arg]) {
    final lang = AppLanguageService();
    if (lang.isCustomLanguage) {
      final custom = lang.customTranslations[descriptionEn ?? description] ?? lang.customTranslations[description];
      if (custom != null && custom.trim().isNotEmpty) return custom;
    }
    if (arg is String) {
      if (arg == 'de') return descriptionDe ?? descriptionEn ?? description;
      if (arg == 'en') return descriptionEn ?? description;
      return description;
    }
    final bool isTr = arg is bool ? arg : true;
    return isTr ? description : (descriptionEn ?? description);
  }

  String getCode([dynamic arg]) {
    if (arg is String) {
      if (arg == 'de') return initialCodeDe ?? initialCodeEn ?? initialCode;
      if (arg == 'en') return initialCodeEn ?? initialCode;
      return initialCode;
    }
    final bool isTr = arg is bool ? arg : true;
    return isTr ? initialCode : (initialCodeEn ?? initialCode);
  }
}

class ProjectModel {
  String name;
  String rootDirectory;
  String mainSourceFile;
  List<String> sourceFiles;
  List<String> headerFiles;
  String outputExeName;

  ProjectModel({
    required this.name,
    required this.rootDirectory,
    this.mainSourceFile = 'main.c',
    List<String>? sourceFiles,
    List<String>? headerFiles,
    this.outputExeName = 'program.exe',
  })  : sourceFiles = sourceFiles ?? ['main.c'],
        headerFiles = headerFiles ?? [];

  String get fullMainPath => p.join(rootDirectory, mainSourceFile);
  String get fullOutputPath => p.join(rootDirectory, outputExeName);

  void refreshFiles() {
    final dir = Directory(rootDirectory);
    if (!dir.existsSync()) return;

    sourceFiles.clear();
    headerFiles.clear();

    for (final entity in dir.listSync()) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.endsWith('.c')) {
          sourceFiles.add(name);
        } else if (name.endsWith('.h')) {
          headerFiles.add(name);
        }
      }
    }

    if (sourceFiles.isEmpty && File(fullMainPath).existsSync()) {
      sourceFiles.add(mainSourceFile);
    }
  }

  static ProjectModel fromDirectory(Directory dir) {
    final name = p.basename(dir.path);
    final proj = ProjectModel(
      name: name,
      rootDirectory: dir.path,
      mainSourceFile: 'main.c',
    );
    proj.refreshFiles();
    if (proj.sourceFiles.isNotEmpty && !proj.sourceFiles.contains(proj.mainSourceFile)) {
      proj.mainSourceFile = proj.sourceFiles.first;
    }
    return proj;
  }

  // Şablonlar: 1. Sırada Boş Proje, 2. Sırada Merhaba Dünya yer alır
  static const List<ProjectTemplate> templates = [
    // 1. BOŞ C PROJESİ (Kullanıcı isteği: 1. Sıraya taşındı)
    ProjectTemplate(
      id: 'empty',
      title: '1. Boş C Projesi',
      titleEn: '1. Empty C Project',
      titleDe: '1. Leeres C-Projekt',
      description: 'Sıfırdan kodlamak için tertemiz boş bir C kaynak dosyası.',
      descriptionEn: 'A clean, blank C source file to code completely from scratch.',
      descriptionDe: 'Eine saubere, leere C-Quelldatei, um von Grund auf neu zu programmieren.',
      initialCode: '''#include <stdio.h>

int main(void) {

    return 0;
}
''',
      initialCodeEn: '''#include <stdio.h>

int main(void) {

    return 0;
}
''',
      initialCodeDe: '''#include <stdio.h>

int main(void) {

    return 0;
}
''',
    ),

    // 2. MERHABA DÜNYA (Kullanıcı isteği: 2. Sıraya taşındı)
    ProjectTemplate(
      id: 'hello',
      title: '2. Merhaba Dünya (Temel Konsol)',
      titleEn: '2. Hello World (Basic Console)',
      titleDe: '2. Hallo Welt (Grundlegendes Terminal)',
      description: 'C diline yeni başlayanlar için standart kütüphaneleri içeren sade başlangıç şablonu.',
      descriptionEn: 'Clean starter template with standard libraries for beginners learning C.',
      descriptionDe: 'Saubere Vorlage mit Standardbibliotheken für C-Einsteiger.',
      initialCode: '''#include <stdio.h>

int main(void) {
    // Ekrana hoş geldiniz mesajı yazdırır
    printf("========================================\\n");
    printf("  C-Studio Modern C IDE'ye Hos Geldiniz! \\n");
    printf("  F5 tusuna basarak hemen calistirabilirsiniz.\\n");
    printf("========================================\\n");

    return 0;
}
''',
      initialCodeEn: '''#include <stdio.h>

int main(void) {
    // Print welcome message to console
    printf("========================================\\n");
    printf("  Welcome to C-Studio Modern C IDE!     \\n");
    printf("  Press F5 to build and run immediately.\\n");
    printf("========================================\\n");

    return 0;
}
''',
      initialCodeDe: '''#include <stdio.h>

int main(void) {
    // Willkommensnachricht auf der Konsole ausgeben
    printf("========================================\\n");
    printf("  Willkommen bei C-Studio Moderner C-IDE!\\n");
    printf("  Druecken Sie F5 zum direkten Ausfuehren.\\n");
    printf("========================================\\n");

    return 0;
}
''',
    ),

    // 3. HESAP MAKİNESİ
    ProjectTemplate(
      id: 'calc',
      title: '3. Hesap Makinesi (Girdi & Koşul)',
      titleEn: '3. Calculator (Input & Logic)',
      titleDe: '3. Taschenrechner (Eingabe & Logik)',
      description: 'scanf ile kullanıcıdan veri alma, switch-case kontrol mekanizması ve döngü örneği.',
      descriptionEn: 'User input with scanf, switch-case control structure, and conditionals.',
      descriptionDe: 'Benutzereingabe mit scanf, switch-case-Steuerung und Bedingungen.',
      initialCode: '''#include <stdio.h>

int main(void) {
    double sayi1, sayi2, sonuc;
    char islem;

    printf("=== C-Studio Hesap Makinesi ===\\n");
    printf("Birinci sayiyi girin: ");
    if (scanf("%lf", &sayi1) != 1) return 1;

    printf("Islemi secin (+, -, *, /): ");
    scanf(" %c", &islem);

    printf("Ikinci sayiyi girin: ");
    if (scanf("%lf", &sayi2) != 1) return 1;

    switch (islem) {
        case '+':
            sonuc = sayi1 + sayi2;
            printf("Sonuc: %.2lf\\n", sonuc);
            break;
        case '-':
            sonuc = sayi1 - sayi2;
            printf("Sonuc: %.2lf\\n", sonuc);
            break;
        case '*':
            sonuc = sayi1 * sayi2;
            printf("Sonuc: %.2lf\\n", sonuc);
            break;
        case '/':
            if (sayi2 != 0) {
                sonuc = sayi1 / sayi2;
                printf("Sonuc: %.2lf\\n", sonuc);
            } else {
                printf("Hata: Sifira bolme yapilamaz!\\n");
            }
            break;
        default:
            printf("Gecersiz islem secildi!\\n");
            break;
    }

    return 0;
}
''',
      initialCodeEn: '''#include <stdio.h>

int main(void) {
    double num1, num2, result;
    char op;

    printf("=== C-Studio Calculator ===\\n");
    printf("Enter first number: ");
    if (scanf("%lf", &num1) != 1) return 1;

    printf("Choose operation (+, -, *, /): ");
    scanf(" %c", &op);

    printf("Enter second number: ");
    if (scanf("%lf", &num2) != 1) return 1;

    switch (op) {
        case '+':
            result = num1 + num2;
            printf("Result: %.2lf\\n", result);
            break;
        case '-':
            result = num1 - num2;
            printf("Result: %.2lf\\n", result);
            break;
        case '*':
            result = num1 * num2;
            printf("Result: %.2lf\\n", result);
            break;
        case '/':
            if (num2 != 0) {
                result = num1 / num2;
                printf("Result: %.2lf\\n", result);
            } else {
                printf("Error: Division by zero!\\n");
            }
            break;
        default:
            printf("Invalid operation selected!\\n");
            break;
    }

    return 0;
}
''',
      initialCodeDe: '''#include <stdio.h>

int main(void) {
    double zahl1, zahl2, ergebnis;
    char op;

    printf("=== C-Studio Taschenrechner ===\\n");
    printf("Erste Zahl eingeben: ");
    if (scanf("%lf", &zahl1) != 1) return 1;

    printf("Operation waehlen (+, -, *, /): ");
    scanf(" %c", &op);

    printf("Zweite Zahl eingeben: ");
    if (scanf("%lf", &zahl2) != 1) return 1;

    switch (op) {
        case '+':
            ergebnis = zahl1 + zahl2;
            printf("Ergebnis: %.2lf\\n", ergebnis);
            break;
        case '-':
            ergebnis = zahl1 - zahl2;
            printf("Ergebnis: %.2lf\\n", ergebnis);
            break;
        case '*':
            ergebnis = zahl1 * zahl2;
            printf("Ergebnis: %.2lf\\n", ergebnis);
            break;
        case '/':
            if (zahl2 != 0) {
                ergebnis = zahl1 / zahl2;
                printf("Ergebnis: %.2lf\\n", ergebnis);
            } else {
                printf("Fehler: Division durch Null nicht erlaubt!\\n");
            }
            break;
        default:
            printf("Ungueltige Operation ausgewaehlt!\\n");
            break;
    }

    return 0;
}
''',
    ),

    // 4. DİZİ VE FONKSİYONLAR
    ProjectTemplate(
      id: 'arrays',
      title: '4. Dizi ve Fonksiyonlar',
      titleEn: '4. Arrays & Functions',
      titleDe: '4. Arrays & Funktionen',
      description: 'Dizi tanımlama, fonksiyona parametre geçirme ve ortalama hesaplama örneği.',
      descriptionEn: 'Declaring arrays, passing them to functions, and computing averages.',
      descriptionDe: 'Arrays deklarieren, an Funktionen uebergeben und Durchschnitt berechnen.',
      initialCode: '''#include <stdio.h>

double diziOrtalamasi(int dizi[], int boyut);

int main(void) {
    int notlar[5] = { 85, 92, 78, 95, 88 };
    int boyut = sizeof(notlar) / sizeof(notlar[0]);

    printf("=== Ogrenci Notlari ===\\n");
    for (int i = 0; i < boyut; i++) {
        printf("%d. Not: %d\\n", i + 1, notlar[i]);
    }

    double ort = diziOrtalamasi(notlar, boyut);
    printf("\\nSinif Ortalamasi: %.2lf\\n", ort);

    return 0;
}

double diziOrtalamasi(int dizi[], int boyut) {
    int toplam = 0;
    for (int i = 0; i < boyut; i++) {
        toplam += dizi[i];
    }
    return (double)toplam / boyut;
}
''',
      initialCodeEn: '''#include <stdio.h>

double calculateAverage(int array[], int size);

int main(void) {
    int scores[5] = { 85, 92, 78, 95, 88 };
    int size = sizeof(scores) / sizeof(scores[0]);

    printf("=== Student Scores ===\\n");
    for (int i = 0; i < size; i++) {
        printf("Score %d: %d\\n", i + 1, scores[i]);
    }

    double avg = calculateAverage(scores, size);
    printf("\\nClass Average: %.2lf\\n", avg);

    return 0;
}

double calculateAverage(int array[], int size) {
    int sum = 0;
    for (int i = 0; i < size; i++) {
        sum += array[i];
    }
    return (double)sum / size;
}
''',
      initialCodeDe: '''#include <stdio.h>

double berechneDurchschnitt(int array[], int groesse);

int main(void) {
    int noten[5] = { 85, 92, 78, 95, 88 };
    int groesse = sizeof(noten) / sizeof(noten[0]);

    printf("=== Notenliste ===\\n");
    for (int i = 0; i < groesse; i++) {
        printf("Note %d: %d\\n", i + 1, noten[i]);
    }

    double schnitt = berechneDurchschnitt(noten, groesse);
    printf("\\nKlassendurchschnitt: %.2lf\\n", schnitt);

    return 0;
}

double berechneDurchschnitt(int array[], int groesse) {
    int summe = 0;
    for (int i = 0; i < groesse; i++) {
        summe += array[i];
    }
    return (double)summe / groesse;
}
''',
    ),

    // 5. STRUCT VE DİNAMİK BELLEK
    ProjectTemplate(
      id: 'struct',
      title: '5. Struct ve Dinamik Bellek (malloc/free)',
      titleEn: '5. Struct & Dynamic Memory (malloc/free)',
      titleDe: '5. Structs & Dynamischer Speicher (malloc/free)',
      description: 'C yapısı (struct), işaretçiler (pointers) ve dinamik bellek yönetimi şablonu.',
      descriptionEn: 'C struct, pointers, dynamic memory allocation with malloc and free.',
      descriptionDe: 'C-Structs, Zeiger (Pointer) und dynamische Speicherverwaltung mit malloc/free.',
      initialCode: '''#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char isim[50];
    int yas;
    double gpa;
} Ogrenci;

int main(void) {
    // Dinamik bellek tahsisi
    Ogrenci *ogr = (Ogrenci*)malloc(sizeof(Ogrenci));
    if (ogr == NULL) {
        printf("Bellek tahsis edilemedi!\\n");
        return 1;
    }

    strcpy(ogr->isim, "Ahmet Yilmaz");
    ogr->yas = 21;
    ogr->gpa = 3.85;

    printf("=== Ogrenci Bilgileri ===\\n");
    printf("Isim : %s\\n", ogr->isim);
    printf("Yas  : %d\\n", ogr->yas);
    printf("GPA  : %.2lf\\n", ogr->gpa);

    // Bellek serbest bırakma
    free(ogr);
    printf("\\nBellek basariyla serbest birakildi.\\n");

    return 0;
}
''',
      initialCodeEn: '''#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[50];
    int age;
    double gpa;
} Student;

int main(void) {
    // Dynamic memory allocation
    Student *s = (Student*)malloc(sizeof(Student));
    if (s == NULL) {
        printf("Memory allocation failed!\\n");
        return 1;
    }

    strcpy(s->name, "Alex Smith");
    s->age = 21;
    s->gpa = 3.85;

    printf("=== Student Details ===\\n");
    printf("Name : %s\\n", s->name);
    printf("Age  : %d\\n", s->age);
    printf("GPA  : %.2lf\\n", s->gpa);

    // Free allocated memory
    free(s);
    printf("\\nMemory freed successfully.\\n");

    return 0;
}
''',
      initialCodeDe: '''#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[50];
    int alter;
    double gpa;
} Student;

int main(void) {
    // Dynamische Speicherzuweisung
    Student *s = (Student*)malloc(sizeof(Student));
    if (s == NULL) {
        printf("Speicherzuweisung fehlgeschlagen!\\n");
        return 1;
    }

    strcpy(s->name, "Max Mustermann");
    s->alter = 21;
    s->gpa = 3.85;

    printf("=== Studentendetails ===\\n");
    printf("Name  : %s\\n", s->name);
    printf("Alter : %d\\n", s->alter);
    printf("Notenschnitt: %.2lf\\n", s->gpa);

    // Speicher freigeben
    free(s);
    printf("\\nSpeicher erfolgreich freigegeben.\\n");

    return 0;
}
''',
    ),

    // 6. DOSYA İŞLEMLERİ
    ProjectTemplate(
      id: 'fileio',
      title: '6. Dosya Islemleri (fopen / fprintf / fgets)',
      titleEn: '6. File Operations (fopen / fprintf / fgets)',
      titleDe: '6. Dateioperationen (fopen / fprintf / fgets)',
      description: 'Diske metin dosyası oluşturma, satır satır yazma ve tekrar okuma işlemleri.',
      descriptionEn: 'Creating text files on disk, writing lines, and reading file content.',
      descriptionDe: 'Textdateien auf der Festplatte erstellen, Zeilen schreiben und lesen.',
      initialCode: '''#include <stdio.h>

int main(void) {
    const char *dosyaAdi = "ornek_veri.txt";

    // 1. Dosya Yazma
    FILE *f = fopen(dosyaAdi, "w");
    if (!f) {
        printf("Dosya olusturulamadi!\\n");
        return 1;
    }
    fprintf(f, "C-Studio ile olusturuldu.\\n");
    fprintf(f, "Dosya Islemleri Ornegi.\\n");
    fclose(f);
    printf("Dosya yazildi: %s\\n\\n", dosyaAdi);

    // 2. Dosya Okuma
    f = fopen(dosyaAdi, "r");
    if (!f) return 1;

    printf("--- Dosya Icerigi ---\\n");
    char tampon[256];
    while (fgets(tampon, sizeof(tampon), f)) {
        printf("%s", tampon);
    }
    fclose(f);

    return 0;
}
''',
      initialCodeEn: '''#include <stdio.h>

int main(void) {
    const char *fileName = "sample_data.txt";

    // 1. Writing to file
    FILE *f = fopen(fileName, "w");
    if (!f) {
        printf("Failed to create file!\\n");
        return 1;
    }
    fprintf(f, "Created with C-Studio.\\n");
    fprintf(f, "File operations example.\\n");
    fclose(f);
    printf("File written: %s\\n\\n", fileName);

    // 2. Reading from file
    f = fopen(fileName, "r");
    if (!f) return 1;

    printf("--- File Content ---\\n");
    char buffer[256];
    while (fgets(buffer, sizeof(buffer), f)) {
        printf("%s", buffer);
    }
    fclose(f);

    return 0;
}
''',
      initialCodeDe: '''#include <stdio.h>

int main(void) {
    const char *dateiname = "beispieldaten.txt";

    // 1. In Datei schreiben
    FILE *f = fopen(dateiname, "w");
    if (!f) {
        printf("Datei konnte nicht erstellt werden!\\n");
        return 1;
    }
    fprintf(f, "Erstellt mit C-Studio.\\n");
    fprintf(f, "Beispiel fuer Dateioperationen.\\n");
    fclose(f);
    printf("Datei geschrieben: %s\\n\\n", dateiname);

    // 2. Aus Datei lesen
    f = fopen(dateiname, "r");
    if (!f) return 1;

    printf("--- Dateiinhalt ---\\n");
    char puffer[256];
    while (fgets(puffer, sizeof(puffer), f)) {
        printf("%s", puffer);
    }
    fclose(f);

    return 0;
}
''',
    ),
  ];
}
