import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectTemplate {
  final String id;
  final String title;
  final String? titleEn;
  final String description;
  final String? descriptionEn;
  final String initialCode;

  const ProjectTemplate({
    required this.id,
    required this.title,
    this.titleEn,
    required this.description,
    this.descriptionEn,
    required this.initialCode,
  });

  String getDisplayTitle(bool isTr) => isTr ? title : (titleEn ?? title);
  String getDisplayDescription(bool isTr) => isTr ? description : (descriptionEn ?? description);
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

  static const List<ProjectTemplate> templates = [
    ProjectTemplate(
      id: 'hello',
      title: '1. Merhaba Dünya (Temel Konsol)',
      titleEn: '1. Hello World (Basic Console)',
      description: 'C diline yeni başlayanlar için standart kütüphaneleri içeren sade başlangıç şablonu.',
      descriptionEn: 'Clean starter template with standard libraries for beginners learning C.',
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
    ),
    ProjectTemplate(
      id: 'calc',
      title: '2. Hesap Makinesi (Girdi & Koşul)',
      titleEn: '2. Calculator (Input & Logic)',
      description: 'scanf ile kullanıcıdan veri alma, switch-case kontrol mekanizması ve döngü örneği.',
      descriptionEn: 'User input with scanf, switch-case control structure, and conditionals.',
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
    ),
    ProjectTemplate(
      id: 'arrays',
      title: '3. Dizi ve Fonksiyonlar',
      titleEn: '3. Arrays & Functions',
      description: 'Dizi tanımlama, fonksiyona parametre geçirme ve ortalama hesaplama örneği.',
      descriptionEn: 'Declaring arrays, passing them to functions, and computing averages.',
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
    ),
    ProjectTemplate(
      id: 'struct',
      title: '4. Struct ve Dinamik Bellek (malloc/free)',
      titleEn: '4. Struct & Dynamic Memory (malloc/free)',
      description: 'C yapısı (struct), işaretçiler (pointers) ve dinamik bellek yönetimi şablonu.',
      descriptionEn: 'C struct, pointers, dynamic memory allocation with malloc and free.',
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
    ),
    ProjectTemplate(
      id: 'fileio',
      title: '5. Dosya Islemleri (fopen / fprintf / fgets)',
      titleEn: '5. File Operations (fopen / fprintf / fgets)',
      description: 'Diske metin dosyası oluşturma, satır satır yazma ve tekrar okuma işlemleri.',
      descriptionEn: 'Creating text files on disk, writing lines, and reading file content.',
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
    ),
    ProjectTemplate(
      id: 'empty',
      title: '6. Bos C Projesi',
      titleEn: '6. Empty C Project',
      description: 'Sıfırdan kodlamak için tertemiz boş bir C kaynak dosyası.',
      descriptionEn: 'A clean, blank C source file to code completely from scratch.',
      initialCode: '''#include <stdio.h>

int main(void) {

    return 0;
}
''',
    ),
  ];
}
