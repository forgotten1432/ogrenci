import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/database_service.dart';

/// Haftalık ve Aylık Ders Durumu Rapor Sayfası
class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  // Seçili hafta/ay
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  Map<String, Map<String, Map<String, dynamic>>> _attendanceData = {};

  // Aylık form düzenlenebilir veriler
  List<Map<String, String>> _monthlySummaryData = [];

  // Uygurca gün isimleri (Pazar hariç, 6 gün)
  static const List<String> _uyghurDays = [
    'دۈشەنبە', // Pazartesi
    'سەيشەنبە', // Salı
    'چارشەنبە', // Çarşamba
    'پەيشەنبە', // Perşembe
    'جۈمە', // Cuma
    'شەنبە', // Cumartesi
  ];

  // Haftanın başlangıcını al (Pazartesi)
  static DateTime _getWeekStart(DateTime date) {
    int diff = date.weekday - 1; // Pazartesi = 1
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Öğrencileri al (izinli olanları hariç tut)
      final studentsSnapshot = await _dbService.getAllStudents();
      _students = studentsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((student) => student['on_leave'] != true)
          .toList();

      // Ana ekranla aynı sıralama: sort_order alanına göre
      _students.sort((a, b) {
        final aOrder = a['sort_order'] as int?;
        final bOrder = b['sort_order'] as int?;
        if (aOrder != null && bOrder != null) return aOrder.compareTo(bOrder);
        if (aOrder != null) return -1;
        if (bOrder != null) return 1;
        return 0;
      });

      // Tüm ders kayıtlarını al
      final logsSnapshot = await _dbService.getAllLogs();
      _attendanceData.clear();

      for (var doc in logsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final studentId = data['student_id'] as String?;
        final dateString = data['date_string'] as String?;

        if (studentId != null && dateString != null) {
          _attendanceData[studentId] ??= {};
          _attendanceData[studentId]![dateString] = data;
        }
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
    }

    setState(() => _isLoading = false);
  }

  // Hafta günlerini al (Pazar hariç)
  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(6, (i) => weekStart.add(Duration(days: i)));
  }

  // Ay günlerini al (Pazar hariç)
  List<DateTime> _getMonthDays(DateTime month) {
    List<DateTime> days = [];
    DateTime current = DateTime(month.year, month.month, 1);
    DateTime nextMonth = DateTime(month.year, month.month + 1, 1);

    while (current.isBefore(nextMonth)) {
      if (current.weekday != 7) {
        // Pazar değilse
        days.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("دەرس ئەھۋالى"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "ھەپتىلىك", icon: Icon(Icons.calendar_view_week)),
            Tab(text: "ئايلىق", icon: Icon(Icons.calendar_month)),
          ],
        ),
        toolbarHeight: 40,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "PDF چۈشۈرۈش",
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "يېڭىلاش",
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyView(),
                _buildMonthlyView(),
              ],
            ),
    );
  }

  void _downloadPdf() {
    if (_tabController.index == 0) {
      // Haftalık
      final weekDays = _getWeekDays(_selectedWeekStart);
      _generateWeeklyPdf(weekDays);
    } else {
      // Aylık
      final monthDays = _getMonthDays(_selectedMonth);
      _generateMonthlyPdf(monthDays);
    }
  }

  // ==================== HAFTALIK GÖRÜNÜM ====================
  Widget _buildWeeklyView() {
    final weekDays = _getWeekDays(_selectedWeekStart);

    return Column(
      children: [
        // Hafta Seçici
        _buildWeekSelector(),

        // Tablo
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text("ئوقۇغۇچى تېپىلمىدى"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: _buildWeeklyTable(weekDays),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector() {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 5));
    final dateFormat = DateFormat('dd/MM');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.teal.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedWeekStart =
                    _selectedWeekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              "${dateFormat.format(_selectedWeekStart)} - ${dateFormat.format(weekEnd)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final now = DateTime.now();
              final nextWeek = _selectedWeekStart.add(const Duration(days: 7));
              if (nextWeek.isBefore(now) ||
                  nextWeek.isAtSameMomentAs(_getWeekStart(now))) {
                setState(() {
                  _selectedWeekStart = nextWeek;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTable(List<DateTime> weekDays) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
      border: TableBorder.all(color: Colors.grey.shade300),
      columnSpacing: 12,
      dataRowMinHeight: 80,
      dataRowMaxHeight: 110,
      columns: [
        const DataColumn(
            label: Text("ئوقۇغۇچى",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ...weekDays.map((day) => DataColumn(
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_uyghurDays[day.weekday - 1],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(DateFormat('dd').format(day),
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            )),
      ],
      rows: _students.map((student) {
        final studentId = student['id'] as String;
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 100,
                child: Text(student['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),
            ...weekDays.map((day) {
              final dateStr = DateFormat('yyyy-MM-dd').format(day);
              final log = _attendanceData[studentId]?[dateStr];
              return DataCell(_buildLessonCell(log, day));
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLessonCell(Map<String, dynamic>? log, DateTime day) {
    // Gelecek tarih kontrolü
    if (day.isAfter(DateTime.now())) {
      return const SizedBox(
        width: 120,
        child: Center(
            child:
                Text("-", style: TextStyle(color: Colors.grey, fontSize: 14))),
      );
    }

    if (log == null) {
      // Kayıt yok
      return const SizedBox(
        width: 120,
        child: Center(
            child:
                Text("—", style: TextStyle(color: Colors.grey, fontSize: 18))),
      );
    }

    final attended = log['attended'] ?? false;
    final lesson = log['lesson'] ?? "";
    final pageCount = log['page_count'] ?? 0;
    final juzCount = log['juz_count'] ?? 0;
    final lineCount = log['line_count'] ?? 0;

    if (!attended) {
      return SizedBox(
        width: 120,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(lesson.isNotEmpty ? lesson : "ئۆتكۈزمىدى",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: lesson.length > 5 ? 9 : 11,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Miktar bilgisini oluştur
    // Miktar bilgisini oluştur
    List<String> parts = [];
    if (juzCount > 0) parts.add("$juzCount پارە");
    if (pageCount > 0) parts.add("$pageCount بەت");
    if (lineCount > 0) parts.add("$lineCount قۇر");
    String quantityText = parts.join(" ");

    // Ders detaylarını göster
    return SizedBox(
      width: 120,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Miktar ve Takrar aynı satırda göster
            if (quantityText.isNotEmpty || log['is_takrar'] == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Miktar göster (sağda - RTL'de önce görünür)
                  if (quantityText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quantityText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  // Takrar badge (solda - RTL'de sonra görünür)
                  if (log['is_takrar'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "تەكرار",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                ],
              ),

            if (quantityText.isNotEmpty || log['is_takrar'] == true)
              const SizedBox(height: 4),

            // Ders detayı (altta)
            // Ders detayı (altta)
            // Eğer ders metni miktar bilgisini içeriyorsa, tekrar gösterme
            if (lesson.isNotEmpty)
              Builder(builder: (context) {
                String displayLesson = lesson;

                // Miktar bilgilerini tek tek temizle
                if (juzCount > 0) {
                  displayLesson =
                      displayLesson.replaceAll('$juzCount پارە', '').trim();
                }
                if (pageCount > 0) {
                  displayLesson =
                      displayLesson.replaceAll('$pageCount بەت', '').trim();
                }
                if (lineCount > 0) {
                  displayLesson =
                      displayLesson.replaceAll('$lineCount قۇر', '').trim();
                }

                // Olası virgül ve boşlukları temizle
                displayLesson =
                    displayLesson.replaceAll(RegExp(r'^[،,\s]+'), '');
                displayLesson =
                    displayLesson.replaceAll(RegExp(r'[،,\s]+$'), '');
                displayLesson =
                    displayLesson.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

                if (displayLesson.isEmpty) return const SizedBox.shrink();

                return Expanded(
                  child: Center(
                    child: Text(
                      displayLesson,
                      style: const TextStyle(fontSize: 9, color: Colors.teal),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              })
            else if (quantityText.isEmpty)
              const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  // ==================== AYLIK GÖRÜNÜM ====================
  // Fotoğraftaki forma uygun aylık özet tablosu (düzenlenebilir):
  // No | الاسم | بداية الشهر | نهاية الشهر | الإذن | الحضور | الحفظ الشهري | الحفظ / المراجعة

  /// Lesson metninden BAŞLANGIÇ konumunu çıkarır
  /// Format: "الفاتحة 1-ئايەتتىن البقرة 5-ئايەتكىچە، 2 بەت، 1 پارە"
  /// Sonuç: "الفاتحة 1"
  String _extractLessonStart(String lesson) {
    String cleaned = _cleanLessonQuantity(lesson);
    if (cleaned.contains('ئايەتتىن')) {
      String startPart = cleaned.split('ئايەتتىن')[0].trim();
      startPart = startPart.replaceAll(RegExp(r'-$'), '').trim();
      return startPart;
    }
    return cleaned;
  }

  /// Lesson metninden BİTİŞ konumunu çıkarır
  /// Format: "الفاتحة 1-ئايەتتىن البقرة 5-ئايەتكىچە، 2 بەت، 1 پارە"
  /// Sonuç: "البقرة 5"
  String _extractLessonEnd(String lesson) {
    String cleaned = _cleanLessonQuantity(lesson);
    if (cleaned.contains('ئايەتتىن') && cleaned.contains('ئايەتكىچە')) {
      String afterStart = cleaned.split('ئايەتتىن')[1].trim();
      String endPart = afterStart.split('ئايەتكىچە')[0].trim();
      endPart = endPart.replaceAll(RegExp(r'-$'), '').trim();
      return endPart;
    }
    // Sadece başlangıç varsa, onu bitiş olarak da kullan
    if (cleaned.contains('ئايەتتىن')) {
      String startPart = cleaned.split('ئايەتتىن')[0].trim();
      startPart = startPart.replaceAll(RegExp(r'-$'), '').trim();
      return startPart;
    }
    return cleaned;
  }

  /// Ders metninden miktar bilgilerini temizler
  String _cleanLessonQuantity(String lesson) {
    String cleaned = lesson;
    cleaned = cleaned.replaceAll(RegExp(r'\d+ بەت'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\d+ پارە'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\d+ قۇر'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[،,]+\s*$'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[،,]+'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return cleaned;
  }

  /// Her öğrenci için aylık özet verisini hesaplar
  Map<String, String> _calculateStudentMonthlySummary(
      String studentId, List<DateTime> monthDays) {
    int attendanceCount = 0;
    int permissionCount = 0;
    int hifzPages = 0;
    int hifzJuz = 0;
    int murajaaPages = 0;
    int murajaaJuz = 0;

    String? firstLessonText; // Ayın ilk dersi
    String? lastLessonText; // Ayın son dersi

    // Ayın günlerini sıralı şekilde tara
    List<DateTime> sortedDays = List.from(monthDays)
      ..sort((a, b) => a.compareTo(b));

    for (var day in sortedDays) {
      if (day.isAfter(DateTime.now())) continue;

      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final log = _attendanceData[studentId]?[dateStr];

      if (log == null) continue;

      if (log['attended'] == true) {
        attendanceCount++;

        // Sayfa/Cüz miktarlarını topla (satır ALMIYORUZ)
        int pc = log['page_count'] ?? 0;
        int jc = log['juz_count'] ?? 0;

        // Takrar/Hıfz durumu
        if (log['is_takrar'] == true) {
          murajaaPages += pc;
          murajaaJuz += jc;
        } else {
          hifzPages += pc;
          hifzJuz += jc;
        }

        // Ders bilgisi
        String lesson = log['lesson'] ?? '';
        if (lesson.isNotEmpty) {
          if (firstLessonText == null) {
            firstLessonText = lesson;
          }
          lastLessonText = lesson;
        }
      } else {
        // Devam etmedi - izin sayısı
        String reason = log['lesson'] ?? '';
        if (reason.contains('رۇخسەت') || reason.contains('كىسەل')) {
          permissionCount++;
        }
      }
    }

    // Aylık ezberleme miktarı metni (Arapça)
    List<String> hifzParts = [];
    if (hifzJuz > 0) hifzParts.add("$hifzJuz جزء");
    if (hifzPages > 0) hifzParts.add("$hifzPages صفحة");
    String monthlyHifzAmount = hifzParts.join(" ");

    // Aylık tekrar miktarı metni (Arapça)
    List<String> murajaaParts = [];
    if (murajaaJuz > 0) murajaaParts.add("$murajaaJuz جزء");
    if (murajaaPages > 0) murajaaParts.add("$murajaaPages صفحة");
    String monthlyMurajaaAmount = murajaaParts.join(" ");

    // بداية الشهر: İlk dersin BAŞLANGIÇ konumu
    String startOfMonth =
        firstLessonText != null ? _extractLessonStart(firstLessonText) : '';
    // نهاية الشهر: Son dersin BİTİŞ konumu
    String endOfMonth =
        lastLessonText != null ? _extractLessonEnd(lastLessonText) : '';

    return {
      'startOfMonth': startOfMonth,
      'endOfMonth': endOfMonth,
      'permissionCount': permissionCount.toString(),
      'attendanceCount': attendanceCount.toString(),
      'monthlyHifzAmount': monthlyHifzAmount,
      'monthlyMurajaaAmount': monthlyMurajaaAmount,
    };
  }

  /// Aylık düzenlenebilir verileri başlat/güncelle
  void _initMonthlySummaryData() {
    final monthDays = _getMonthDays(_selectedMonth);
    _monthlySummaryData = _students.map((student) {
      final studentId = student['id'] as String;
      final summary = _calculateStudentMonthlySummary(studentId, monthDays);
      summary['name'] = student['name'] ?? ''; // İsim alanını ekle
      return summary;
    }).toList();
  }

  Widget _buildMonthlyView() {
    // Veriler yüklendiyse ve monthlySummary boşsa veya öğrenci sayısı değiştiyse → yeniden hesapla
    if (_monthlySummaryData.length != _students.length) {
      _initMonthlySummaryData();
    }

    return Column(
      children: [
        // Ay Seçici
        _buildMonthSelector(),

        // Başlık
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.orange.shade50,
          child: Column(
            children: [
              const Text(
                "قائمة الدروس الشهري للطلاب",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  "(${_selectedMonth.month.toString().padLeft(2, '0')} / ${_selectedMonth.year})",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Tablo (düzenlenebilir)
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text("ئوقۇغۇچى تېپىلمىدى"))
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _buildMonthlySummaryTable(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.orange.shade100),
      border: TableBorder.all(color: Colors.grey.shade400, width: 1),
      columnSpacing: 12,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 68,
      columns: const [
        DataColumn(
          label: Text("No",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("الاسم",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("بداية الشهر",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("نهاية الشهر",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("الإذن",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("الحضور",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("الحفظ الشهري",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
        DataColumn(
          label: Text("المراجعة الشهري",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
        ),
      ],
      rows: _students.asMap().entries.map((entry) {
        final index = entry.key;
        final student = entry.value;

        // _monthlySummaryData güvenlik kontrolü
        if (index >= _monthlySummaryData.length)
          return const DataRow(cells: []);

        final data = _monthlySummaryData[index];

        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>(
            (states) => index.isEven ? Colors.white : Colors.grey.shade50,
          ),
          cells: [
            // No
            DataCell(
              SizedBox(
                width: 30,
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // الاسم (Düzenlenebilir)
            DataCell(
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey('name_${_selectedMonth.month}_$index'),
                  initialValue: data['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['name'] = val;
                  },
                ),
              ),
            ),
            // بداية الشهر (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 150,
                child: TextFormField(
                  key: ValueKey('start_${_selectedMonth.month}_$index'),
                  initialValue: data['startOfMonth'] ?? '',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['startOfMonth'] = val;
                  },
                ),
              ),
            ),
            // نهاية الشهر (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 150,
                child: TextFormField(
                  key: ValueKey('end_${_selectedMonth.month}_$index'),
                  initialValue: data['endOfMonth'] ?? '',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['endOfMonth'] = val;
                  },
                ),
              ),
            ),
            // الإذن (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 50,
                child: TextFormField(
                  key: ValueKey('perm_${_selectedMonth.month}_$index'),
                  initialValue: (data['permissionCount'] ?? '0') == '0'
                      ? ''
                      : data['permissionCount'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['permissionCount'] = val;
                  },
                ),
              ),
            ),
            // الحضور (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 50,
                child: TextFormField(
                  key: ValueKey('att_${_selectedMonth.month}_$index'),
                  initialValue: data['attendanceCount'] ?? '0',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['attendanceCount'] = val;
                  },
                ),
              ),
            ),
            // الحفظ الشهري (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey('hifz_amount_${_selectedMonth.month}_$index'),
                  initialValue: data['monthlyHifzAmount'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['monthlyHifzAmount'] = val;
                  },
                ),
              ),
            ),
            // المراجعة الشهري (düzenlenebilir)
            DataCell(
              SizedBox(
                width: 120,
                child: TextFormField(
                  key:
                      ValueKey('murajaa_amount_${_selectedMonth.month}_$index'),
                  initialValue: data['monthlyMurajaaAmount'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (val) {
                    _monthlySummaryData[index]['monthlyMurajaaAmount'] = val;
                  },
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
      'يانۋار',
      'فېۋرال',
      'مارت',
      'ئاپرېل',
      'ماي',
      'ئىيۇن',
      'ئىيۇل',
      'ئاۋغۇست',
      'سېنتەبىر',
      'ئۆكتەبىر',
      'نويابىر',
      'دېكابىر'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.orange.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                _monthlySummaryData.clear();
              });
            },
          ),
          Text(
            "${months[_selectedMonth.month - 1]} ${_selectedMonth.year}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final now = DateTime.now();
              if (_selectedMonth.year < now.year ||
                  (_selectedMonth.year == now.year &&
                      _selectedMonth.month < now.month)) {
                setState(() {
                  _selectedMonth =
                      DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  _monthlySummaryData.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ==================== PDF OLUŞTURMA ====================
  Future<void> _generateWeeklyPdf(List<DateTime> weekDays) async {
    try {
      // Uygurca font yükleme
      Uint8List? fontData;
      pw.Font? ttf;

      try {
        // Noto Naskh Arabic فونتى ئۇيغۇرچە ھەرپلەرنى توغرا ئۇلايدۇ
        fontData = await rootBundle
            .load('assets/fonts/NotoNaskhArabic.ttf')
            .then((data) => data.buffer.asUint8List());
        ttf = pw.Font.ttf(fontData!.buffer.asByteData());
      } catch (e) {
        // ئەگەر Noto تېپىلمىسا، ئەسلى فونتنى ئىشلەت
        debugPrint('Noto font bulunamadı, UyghurFont deneniyor: $e');
        try {
          fontData = await rootBundle
              .load('assets/fonts/UyghurFont.ttf')
              .then((data) => data.buffer.asUint8List());
          ttf = pw.Font.ttf(fontData!.buffer.asByteData());
        } catch (e2) {
          debugPrint('Font yüklenemedi: $e2');
        }
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM');
      final weekStart = weekDays.first;
      final weekEnd = weekDays.last;

      final textStyle = pw.TextStyle(font: ttf, fontSize: 11);
      final headerStyle =
          pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold);
      final titleStyle =
          pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold);

      // RTL için başlıkları sağdan sola sırala
      final headers = [
        ...weekDays.reversed.map((d) =>
            '${_uyghurDays[d.weekday - 1]}\n${DateFormat('dd').format(d)}'),
        'ئوقۇغۇچى', // Öğrenci adı en sağda
      ];

      // RTL için verileri sağdan sola sırala
      // RTL için verileri sağdan sola sırala
      // (tableData değişkeni artık kullanılmıyor, pw.Table içinde doğrudan map yapıyoruz)

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(12),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Text('ھەپتىلىك دەرس ئەھۋالى', style: titleStyle),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}',
                style: headerStyle,
              ),
            ),
            pw.SizedBox(height: 16),

            // RTL Tablo
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  for (int i = 0; i < headers.length; i++)
                    i: (i == headers.length - 1)
                        ? const pw.FixedColumnWidth(60) // Öğrenci ismi
                        : const pw.FlexColumnWidth(1), // Günler
                },
                children: [
                  // Başlık Satırı
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey400, width: 1)),
                    ),
                    children: headers
                        .map((h) => pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.center,
                              child: pw.Text(h,
                                  style: headerStyle.copyWith(
                                      color: PdfColors.teal),
                                  textAlign: pw.TextAlign.center),
                            ))
                        .toList(),
                  ),
                  // Veri Satırları
                  ..._students.map((student) {
                    final studentId = student['id'] as String;
                    return pw.TableRow(
                      children: [
                        // Günler (Ters çevrilmiş hafta günleri)
                        ...weekDays.reversed.map((day) {
                          if (day.isAfter(DateTime.now())) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              height: 50, // Sabit yükseklik
                              alignment: pw.Alignment.center,
                              child: pw.Text('-',
                                  style: textStyle.copyWith(
                                      color: PdfColors.black)),
                            );
                          }

                          final dateStr = DateFormat('yyyy-MM-dd').format(day);
                          final log = _attendanceData[studentId]?[dateStr];

                          if (log == null) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              height: 50,
                              alignment: pw.Alignment.center,
                              child: pw.Text('—',
                                  style: textStyle.copyWith(
                                      color: PdfColors.grey)),
                            );
                          }

                          final lesson = log['lesson'] ?? '';

                          if (log['attended'] != true) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              height: 50,
                              alignment: pw.Alignment.center,
                              // color: PdfColors.red50, // Removed background color
                              child: pw.Text(
                                lesson.isNotEmpty ? lesson : 'ئۆتكۈزمىدى',
                                style: textStyle.copyWith(color: PdfColors.red),
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.center,
                              ),
                            );
                          }

                          // Miktar bilgisi
                          int pageCount = log['page_count'] ?? 0;
                          int juzCount = log['juz_count'] ?? 0;
                          int lineCount = log['line_count'] ?? 0;

                          List<String> parts = [];
                          // Sıralama: Cüz -> Sayfa -> Satır
                          if (juzCount > 0) parts.add('$juzCount پارە');
                          if (pageCount > 0) parts.add('$pageCount بەت');
                          if (lineCount > 0) parts.add('$lineCount قۇر');
                          String quantityText = parts.join(' ');

                          String displayLesson = lesson;

                          // Miktar bilgilerini tek tek temizle
                          if (juzCount > 0) {
                            displayLesson = displayLesson
                                .replaceAll('$juzCount پارە', '')
                                .trim();
                          }
                          if (pageCount > 0) {
                            displayLesson = displayLesson
                                .replaceAll('$pageCount بەت', '')
                                .trim();
                          }
                          if (lineCount > 0) {
                            displayLesson = displayLesson
                                .replaceAll('$lineCount قۇر', '')
                                .trim();
                          }

                          // Olası virgül ve boşlukları temizle
                          displayLesson =
                              displayLesson.replaceAll(RegExp(r'^[،,\s]+'), '');
                          displayLesson =
                              displayLesson.replaceAll(RegExp(r'[،,\s]+$'), '');
                          displayLesson = displayLesson
                              .replaceAll(RegExp(r'\s{2,}'), ' ')
                              .trim();

                          return pw.Container(
                            padding: const pw.EdgeInsets.all(
                                6), // Changed from 4 to 6
                            // Hücre içeriği
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // Miktar ve Takrar aynı satırda
                                if (quantityText.isNotEmpty ||
                                    log['is_takrar'] == true)
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    mainAxisSize: pw.MainAxisSize.min,
                                    children: [
                                      // Miktar Kutusu (sağda - RTL'de önce görünür)
                                      if (quantityText.isNotEmpty)
                                        pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 3),
                                          child: pw.Text(
                                            quantityText,
                                            style: textStyle.copyWith(
                                                color: PdfColors.purple,
                                                fontWeight: pw.FontWeight.bold,
                                                fontSize: 9),
                                            textDirection: pw.TextDirection.rtl,
                                            textAlign: pw.TextAlign.center,
                                          ),
                                        ),
                                      // Takrar Badge (solda - RTL'de sonra görünür)
                                      if (log['is_takrar'] == true)
                                        pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 2),
                                          margin: const pw.EdgeInsets.only(
                                              right: 6),
                                          child: pw.Text(
                                            "تەكرار",
                                            style: textStyle.copyWith(
                                                color: PdfColors.orange,
                                                fontSize: 8,
                                                fontWeight: pw.FontWeight.bold),
                                            textDirection: pw.TextDirection.rtl,
                                          ),
                                        ),
                                    ],
                                  ),
                                if (quantityText.isNotEmpty ||
                                    log['is_takrar'] == true)
                                  pw.SizedBox(height: 4),

                                // Ders Metni
                                if (displayLesson.isNotEmpty)
                                  pw.Text(
                                    displayLesson,
                                    style: textStyle.copyWith(
                                        fontSize: 10, color: PdfColors.black),
                                    textDirection: pw.TextDirection.rtl,
                                    textAlign: pw.TextAlign.center,
                                    maxLines: 4,
                                  )
                                else if (quantityText.isEmpty)
                                  pw.Text('✓',
                                      style: textStyle.copyWith(
                                          color: PdfColors.black)),
                              ],
                            ),
                          );
                        }).toList(),
                        // Öğrenci Adı (En sağda)
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(student['name'] ?? '',
                              style: textStyle.copyWith(
                                  color: PdfColors.teal,
                                  fontWeight: pw.FontWeight.bold),
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.center),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      );

      // PDF'i kaydet
      final pdfBytes = await pdf.save();
      final fileName =
          'haftalik_rapor_${DateFormat('yyyyMMdd').format(weekStart)}.pdf';

      // iOS ve Web için sharePdf kullan, diğerleri için layoutPdf
      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF ھاسىل قىلىشتا خاتالىق: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateMonthlyPdf(List<DateTime> monthDays) async {
    try {
      Uint8List? fontData;
      pw.Font? ttf;

      try {
        fontData = await rootBundle
            .load('assets/fonts/NotoNaskhArabic.ttf')
            .then((data) => data.buffer.asUint8List());
        ttf = pw.Font.ttf(fontData!.buffer.asByteData());
      } catch (e) {
        debugPrint('Noto font bulunamadı, UyghurFont deneniyor: $e');
        try {
          fontData = await rootBundle
              .load('assets/fonts/UyghurFont.ttf')
              .then((data) => data.buffer.asUint8List());
          ttf = pw.Font.ttf(fontData!.buffer.asByteData());
        } catch (e2) {
          debugPrint('Font yüklenemedi: $e2');
        }
      }

      final pdf = pw.Document();

      final textStyle = pw.TextStyle(font: ttf, fontSize: 10);
      final headerStyle =
          pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold);
      final titleStyle =
          pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold);
      final subtitleStyle =
          pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);

      // RTL sütun sırası (sağdan sola): م | الاسم | بداية الشهر | نهاية الشهر | الإذن | الحضور | الحفظ الشهري | الحفظ / المراجعة
      // PDF'te sütunlar fiziksel olarak soldan sağa sıralanır, o yüzden ters çeviriyoruz
      final tableHeadersReversed = [
        'المراجعة الشهري',
        'الحفظ الشهري',
        'الحضور',
        'الإذن',
        'نهاية الشهر',
        'بداية الشهر',
        'الاسم',
        'م',
      ];

      // Düzenlenmiş veriyi kullan (monthlySummaryData varsa)
      if (_monthlySummaryData.length != _students.length) {
        _initMonthlySummaryData();
      }

      // Tablo verileri - minimum 22 satır (fotoğraftaki gibi)
      int totalRows = _students.length < 22 ? 22 : _students.length;
      List<List<String>> tableData = [];

      for (int i = 0; i < totalRows; i++) {
        if (i < _students.length && i < _monthlySummaryData.length) {
          final student = _students[i];
          final data = _monthlySummaryData[i];

          // Ters sıra (RTL): sağdaki sütun ilk sırada
          tableData.add([
            data['monthlyMurajaaAmount'] ?? '',
            data['monthlyHifzAmount'] ?? '',
            data['attendanceCount'] ?? '0',
            (data['permissionCount'] ?? '0') != '0'
                ? data['permissionCount']!
                : '',
            data['endOfMonth'] ?? '',
            data['startOfMonth'] ?? '',
            data['name'] ?? '',
            (i + 1).toString(),
          ]);
        } else {
          // Boş satır
          tableData.add(['', '', '', '', '', '', '', (i + 1).toString()]);
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.portrait,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Başlık
            pw.Center(
              child: pw.Text('قائمة الدروس الشهري للطلاب',
                  style: titleStyle, textDirection: pw.TextDirection.rtl),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '(${_selectedMonth.month.toString().padLeft(2, '0')} / ${_selectedMonth.year})',
                style: subtitleStyle,
              ),
            ),
            pw.SizedBox(height: 16),

            // Ana tablo (RTL - sütunlar ters sırada)
            pw.TableHelper.fromTextArray(
              headers: tableHeadersReversed,
              data: tableData,
              headerStyle: headerStyle,
              cellStyle: textStyle,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              cellAlignments: {
                6: pw.Alignment.centerRight, // الاسم - sağa hizalı
              },
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.8),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FlexColumnWidth(2), // المراجعة الشهري
                1: const pw.FlexColumnWidth(2), // الحفظ الشهري
                2: const pw.FixedColumnWidth(40), // الحضور
                3: const pw.FixedColumnWidth(35), // الإذن
                4: const pw.FlexColumnWidth(2.5), // نهاية الشهر
                5: const pw.FlexColumnWidth(2.5), // بداية الشهر
                6: const pw.FlexColumnWidth(2.5), // الاسم
                7: const pw.FixedColumnWidth(25), // م
              },
            ),
          ],
        ),
      );

      // PDF'i kaydet
      final pdfBytes = await pdf.save();
      final fileName =
          'aylik_rapor_${DateFormat('yyyyMM').format(_selectedMonth)}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF ھاسىل قىلىشتا خاتالىق: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
