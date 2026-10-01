import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/database_service.dart';

/// E-Hafız Takip için Uygurca destekli PDF Rapor Widget'ı
///
/// Bu widget Firebase'den gelen ders loglarını tablo olarak gösterir
/// ve Uygurca (RTL) destekli PDF çıktısı almayı sağlar.
///
/// Kullanım:
/// ```dart
/// ReportTable(
///   studentName: 'ئابدۇرەشىد',
///   logs: [
///     {'date': Timestamp.now(), 'lesson': 'الفاتحة سورىسى', 'attended': true, 'homework': ''},
///   ],
/// )
/// ```
class ReportTable extends StatefulWidget {
  /// Öğrenci ismi (Uygurca)
  final String studentName;

  /// Firebase'den gelen günlük log verileri
  /// Her bir map şunları içermeli:
  /// - 'date': Timestamp veya 'date_string': String
  /// - 'lesson': String
  /// - 'attended': bool
  /// - 'homework': String (opsiyonel)
  final List<Map<String, dynamic>> logs;

  const ReportTable({
    super.key,
    required this.studentName,
    required this.logs,
  });

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  bool _isGeneratingPdf = false;

  // Uygurca gün isimleri
  static const List<String> _uyghurDays = [
    'دۈشەنبە',
    'سەيشەنبە',
    'چارشەنبە',
    'پەيشەنبە',
    'جۈمە',
    'شەنبە',
    'يەكشەنبە',
  ];

  /// Timestamp'ı okunabilir tarihe çevirir
  String _formatDate(Map<String, dynamic> log) {
    Timestamp? timestamp = log['date'] as Timestamp?;
    if (timestamp != null) {
      DateTime date = timestamp.toDate();
      String dayName = _uyghurDays[date.weekday - 1];
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ($dayName)";
    }
    return log['date_string'] ?? '';
  }

  /// Durumu Uygurca metne çevirir
  String _getStatusText(bool attended) {
    return attended ? 'ئۆتكۈزدى' : 'ئۆتكۈزمىدى';
  }

  /// PDF oluşturur ve indirme/yazdırma dialogunu açar
  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      // Noto Naskh Arabic فونتى ئۇيغۇرچە ھەرپلەرنى توغرا ئۇلايدۇ
      Uint8List fontData;
      try {
        fontData = await rootBundle
            .load('assets/fonts/NotoNaskhArabic.ttf')
            .then((data) => data.buffer.asUint8List());
      } catch (e) {
        // ئەگەر Noto تېپىلمىسا، ئەسلى فونتنى ئىشلەت
        debugPrint('Noto font bulunamadı, UyghurFont deneniyor: $e');
        fontData = await rootBundle
            .load('assets/fonts/UyghurFont.ttf')
            .then((data) => data.buffer.asUint8List());
      }

      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      // PDF belgesi oluştur
      final pdf = pw.Document();

      // RTL için metin stili
      final textStyle = pw.TextStyle(
        font: ttf,
        fontSize: 12,
      );

      final headerStyle = pw.TextStyle(
        font: ttf,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      );

      final titleStyle = pw.TextStyle(
        font: ttf,
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
      );

