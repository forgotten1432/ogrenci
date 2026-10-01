# Uygurca PDF Rapor Modülü

Bu modül, E-Hafız Takip uygulaması için Uygurca (Uyghur Language) destekli PDF rapor oluşturma özelliği sağlar.

## 🎯 Özellikler

- ✅ Uygurca (Perso-Arabic script) karakter desteği
- ✅ RTL (Sağdan Sola) yazım desteği
- ✅ Firebase verilerinden tablo oluşturma
- ✅ PDF indirme/yazdırma
- ✅ Veli imza alanı
- ✅ Öğretmen imza alanı

## 📦 Kurulum

### 1. Font Dosyası Ekleme (ÇOK ÖNEMLİ!)

Standart PDF fontları Uygurca karakterleri (ئ، ە، ب، ت) desteklemez. Bu yüzden özel bir Uygurca font dosyası eklemeniz **zorunludur**.

#### Önerilen Fontlar:
1. **UKIJ Tuz Tom** (En popüler)
2. **Alkatip** (Profesyonel görünüm)
3. **Uighur Sans** (Modern)
4. **Scheherazade New** (Arapça/Farsça destekli)

#### Font Kurulumu:
```
assets/
  fonts/
    UygurFont.ttf  <-- Font dosyanızı buraya koyun
```

Font dosyasını indirdikten sonra:
1. `assets/fonts/` klasörüne kopyalayın
2. Dosya adını `UygurFont.ttf` olarak değiştirin
3. Uygulamayı yeniden başlatın

## 📋 Kullanım

### Temel Kullanım

```dart
import 'package:e_hafiz_takip/widgets/report_table.dart';

// Widget içinde kullanım
ReportTable(
  studentName: 'ئابدۇرەشىد',
  logs: [
    {
      'date': Timestamp.now(),
      'lesson': 'الفاتحة سۈرىسى 1-ئايەتتىن 7-ئايەتكىچە',
      'attended': true,
      'homework': 'يىڭىدىن ئوقۇش',
    },
    {
      'date': Timestamp.fromDate(DateTime(2026, 1, 13)),
      'lesson': 'البقره سۈرىسى',
      'attended': true,
      'homework': '',
    },
    {
      'date_string': '2026-01-12',
      'lesson': '',
      'attended': false,
      'homework': '',
    },
  ],
)
```

### Parent Dashboard'a Entegrasyon

`parent_dashboard.dart` dosyasında kullanmak için:

```dart
import '../widgets/report_table.dart';

// StreamBuilder içinde
StreamBuilder<QuerySnapshot>(
  stream: _dbService.getStudentHistory(studentId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final logs = snapshot.data!.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();
    
    return ReportTable(
      studentName: studentData['name'] ?? 'ئوقۇغۇچى',
      logs: logs,
    );
  },
)
```

## 📊 Tablo Yapısı

### Başlıklar (Uygurca)
| Türkçe | Uygurca | Açıklama |
|--------|---------|----------|
| Tarih | تارىخ | Ders tarihi |
| Ders | دەرس | Ders içeriği |
| Durum | ئەھۋال | ئۆتكۈزدى / ئۆتكۈزمىدى |
| Puan | نومۇر | Performans puanı |

### Veri Formatı
```dart
{
  'date': Timestamp,        // veya 'date_string': String
  'lesson': String,         // Ders içeriği
  'attended': bool,         // Ders durumu
  'homework': String,       // Ödev (opsiyonel)
}
```

## 🎨 PDF Çıktısı Özellikleri

- **Sayfa Boyutu**: A4
- **Yönlendirme**: RTL (Sağdan Sola)
- **Başlık**: Ortalanmış rapor başlığı
- **Öğrenci Adı**: Başlığın altında
- **Tablo**: Renkli başlıklar, kenarlıklar
- **Alt Kısım**: Veli ve öğretmen imza alanları

## ⚠️ Dikkat Edilecekler

1. **Font Dosyası Zorunlu**: Font olmadan PDF oluşturulamaz
2. **RTL Desteği**: Tüm metinler sağdan sola yazılır
3. **Tarih Formatı**: YYYY-MM-DD (gün adı ile)
4. **Karakter Desteği**: Tüm Uygurca karakterler desteklenir

## 🔧 Sorun Giderme

### "Font bulunamadı" Hatası
```
assets/fonts/UygurFont.ttf dosyasının doğru konumda olduğunu kontrol edin.
pubspec.yaml'da assets bölümünün doğru tanımlandığından emin olun.
```

### PDF Oluşturulmuyor
```
1. flutter pub get komutunu çalıştırın
2. Uygulamayı yeniden başlatın
3. Printing paketinin doğru yüklendiğini kontrol edin
```

## 📝 Lisans

Bu modül E-Hafız Takip projesi için geliştirilmiştir.
