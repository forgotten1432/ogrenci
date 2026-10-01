import 'package:flutter/material.dart';

import 'package:intl/intl.dart' hide TextDirection;
import '../services/database_service.dart';

class TrackingFormPage extends StatefulWidget {
  const TrackingFormPage({super.key});

  @override
  State<TrackingFormPage> createState() => _TrackingFormPageState();
}

class _TrackingFormPageState extends State<TrackingFormPage> {
  final DatabaseService _dbService = DatabaseService();
  DateTime _currentMonth = DateTime.now();


  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool _isSyncingScroll = false;

  static const Map<String, String> _studentTypes = {
    'tam_gun': 'پۈتۈن كۈن',
    'ogleden_once': 'چۈشتىن بۇرۇن',
    'ogleden_sonra': 'چۈشتىن كىيىن',
  };

  static const Map<String, String> _statusLabels = {
    'v': 'كەلگەن',
    'x': 'كەلمىگەن',
    'R': 'رۇخسەت',
    'K': 'كىسەل',
  };

  static const Map<String, Color> _statusColors = {
    'v': Colors.green,
    'x': Colors.red,
    'R': Colors.orange,
    'K': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    _bodyScrollController.addListener(() {
      if (_isSyncingScroll) return;
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _isSyncingScroll = true;
        _headerScrollController.jumpTo(_bodyScrollController.offset);
        _isSyncingScroll = false;
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _scrollToToday(double dayWidth, int todayDay) {
    if (todayDay <= 0) return;
    if (_bodyScrollController.hasClients) {
      final target = ((todayDay - 1) * dayWidth).clamp(
        0.0,
        _bodyScrollController.position.maxScrollExtent,
      );
      _bodyScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddStudentDialog() {
    String name = '';
    String selectedType = 'ogleden_sonra';
    final timeController = TextEditingController(text: '14:00');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("يېڭى ئوقۇغۇچى قوشۇش",
              textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "ئىسىم",
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: "ۋاقتى",
                  border: OutlineInputBorder(),
                ),
                items: _studentTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, textDirection: TextDirection.rtl),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: "كېلىش سائىتى (مەسىلەن: 14:00)",
                  hintText: "14:00",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    tooltip: "سائەت تاللاش",
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 14, minute: 0),
                      );
                      if (picked != null) {
                        final hourStr = picked.hour.toString().padLeft(2, '0');
                        final minStr = picked.minute.toString().padLeft(2, '0');
                        timeController.text = "$hourStr:$minStr";
                      }
                    },
                  ),
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("بىكار قىلىش"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;
                try {
                  await _dbService.addTrackingStudent(
                    name,
                    selectedType,
                    arrivalTime: timeController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ئوقۇغۇچى قوشۇلدى'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('خاتالىق يۈز بەردى'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("قوشۇش"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(
      String studentId, String currentName, String currentType, String currentArrivalTime) {
    String name = currentName;
    String selectedType = currentType;
    final timeController = TextEditingController(text: currentArrivalTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("ئوقۇغۇچى تەھرىرلەش",
              textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: name),
                decoration: const InputDecoration(
                  labelText: "ئىسىم",
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: "ۋاقتى",
                  border: OutlineInputBorder(),
                ),
                items: _studentTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, textDirection: TextDirection.rtl),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: "كېلىش سائىتى (مەسىلەن: 14:00)",
                  hintText: "14:00",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    tooltip: "سائەت تاللاش",
                    onPressed: () async {
                      TimeOfDay initial = const TimeOfDay(hour: 14, minute: 0);
                      if (timeController.text.contains(':')) {
                        final parts = timeController.text.split(':');
                        final h = int.tryParse(parts[0]);
                        final m = int.tryParse(parts[1]);
                        if (h != null && m != null) {
                          initial = TimeOfDay(hour: h, minute: m);
                        }
                      }
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                      );
                      if (picked != null) {
                        final hourStr = picked.hour.toString().padLeft(2, '0');
                        final minStr = picked.minute.toString().padLeft(2, '0');
                        timeController.text = "$hourStr:$minStr";
                      }
                    },
                  ),
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("بىكار قىلىش"),
            ),
            TextButton(
              onPressed: () async {
                final conf = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("ئۆچۈرۈش"),
                    content: Text("$currentName ئۆچۈرۈلسۇنمۇ؟"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("ياق")),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text("ھەئە"),
                      ),
                    ],
                  ),
                );
                if (conf == true) {
                  await _dbService.deleteTrackingStudent(studentId);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("ئۆچۈرۈش (Delete)"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;
                try {
                  await _dbService.updateTrackingStudent(
                    studentId,
                    name,
                    selectedType,
                    arrivalTime: timeController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("ئۆزگەرتىلدى"),
                          backgroundColor: Colors.blue),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("خاتالىق يۈز بەردى"),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text("ساقلاش"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCellTap(
      String studentId, String yearMonth, int day, String? currentStatus) async {
    final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    if (dayDate.weekday == DateTime.sunday) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "$day - كۈن ئەھۋالى",
            textDirection: TextDirection.rtl,
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ..._statusLabels.entries.map((entry) => ChoiceChip(
                    label: Text(
                        "${entry.value} (${entry.key == 'v' ? '✓' : entry.key})"),
                    selected: currentStatus == entry.key,
                    selectedColor:
                        _statusColors[entry.key]?.withValues(alpha: 0.3),
                    onSelected: (selected) {
                      Navigator.pop(context, entry.key);
                    },
                  )),
              ChoiceChip(
                label: const Text("تازىلاش"),
                selected: currentStatus == null,
                selectedColor: Colors.grey.shade300,
                onSelected: (selected) {
                  Navigator.pop(context, 'clear');
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      if (result == 'clear') {
        await _dbService.updateTrackingAttendance(
            studentId, yearMonth, day, null);
      } else {
        await _dbService.updateTrackingAttendance(
            studentId, yearMonth, day, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearMonth = DateFormat('yyyy-MM').format(_currentMonth);
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    final now = DateTime.now();
    final isCurrentMonth =
        now.year == _currentMonth.year && now.month == _currentMonth.month;
    final todayDay = isCurrentMonth ? now.day : -1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("يوقلىما جەدۋىلى (Takip)"),
        actions: [
          // Yeni Öğrenci Ekle
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: "ئوقۇغۇچى قوشۇش",
            onPressed: _showAddStudentDialog,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final bool isNarrow = availableWidth < 600;

          // Sabit sütun genişlikleri (İsim, Sıra no, Vakit)
          final double colIndexWidth = isNarrow ? 26.0 : 34.0;
          final double colNameWidth = isNarrow ? 120.0 : 155.0;
          final double colTimeWidth = isNarrow ? 74.0 : 95.0;
          final double pinnedWidth =
              colIndexWidth + colNameWidth + colTimeWidth;

          // Gün sütunlarının genişlik hesabı: Ekranın kalan tüm alanını eşit olarak doldurur
          final double remainingWidth =
              (availableWidth - pinnedWidth).clamp(100.0, double.infinity);
          final double autoDayWidth = remainingWidth / daysInMonth;

          // Her açıldığında ekrana tam dolacak şekilde çalışır
          final bool isFitMode = autoDayWidth >= 16.0;
          final double dayWidth = isFitMode ? autoDayWidth : 34.0;

          const double headerHeight = 46.0;
          const double rowHeight = 44.0;

          return Column(
            children: [
              // 1. Ay Seçici ve Bilgi Çubuğu
              _buildMonthBar(todayDay, dayWidth),

              // 2. Tablo İçeriği (StreamBuilder)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getTrackingStudents(),
                  builder: (context, studentsSnapshot) {
                    if (studentsSnapshot.hasError) {
                      return const Center(child: Text("خاتالىق يۈز بەردى"));
                    }
                    if (studentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final students = studentsSnapshot.data?.docs ?? [];
                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text("تېخى ئوقۇغۇچى قوشۇلمىدى"),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _showAddStudentDialog,
                              icon: const Icon(Icons.add),
                              label: const Text("ئوقۇغۇچى قوشۇش"),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _dbService.getTrackingAttendance(yearMonth),
                      builder: (context, attendanceSnapshot) {
                        if (attendanceSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // Veri haritası: { studentId : { '1': 'v', '2': 'x' } }
                        final attendanceMap =
                            <String, Map<String, dynamic>>{};
                        for (var doc in attendanceSnapshot.data?.docs ?? []) {
                          final data = doc.data() as Map<String, dynamic>;
                          final sId = data['student_id'] as String;
                          final days =
                              data['days'] as Map<String, dynamic>? ?? {};
                          attendanceMap[sId] = days;
                        }

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              // SABİT BAŞLIK (Yukarı kaybolmaz)
                              Container(
                                height: headerHeight,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 1.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Sabit Başlıklar (Sıra, İsim, Vakit)
                                    _buildPinnedHeader(
                                      colIndexWidth,
                                      colNameWidth,
                                      colTimeWidth,
                                      headerHeight,
                                    ),
                                    // Gün Başlıkları (1..daysInMonth)
                                    Expanded(
                                      child: isFitMode
                                          ? _buildDaysHeaderRow(
                                              daysInMonth,
                                              todayDay,
                                              true,
                                              dayWidth,
                                              headerHeight,
                                            )
                                          : SingleChildScrollView(
                                              controller:
                                                  _headerScrollController,
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              child: _buildDaysHeaderRow(
                                                daysInMonth,
                                                todayDay,
                                                false,
                                                dayWidth,
                                                headerHeight,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              // KAYDIRILABİLİR GÖVDE (Öğrenci Satırları)
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  scrollDirection: Axis.vertical,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Sabit Öğrenci Sütunu (Sıra, İsim, Düzenle, Vakit)
                                      _buildPinnedStudentsColumn(
                                        students,
                                        colIndexWidth,
                                        colNameWidth,
                                        colTimeWidth,
                                        rowHeight,
                                      ),

                                      // Günler ve Yoklama Hücreleri
                                      Expanded(
                                        child: isFitMode
                                            ? _buildDaysBodyTable(
                                                students,
                                                attendanceMap,
                                                daysInMonth,
                                                true,
                                                dayWidth,
                                                rowHeight,
                                                todayDay,
                                                yearMonth,
                                              )
                                            : SingleChildScrollView(
                                                controller:
                                                    _bodyScrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                child: _buildDaysBodyTable(
                                                  students,
                                                  attendanceMap,
                                                  daysInMonth,
                                                  false,
                                                  dayWidth,
                                                  rowHeight,
                                                  todayDay,
                                                  yearMonth,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== AY SEÇİCİ ÇUBUĞU ====================
  Widget _buildMonthBar(int todayDay, double dayWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: "ئالدىنقى ئاي",
            onPressed: _previousMonth,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('yyyy - MMMM', 'tr').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              if (todayDay > 0) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _scrollToToday(dayWidth, todayDay),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.today, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          "بۈگۈن: $todayDay",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: "كېيىنكى ئاي",
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  // ==================== SABİT BAŞLIKLAR ====================
  Widget _buildPinnedHeader(
    double colIndexWidth,
    double colNameWidth,
    double colTimeWidth,
    double height,
  ) {
    return SizedBox(
      width: colIndexWidth + colNameWidth + colTimeWidth,
      child: Row(
        children: [
          SizedBox(
            width: colIndexWidth,
            height: height,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade400, width: 0.5),
                ),
              ),
              child: const Text(
                "#",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          SizedBox(
            width: colNameWidth,
            height: height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade400, width: 0.5),
                ),
              ),
              child: const Text(
                "ئىسىم فامىلە",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: colTimeWidth,
            height: height,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade500, width: 1.5),
                ),
              ),
              child: const Text(
                "ۋاقتى",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GÜN BAŞLIKLARI SATIRI ====================
  Widget _buildDaysHeaderRow(
    int daysInMonth,
    int todayDay,
    bool isFitMode,
    double dayWidth,
    double height,
  ) {
    if (isFitMode) {
      return Row(
        children: [
          for (int i = 1; i <= daysInMonth; i++)
            Expanded(
              child: _buildDayHeaderCell(i, height, todayDay),
            ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= daysInMonth; i++)
            SizedBox(
              width: dayWidth,
              child: _buildDayHeaderCell(i, height, todayDay),
            ),
        ],
      );
    }
  }

  Widget _buildDayHeaderCell(int day, double height, int todayDay) {
    final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isSunday = dayDate.weekday == DateTime.sunday;
    final isToday = day == todayDay;

    Color bgColor = Colors.transparent;
    if (isToday) {
      bgColor = Colors.teal.shade200;
    } else if (isSunday) {
      bgColor = Colors.orange.shade200;
    }

    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          left: isToday
              ? const BorderSide(color: Colors.teal, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$day",
            style: TextStyle(
              fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
              fontSize: 11,
              color: isToday
                  ? Colors.teal.shade900
                  : (isSunday ? Colors.deepOrange.shade900 : Colors.black87),
            ),
          ),
          Text(
            isSunday ? "ي" : _getShortWeekday(dayDate.weekday),
            style: TextStyle(
              fontSize: 9,
              color: isSunday ? Colors.deepOrange : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getShortWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "د";
      case DateTime.tuesday:
        return "س";
      case DateTime.wednesday:
        return "چ";
      case DateTime.thursday:
        return "پ";
      case DateTime.friday:
        return "ج";
      case DateTime.saturday:
        return "ش";
      case DateTime.sunday:
        return "ي";
      default:
        return "";
    }
  }

  // ==================== SABİT ÖĞRENCİ SÜTUNU ====================
  Widget _buildPinnedStudentsColumn(
    List<QueryDocumentSnapshot> students,
    double colIndexWidth,
    double colNameWidth,
    double colTimeWidth,
    double rowHeight,
  ) {
    return Column(
      children: [
        for (int index = 0; index < students.length; index++)
          _buildPinnedStudentRow(
            students[index],
            index,
            colIndexWidth,
            colNameWidth,
            colTimeWidth,
            rowHeight,
          ),
      ],
    );
  }

  Widget _buildPinnedStudentRow(
    QueryDocumentSnapshot studentDoc,
    int index,
    double colIndexWidth,
    double colNameWidth,
    double colTimeWidth,
    double height,
  ) {
    final sData = studentDoc.data() as Map<String, dynamic>;
    final sId = studentDoc.id;
    final name = sData['name'] ?? 'ئىسىمسىز';
    final typeKey = sData['type'] ?? 'tam_gun';
    final typeLabel = _studentTypes[typeKey] ?? '';
    final arrivalTime = (sData['arrival_time'] as String?)?.trim() ?? '';

    final bool isEven = index % 2 == 0;
    final Color rowBg = isEven ? Colors.white : Colors.grey.shade50;

    return Container(
      height: height,
      color: rowBg,
      child: SizedBox(
        width: colIndexWidth + colNameWidth + colTimeWidth,
        child: Row(
          children: [
            // Sıra No
            SizedBox(
              width: colIndexWidth,
              height: height,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    right: BorderSide(color: Colors.grey.shade400, width: 0.5),
                  ),
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontSize: colIndexWidth < 32 ? 11 : 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            // İsim ve Düzenle Butonu
            SizedBox(
              width: colNameWidth,
              height: height,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    right: BorderSide(color: Colors.grey.shade400, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 13, color: Colors.blue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 18),
                      tooltip: "تەھرىرلەش",
                      onPressed: () {
                        _showEditStudentDialog(sId, name, typeKey, arrivalTime);
                      },
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: colNameWidth < 130 ? 10.5 : 11.5,
                          height: 1.15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Vakit (Tam gün / Çüştin burun / Çüştin kéyin + saat)
            SizedBox(
              width: colTimeWidth,
              height: height,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    right: BorderSide(color: Colors.grey.shade500, width: 1.5),
                  ),
                ),
                child: arrivalTime.isNotEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            typeLabel,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: colTimeWidth < 85 ? 9.5 : 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                  color: Colors.blue.shade200, width: 0.5),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                arrivalTime,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: colTimeWidth < 85 ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        typeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: colTimeWidth < 85 ? 10 : 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GÜNLER VE YOKLAMA TABLOSU GÖVDESİ ====================
  Widget _buildDaysBodyTable(
    List<QueryDocumentSnapshot> students,
    Map<String, Map<String, dynamic>> attendanceMap,
    int daysInMonth,
    bool isFitMode,
    double dayWidth,
    double rowHeight,
    int todayDay,
    String yearMonth,
  ) {
    return Column(
      children: [
        for (int index = 0; index < students.length; index++)
          _buildDaysStudentRow(
            students[index],
            index,
            attendanceMap[students[index].id] ?? {},
            daysInMonth,
            isFitMode,
            dayWidth,
            rowHeight,
            todayDay,
            yearMonth,
          ),
      ],
    );
  }

  Widget _buildDaysStudentRow(
    QueryDocumentSnapshot studentDoc,
    int index,
    Map<String, dynamic> studentDays,
    int daysInMonth,
    bool isFitMode,
    double dayWidth,
    double height,
    int todayDay,
    String yearMonth,
  ) {
    final sId = studentDoc.id;
    final bool isEven = index % 2 == 0;
    final Color rowBg = isEven ? Colors.white : Colors.grey.shade50;

    if (isFitMode) {
      return Container(
        height: height,
        color: rowBg,
        child: Row(
          children: [
            for (int day = 1; day <= daysInMonth; day++)
              Expanded(
                child: _buildStatusCell(
                  studentDays[day.toString()] as String?,
                  day,
                  height,
                  day == todayDay,
                  onTap: () => _onCellTap(
                    sId,
                    yearMonth,
                    day,
                    studentDays[day.toString()] as String?,
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      return Container(
        height: height,
        color: rowBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int day = 1; day <= daysInMonth; day++)
              SizedBox(
                width: dayWidth,
                child: _buildStatusCell(
                  studentDays[day.toString()] as String?,
                  day,
                  height,
                  day == todayDay,
                  onTap: () => _onCellTap(
                    sId,
                    yearMonth,
                    day,
                    studentDays[day.toString()] as String?,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusCell(
    String? status,
    int day,
    double height,
    bool isToday, {
    required VoidCallback onTap,
  }) {
    final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isSunday = dayDate.weekday == DateTime.sunday;

    if (isSunday) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange.shade100.withValues(alpha: 0.6),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
      );
    }

    Widget content;
    if (status == null || !_statusColors.containsKey(status)) {
      content = Text(
        "-",
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      );
    } else {
      final color = _statusColors[status]!;
      final label = status == 'v' ? '✓' : status;
      content = Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: status == 'v' ? 14 : 11,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
            left: isToday
                ? const BorderSide(color: Colors.teal, width: 1.0)
                : BorderSide.none,
          ),
        ),
        child: content,
      ),
    );
  }
}