      // Tablo verilerini hazırla
      // RTL için sütun sırası: Puan, Durum, Ders, Tarih (sağdan sola)
      final tableData = widget.logs.map((log) {
        final attended = log['attended'] ?? false;
        return [
          '—', // Puan (Nomur) - şimdilik boş
          _getStatusText(attended), // Durum (Ahwal)
          log['lesson'] ?? '', // Ders
          _formatDate(log), // Tarih
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl, // RTL desteği
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  pw.Center(
                    child: pw.Text(
                      'مىئراج دەرس ئەھۋالى',
                      style: titleStyle,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Öğrenci adı
                  pw.Center(
                    child: pw.Text(
                      'ئوقۇغۇچى: ${widget.studentName}',
                      style: headerStyle,
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Rapor tarihi
                  pw.Center(
                    child: pw.Text(
                      'چەسلا: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: textStyle,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Tablo
                  pw.TableHelper.fromTextArray(
                    context: context,
                    // RTL için başlık sırası (sağdan sola)
                    headers: ['نومۇر', 'ئەھۋال', 'دەرس', 'تارىخ'],
                    data: tableData,
                    headerStyle: headerStyle,
                    cellStyle: textStyle,
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.teal100,
                    ),
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    cellAlignments: {
                      0: pw.Alignment.center, // Puan
                      1: pw.Alignment.center, // Durum
                      2: pw
                          .Alignment.centerRight, // Ders (RTL için sağa hizalı)
                      3: pw.Alignment.center, // Tarih
                    },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                    cellPadding: const pw.EdgeInsets.all(8),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1), // Puan
                      1: const pw.FlexColumnWidth(1.5), // Durum
                      2: const pw.FlexColumnWidth(3), // Ders
                      3: const pw.FlexColumnWidth(2), // Tarih
                    },
                  ),

                  // Alt kısım - Veli imza alanı
                  pw.Spacer(),
                  pw.Divider(thickness: 0.5),
                  pw.SizedBox(height: 30),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Sağ taraf (RTL'de sol görünür) - Öğretmen
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: PdfColors.grey600,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            height: 40,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('ئوقۇتقۇچى ئىمزاسى', style: textStyle),
                        ],
                      ),
                      // Sol taraf (RTL'de sağ görünür) - Veli
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: PdfColors.grey600,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            height: 40,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('ئاتا-ئانا ئىمزاسى', style: textStyle),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      );

      // PDF'i yazdır/indir
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${widget.studentName}_دوكلاتى.pdf',
      );
    } catch (e) {
      // Font bulunamadığında hata mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF ھاسىل قىلىشتا خاتالىق: $e\n'
              'assets/fonts/UyghurFont.ttf فونتىنى تەكشۈرۈڭ.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      debugPrint('PDF oluşturma hatası: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PDF İndirme Butonu
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPdf ? null : _generatePdf,
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                _isGeneratingPdf ? 'ھاسىل قىلىۋاتىدۇ...' : 'PDF چۈشۈرۈش',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Ekrandaki Tablo Başlığı
        Container(
          color: Colors.teal.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                'دەرس خاتىرىسى',
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'جەمئىي ${widget.logs.length} خاتىرە',
                style: TextStyle(
                  color: Colors.teal.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Ekranda gösterilen tablo
        Expanded(
          child: widget.logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'تېخى دەرس خاتىرىسى يوق.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2), // Tarih
                      1: FlexColumnWidth(3), // Ders
                      2: FlexColumnWidth(1.5), // Durum
                      3: FlexColumnWidth(1), // Puan
                    },
                    children: [
                      // Başlık satırı
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                        ),
                        children: const [
                          _TableHeaderCell(text: 'تارىخ'),
                          _TableHeaderCell(text: 'دەرس'),
                          _TableHeaderCell(text: 'ئەھۋال'),
                          _TableHeaderCell(text: 'نومۇر'),
                        ],
                      ),
                      // Veri satırları
                      ...widget.logs.map((log) {
                        final attended = log['attended'] ?? false;
                        return TableRow(
                          children: [
                            _TableDataCell(
                              text: _formatDate(log),
                              isLtr: true, // Tarihler LTR
                            ),
                            _TableDataCell(text: log['lesson'] ?? ''),
                            _TableDataCell(
                              text: _getStatusText(attended),
                              textColor: attended ? Colors.green : Colors.red,
                            ),
                            const _TableDataCell(text: '—'),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Tablo başlık hücresi widget'ı
class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }
}

/// Tablo veri hücresi widget'ı
class _TableDataCell extends StatelessWidget {
  final String text;
  final Color? textColor;
  final bool isLtr;

  const _TableDataCell({
    required this.text,
    this.textColor,
    this.isLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
      ),
    );

    if (isLtr) {
      child = Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}
