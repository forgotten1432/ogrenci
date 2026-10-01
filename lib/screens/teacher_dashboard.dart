import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../data/quran_data.dart';
import 'add_student_page.dart';
import 'attendance_report_page.dart';
import 'tracking_form_page.dart';
import 'login_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final DatabaseService _dbService = DatabaseService();
  bool _showOnLeaveStudents = false;
  bool _isReorderMode = false;
  List<Map<String, dynamic>> _reorderList = [];
  bool _isSavingOrder = false;

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

  void _enterReorderMode(List<QueryDocumentSnapshot> activeStudents) {
    setState(() {
      _isReorderMode = true;
      _reorderList = activeStudents.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'name': data['name'] ?? ''};
      }).toList();
    });
  }

  Future<void> _saveReorder() async {
    setState(() => _isSavingOrder = true);
    try {
      final ids = _reorderList.map((s) => s['id'] as String).toList();
      await _dbService.updateStudentsSortOrder(ids);
      if (!mounted) return;
      setState(() {
        _isReorderMode = false;
        _isSavingOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("سىرالما ساقلاندى"),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خاتالىق يۈز بەردى"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _reorderList.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _reorderList.removeAt(oldIndex);
          _reorderList.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final student = _reorderList[index];
        return Card(
          key: ValueKey(student['id']),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'سۆرۈۋاتقان ئورۇن: ${index + 1}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.drag_handle, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("چىقىش"),
        content: const Text("چىقىشنى خالامسىز؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("بىكار قىلىش"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Oturumu temizle
              await SessionService.clearSession();

              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("چىقىش", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_isReorderMode
            ? "رەت تەرتىپىنى تەھرىرلەش"
            : "ئوقۇغۇچىلار تىزىملىكى"),
        automaticallyImplyLeading: false,
        actions: _isReorderMode
            ? [
                if (_isSavingOrder)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    tooltip: "ساقلا",
                    onPressed: _saveReorder,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: "بىكار قىلىش",
                    onPressed: () => setState(() => _isReorderMode = false),
                  ),
                ],
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.fact_check),
                  tooltip: "يوقلىما جەدۋىلى",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrackingFormPage()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: "دەرس ئەھۋالى",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceReportPage()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: "يېڭى ئوقۇغۇچى قوشۇش",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddStudentPage()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: "چىقىش",
                  onPressed: _logout,
                ),
              ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            child: StreamBuilder<QuerySnapshot>(
                stream: _dbService.getStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("خاتالىق يۈز بەردى!"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text("تېخى ئوقۇغۇچى قوشۇلمىدى."),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddStudentPage()));
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("بىرىنچى ئوقۇغۇچىنى قوشۇش"),
                          ),
                        ],
                      ),
                    );
                  }

                  final allDocs = snapshot.data!.docs;

                  final activeStudents = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['on_leave'] != true;
                  }).toList();

                  final onLeaveStudents = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['on_leave'] == true;
                  }).toList();

                  // sort_order'a gore sirala
                  activeStudents.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aOrder = aData['sort_order'] as int?;
                    final bOrder = bData['sort_order'] as int?;
                    if (aOrder != null && bOrder != null)
                      return aOrder.compareTo(bOrder);
                    if (aOrder != null) return -1;
                    if (bOrder != null) return 1;
                    return 0;
                  });

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.teal.shade50,
                        child: Text("جەمئىي ${activeStudents.length} ئوقۇغۇچى",
                            style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w500)),
                      ),
                      // İzinli öğrenci banner'ı
                      if (onLeaveStudents.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showOnLeaveStudents = !_showOnLeaveStudents;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            color: Colors.amber.shade50,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.beach_access,
                                  size: 18,
                                  color: Colors.amber.shade800,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "رۇخسەتتىكى ئوقۇغۇچىلار: ${onLeaveStudents.length}",
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _showOnLeaveStudents
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.amber.shade800,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // İzinli öğrenci listesi (açılır/kapanır)
                      if (_showOnLeaveStudents && onLeaveStudents.isNotEmpty)
                        Container(
                          color: Colors.amber.shade50,
                          child: Column(
                            children: onLeaveStudents.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildOnLeaveStudentCard(data, doc.id);
                            }).toList(),
                          ),
                        ),
                      Expanded(
                        child: _isReorderMode
                            ? _buildReorderList()
                            : ListView.builder(
                                padding: const EdgeInsets.all(10),
                                itemCount: activeStudents.length,
                                itemBuilder: (context, index) {
                                  var data = activeStudents[index].data()
                                      as Map<String, dynamic>;
                                  return _buildStudentCard(
                                      data, activeStudents[index].id);
                                },
                              ),
                      ),
                      if (!_isReorderMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.grey.shade200,
                          child: OutlinedButton.icon(
                            onPressed: () => _enterReorderMode(activeStudents),
                            icon: const Icon(Icons.drag_handle, size: 18),
                            label: const Text("رەت تەرتىپىنى تەھرىرلەش"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
        },
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, String docId) {
    String name = student['name'] ?? 'ئىسىمسىز';

    // Bugünün tarihini al
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastAttendedDate = student['last_attended_date'] as String?;

    // Sadece bugün için ders girilmişse "ئۆتكۈزدى" göster
    // Eğer son kayıt bugüne ait değilse, herkes "ئۆتكۈزمىدى" olarak görünür
    bool attended = false;
    if (lastAttendedDate == today) {
      attended = student['last_attended'] ?? false;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Expanded(
                child:
                    Text(student['last_lesson'] ?? "تېخى دەرس كىرگۈزۈلمىدى")),
            if (student['last_is_takrar'] == true)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "تەكرار",
                  style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),

          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: attended
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: attended ? Colors.green : Colors.red),
          ),
          child: Text(
            attended ? "ئۆتكۈزدى" : "ئۆتكۈزمىدى",
            style: TextStyle(
                color: attended ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        onTap: () => _showStudentOptionsDialog(context, student, docId),
      ),
    );
  }

  Widget _buildOnLeaveStudentCard(Map<String, dynamic> student, String docId) {
    String name = student['name'] ?? 'ئىسىمسىز';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      color: Colors.amber.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade200,
          child: const Icon(Icons.beach_access, color: Colors.amber, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "رۇخسەتتە",
          style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            try {
              await _dbService.setStudentLeaveStatus(docId, false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name رۇخسەتتىن قايتتى"),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("خاتالىق يۈز بەردى"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.replay, size: 16),
          label: const Text("قايتۇرۇش", style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }

  // ==================== ÖĞRENCİ SEÇENEKLERİ DİALOGU ====================
  void _showStudentOptionsDialog(
      BuildContext context, Map<String, dynamic> student, String docId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Öğrenci adı
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  student['name'] ?? 'ئوقۇغۇچى',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),

              // Ders girişi
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.teal),
                title: const Text("دەرس كىرگۈزۈش"),
                subtitle: const Text("يېڭى دەرس خاتىرىسى قوشۇش"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEntryDialog(context, student, docId);
                },
              ),

              // Ders geçmişi
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("دەرس تارىخى"),
                subtitle: const Text("بارلىق دەرس خاتىرىلىرى"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStudentHistoryDialog(context, student, docId);
                },
              ),

              // Öğrenci düzenleme
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text("ئوقۇغۇچى تەھرىرلەش"),
                subtitle: const Text("ئىسىم، كود، جۈز ئۆزگەرتىش"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditStudentDialog(context, student, docId);
                },
              ),

              // İzne çıkar
              ListTile(
                leading: Icon(
                  student['on_leave'] == true
                      ? Icons.replay
                      : Icons.beach_access,
                  color: Colors.amber.shade700,
                ),
                title: Text(
                  student['on_leave'] == true
                      ? "رۇخسەتتىن قايتۇرۇش"
                      : "رۇخسەتكە چىقىرىش",
                ),
                subtitle: Text(
                  student['on_leave'] == true
                      ? "ئوقۇغۇچىنى تىزىملىككە قايتۇرۇش"
                      : "ۋاقىتلىق تىزىملىكتىن يوشۇرۇش",
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final newStatus = !(student['on_leave'] == true);
                  try {
                    await _dbService.setStudentLeaveStatus(docId, newStatus);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? "${student['name']} رۇخسەتكە چىقتى"
                              : "${student['name']} رۇخسەتتىن قايتتى",
                        ),
                        backgroundColor:
                            newStatus ? Colors.amber : Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("خاتالىق يۈز بەردى"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

              // Öğrenci silme
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("ئوقۇغۇچى ئۆچۈرۈش"),
                subtitle: const Text("بارلىق مەلۇماتلارنى ئۆچۈرىدۇ"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteStudentDialog(context, student, docId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DERS GİRİŞİ DİALOGU ====================
  void _showEntryDialog(
      BuildContext context, Map<String, dynamic> student, String docId) {
    final homeworkController = TextEditingController();
    // Miktar seçimi için değişkenler (TextController yerine)
    int selectedPageAmount = 0;
    int selectedJuzAmount = 0;
    int selectedLineAmount = 0;

    bool attended = true;
    bool isTakrar = false;
    bool isSaving = false;
    DateTime selectedDate = DateTime.now();

    SurahInfo? startSurah;
    int? startAyah;
    SurahInfo? endSurah;
    int? endAyah;

    final List<String> reasonOptions = [
      'ئۆتكۈزمىدى',
      'كەلمىدى',
      'رۇخسەت',
      'كىسەل'
    ];
    String selectedReason = 'ئۆتكۈزمىدى';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Klavye açıkken dialog yukarı kayması için MediaQuery kullan
            return AlertDialog(
              scrollable: true,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(student['name'] ?? 'ئوقۇغۇچى'),
                  // Tarih seçici
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('tr'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarih gösterimi
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "${_uyghurDays[selectedDate.weekday - 1]} كۈنى ئۈچۈن كىرگۈزۈلىدۇ",
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ders durumu
                  const Text("دەرس ئەھۋالى:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _statusButton(
                          selected: attended,
                          icon: Icons.check_circle,
                          label: "ئۆتكۈزدى",
                          color: Colors.green,
                          onTap: () => setState(() => attended = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusButton(
                          selected: !attended,
                          icon: Icons.cancel,
                          label: "ئۆتكۈزمىدى",
                          color: Colors.red,
                          onTap: () => setState(() => attended = false),
                        ),
                      ),
                    ],
                  ),
                  if (!attended)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: reasonOptions.map((reason) {
                          final isSelected = selectedReason == reason;
                          return ChoiceChip(
                            label: Text(reason),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => selectedReason = reason);
                            },
                            selectedColor: Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.red.shade900
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ),

                  if (attended) ...[
                    const SizedBox(height: 16),

                    // Başlangıç
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("باشلىنىشى:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              if (startSurah != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text("${startSurah!.startJuz}-پارە",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _surahSelector(
                                  label:
                                      startSurah?.nameArabic ?? "سۈرە تاللاڭ",
                                  onTap: () async {
                                    final result =
                                        await _showSurahPicker(context);
                                    if (result != null) {
                                      setState(() {
                                        startSurah = result;
                                        startAyah = null;
                                        endSurah = result;
                                        endAyah = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ayahSelector(
                                  label: startAyah?.toString() ?? "ئايەت",
                                  enabled: startSurah != null,
                                  onTap: () async {
                                    if (startSurah == null) return;
                                    final result = await _showAyahPicker(
                                        context, startSurah!.ayahCount);
                                    if (result != null) {
                                      setState(() => startAyah = result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bitiş
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ئاياغلىشىشى:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _surahSelector(
                                  label: endSurah?.nameArabic ?? "سۈرە تاللاڭ",
                                  onTap: () async {
                                    final result =
                                        await _showSurahPicker(context);
                                    if (result != null) {
                                      setState(() {
                                        endSurah = result;
                                        endAyah = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ayahSelector(
                                  label: endAyah?.toString() ?? "ئايەت",
                                  enabled: endSurah != null,
                                  onTap: () async {
                                    if (endSurah == null) return;
                                    final result = await _showAyahPicker(
                                        context, endSurah!.ayahCount);
                                    if (result != null) {
                                      setState(() => endAyah = result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Takrar toggle
                  CheckboxListTile(
                    title: const Text("تەكرار",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: isTakrar,
                    onChanged: (val) => setState(() => isTakrar = val ?? false),
                    activeColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Sayfa / Cüz / Satır sayısı
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("دەرس مىقدارى:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              // Sayfa Seçimi
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("بەت",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedPageAmount,
                                      items: List.generate(21, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Center(
                                                    child: Text(e.toString())),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                              () => selectedPageAmount = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Cüz Seçimi
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("پارە",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedJuzAmount,
                                      items: List.generate(31, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Center(
                                                    child: Text(e.toString())),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                              () => selectedJuzAmount = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Satır Seçimi
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("قۇر",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedLineAmount,
                                      items: List.generate(16, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Center(
                                                    child: Text(e.toString())),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                              () => selectedLineAmount = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isTakrar)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "تەكرار دەرس",
                          style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),


                  const SizedBox(height: 16),
                  // تاپشۇرۇق كىرگۈزۈش - كونوپكا تاختىسىدىن يوقىرى كۆرۈنىدۇ
                  InkWell(
                    onTap: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) {
                          final textController = TextEditingController(
                              text: homeworkController.text);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(ctx).viewInsets.bottom,
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "تاپشۇرۇق كىرگۈزۈش",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: textController,
                                    autofocus: true,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: "ئۆيگە تاپشۇرۇق...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Colors.teal, width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(
                                          ctx, textController.text),
                                      child: const Text("جەزملەش",
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      if (result != null) {
                        setState(() {
                          homeworkController.text = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              homeworkController.text.isEmpty
                                  ? "تاپشۇرۇق كىرگۈزۈش ئۈچۈن بېسىڭ..."
                                  : homeworkController.text,
                              style: TextStyle(
                                color: homeworkController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("بىكار قىلىش"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          try {
                            String lessonText = "";

                            List<String> parts = [];

                            // Quran part
                            if (attended &&
                                startSurah != null &&
                                startAyah != null) {
                              String quranPart =
                                  "${startSurah!.nameArabic} $startAyah-ئايەتتىن";
                              if (endSurah != null && endAyah != null) {
                                quranPart +=
                                    " ${endSurah!.nameArabic} $endAyah-ئايەتكىچە";
                              }
                              parts.add(quranPart);
                            }

                            // Page/Juz/Line part (Değişkenlerden al)
                            int pCount = selectedPageAmount;
                            int jCount = selectedJuzAmount;
                            int lCount = selectedLineAmount;

                            if (pCount > 0) parts.add("$pCount بەت");
                            if (jCount > 0) parts.add("$jCount پارە");
                            if (lCount > 0) parts.add("$lCount قۇر");

                            if (parts.isNotEmpty) {
                              lessonText = parts.join("، ");
                            }

                            if (!attended) {
                              lessonText = selectedReason;
                            }

                            await _dbService.addDailyLog(
                              docId,
                              attended,
                              lessonText,
                              homeworkController.text.trim(),
                              customDate: selectedDate,
                              pageCount: selectedPageAmount,
                              juzCount: selectedJuzAmount,
                              lineCount: selectedLineAmount,
                              isTakrar: isTakrar,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!context.mounted) return;

                            // Başarı mesajı ve kaydedilen bilgi
                            _showSaveSuccessDialog(
                                context, attended, lessonText, selectedDate,
                                pageCount: selectedPageAmount,
                                juzCount: selectedJuzAmount,
                                lineCount: selectedLineAmount);
                          } catch (e) {
                            setState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("خاتالىق: $e"),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("ساقلاش"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== KAYIT BAŞARI DİALOGU ====================
  void _showSaveSuccessDialog(
      BuildContext context, bool attended, String lesson, DateTime date,
      {int pageCount = 0, int juzCount = 0, int lineCount = 0}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          attended ? Icons.check_circle : Icons.cancel,
          color: attended ? Colors.green : Colors.red,
          size: 48,
        ),
        title: const Text("ساقلاندى!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("چېسلا:", DateFormat('yyyy-MM-dd').format(date)),
            _infoRow("كۈن:", _uyghurDays[date.weekday - 1]),
            _infoRow(
                "ئەھۋال:",
                attended
                    ? "ئۆتكۈزدى"
                    : (lesson.isNotEmpty ? lesson : "ئۆتكۈزمىدى")),
            if (attended && lesson.isNotEmpty) _infoRow("دەرس:", lesson),
            if (pageCount > 0 || juzCount > 0 || lineCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (pageCount > 0) _miniInfo("بەت", pageCount.toString()),
                      if (juzCount > 0) _miniInfo("پارە", juzCount.toString()),
                      if (lineCount > 0) _miniInfo("قۇر", lineCount.toString()),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("تامام"),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ==================== ÖĞRENCİ GEÇMİŞİ DİALOGU ====================
  void _showStudentHistoryDialog(
      BuildContext context, Map<String, dynamic> student, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.blue),
            const SizedBox(width: 8),
            Text("${student['name']} - تارىخ"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getStudentLogs(docId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("تېخى دەرس خاتىرىسى يوق."));
              }

              var logs = snapshot.data!.docs.toList();
              logs.sort((a, b) {
                var aData = a.data() as Map<String, dynamic>;
                var bData = b.data() as Map<String, dynamic>;
                Timestamp? aTime = aData['date'] as Timestamp?;
                Timestamp? bTime = bData['date'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  var log = logs[index].data() as Map<String, dynamic>;
                  String logId = logs[index].id;
                  return _buildLogItem(context, log, logId, docId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("تاقاش"),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, Map<String, dynamic> log,
      String logId, String studentId) {
    Timestamp? timestamp = log['date'] as Timestamp?;
    String dateStr = log['date_string'] ?? "";
    String dayStr = "";

    if (timestamp != null) {
      DateTime date = timestamp.toDate();
      dateStr = DateFormat('yyyy-MM-dd').format(date);
      dayStr = _uyghurDays[date.weekday - 1];
    }

    bool attended = log['attended'] ?? false;
    String lesson = log['lesson'] ?? "";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          attended ? Icons.check_circle : Icons.cancel,
          color: attended ? Colors.green : Colors.red,
        ),
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Text("$dateStr ($dayStr)"),
        ),
        subtitle: Text(lesson.isNotEmpty ? lesson : "دەرس كىرگۈزۈلمىدى"),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditLogDialog(context, log, logId);
            } else if (value == 'delete') {
              _showDeleteLogDialog(context, logId);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("تەھرىرلەش")),
            const PopupMenuItem(value: 'delete', child: Text("ئۆچۈرۈش")),
          ],
        ),
      ),
    );
  }

  // ==================== DERS DÜZENLEME DİALOGU ====================
  void _showEditLogDialog(
      BuildContext context, Map<String, dynamic> log, String logId) {
    final homeworkController =
        TextEditingController(text: log['homework'] ?? "");

    bool attended = log['attended'] ?? false;
    bool isTakrar = log['is_takrar'] ?? false;
    bool isSaving = false;

    Timestamp? timestamp = log['date'] as Timestamp?;
    DateTime selectedDate = timestamp?.toDate() ?? DateTime.now();

    int selectedPageAmount = log['page_count'] ?? 0;
    int selectedJuzAmount = log['juz_count'] ?? 0;
    int selectedLineAmount = log['line_count'] ?? 0;

    SurahInfo? startSurah;
    int? startAyah;
    SurahInfo? endSurah;
    int? endAyah;

    String lessonText = log['lesson'] ?? '';
    if (attended && lessonText.isNotEmpty) {
      if (lessonText.contains('ئايەتتىن')) {
        String startPart = lessonText.split('ئايەتتىن')[0].trim();
        final startMatch = RegExp(r'(.+?)\s+(\d+)-?$').firstMatch(startPart);
        if (startMatch != null) {
          String surahName = startMatch.group(1)!.trim();
          int ayah = int.tryParse(startMatch.group(2)!) ?? 0;
          try {
            startSurah =
                QuranData.surahs.firstWhere((s) => s.nameArabic == surahName);
            startAyah = ayah;
          } catch (_) {}
        }
        if (lessonText.contains('ئايەتكىچە')) {
          String afterStart = lessonText.split('ئايەتتىن')[1].trim();
          String endPart = afterStart.split('ئايەتكىچە')[0].trim();
          final endMatch = RegExp(r'(.+?)\s+(\d+)-?$').firstMatch(endPart);
          if (endMatch != null) {
            String surahName = endMatch.group(1)!.trim();
            int ayah = int.tryParse(endMatch.group(2)!) ?? 0;
            try {
              endSurah =
                  QuranData.surahs.firstWhere((s) => s.nameArabic == surahName);
              endAyah = ayah;
            } catch (_) {}
          }
        }
      }
    }

    final List<String> reasonOptions = [
      'ئۆتكۈزمىدى',
      'كەلمىدى',
      'رۇخسەت',
      'كىسەل'
    ];
    String selectedReason =
        reasonOptions.contains(lessonText) ? lessonText : 'ئۆتكۈزمىدى';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              scrollable: true,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("دەرس تەھرىرلەش"),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('tr'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "${_uyghurDays[selectedDate.weekday - 1]} كۈنى ئۈچۈن تەھرىرلىنىدۇ",
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("دەرس ئەھۋالى:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _statusButton(
                          selected: attended,
                          icon: Icons.check_circle,
                          label: "ئۆتكۈزدى",
                          color: Colors.green,
                          onTap: () => setState(() => attended = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusButton(
                          selected: !attended,
                          icon: Icons.cancel,
                          label: "ئۆتكۈزمىدى",
                          color: Colors.red,
                          onTap: () => setState(() => attended = false),
                        ),
                      ),
                    ],
                  ),
                  if (!attended)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: reasonOptions.map((reason) {
                          final isSelected = selectedReason == reason;
                          return ChoiceChip(
                            label: Text(reason),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => selectedReason = reason);
                            },
                            selectedColor: Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.red.shade900
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ),
                  if (attended) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("باشلىنىشى:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              if (startSurah != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text("${startSurah!.startJuz}-پارە",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _surahSelector(
                                  label:
                                      startSurah?.nameArabic ?? "سۈرە تاللاڭ",
                                  onTap: () async {
                                    final result =
                                        await _showSurahPicker(context);
                                    if (result != null) {
                                      setState(() {
                                        startSurah = result;
                                        startAyah = null;
                                        endSurah = result;
                                        endAyah = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ayahSelector(
                                  label: startAyah?.toString() ?? "ئايەت",
                                  enabled: startSurah != null,
                                  onTap: () async {
                                    if (startSurah == null) return;
                                    final result = await _showAyahPicker(
                                        context, startSurah!.ayahCount);
                                    if (result != null) {
                                      setState(() => startAyah = result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ئاياغلىشىشى:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _surahSelector(
                                  label: endSurah?.nameArabic ?? "سۈرە تاللاڭ",
                                  onTap: () async {
                                    final result =
                                        await _showSurahPicker(context);
                                    if (result != null) {
                                      setState(() {
                                        endSurah = result;
                                        endAyah = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ayahSelector(
                                  label: endAyah?.toString() ?? "ئايەت",
                                  enabled: endSurah != null,
                                  onTap: () async {
                                    if (endSurah == null) return;
                                    final result = await _showAyahPicker(
                                        context, endSurah!.ayahCount);
                                    if (result != null) {
                                      setState(() => endAyah = result);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  CheckboxListTile(
                    title: const Text("تەكرار",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: isTakrar,
                    onChanged: (val) => setState(() => isTakrar = val ?? false),
                    activeColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("دەرس مىقدارى:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("بەت",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedPageAmount,
                                      items: List.generate(21, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Center(
                                                  child: Text(e.toString()))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(
                                              () => selectedPageAmount = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("پارە",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedJuzAmount,
                                      items: List.generate(31, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Center(
                                                  child: Text(e.toString()))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(
                                              () => selectedJuzAmount = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("قۇر",
                                        style: TextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedLineAmount,
                                      items: List.generate(16, (index) => index)
                                          .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Center(
                                                  child: Text(e.toString()))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(
                                              () => selectedLineAmount = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isTakrar)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("تەكرار دەرس",
                            style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            textAlign: TextAlign.center),
                      ),
                    ),

                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) {
                          final textController = TextEditingController(
                              text: homeworkController.text);
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("تاپشۇرۇق كىرگۈزۈش",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () => Navigator.pop(ctx)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: textController,
                                    autofocus: true,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: "ئۆيگە تاپشۇرۇق...",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Colors.teal, width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(
                                          ctx, textController.text),
                                      child: const Text("جەزملەش",
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      if (result != null) {
                        setState(() {
                          homeworkController.text = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              homeworkController.text.isEmpty
                                  ? "تاپشۇرۇق كىرگۈزۈش ئۈچۈن بېسىڭ..."
                                  : homeworkController.text,
                              style: TextStyle(
                                  color: homeworkController.text.isEmpty
                                      ? Colors.grey
                                      : Colors.black),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("بىكار قىلىش"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          try {
                            String editLessonText = "";
                            List<String> parts = [];
                            if (attended &&
                                startSurah != null &&
                                startAyah != null) {
                              String quranPart =
                                  "${startSurah!.nameArabic} $startAyah-ئايەتتىن";
                              if (endSurah != null && endAyah != null) {
                                quranPart +=
                                    " ${endSurah!.nameArabic} $endAyah-ئايەتكىچە";
                              }
                              parts.add(quranPart);
                            }
                            int pCount = selectedPageAmount;
                            int jCount = selectedJuzAmount;
                            int lCount = selectedLineAmount;
                            if (pCount > 0) parts.add("$pCount بەت");
                            if (jCount > 0) parts.add("$jCount پارە");
                            if (lCount > 0) parts.add("$lCount قۇر");
                            if (parts.isNotEmpty)
                              editLessonText = parts.join("، ");
                            if (!attended) editLessonText = selectedReason;

                            await _dbService.updateDailyLog(
                              logId,
                              attended: attended,
                              lesson: editLessonText,
                              homework: homeworkController.text.trim(),
                              customDate: selectedDate,
                              isTakrar: isTakrar,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("ساقلاندى!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("ساقلاش"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== DERS SİLME DİALOGU ====================
  void _showDeleteLogDialog(BuildContext context, String logId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("دەرس ئۆچۈرۈش"),
        content: const Text(
            "بۇ دەرس خاتىرىسىنى ئۆچۈرۈشنى خالامسىز؟\nبۇ مەشغۇلاتنى قايتۇرغىلى بولمايدۇ!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("بىكار قىلىش"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _dbService.deleteDailyLog(logId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("ئۆچۈرۈلدى!"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("خاتالىق: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("ئۆچۈرۈش", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== ÖĞRENCİ DÜZENLEME DİALOGU ====================
  void _showEditStudentDialog(
      BuildContext context, Map<String, dynamic> student, String docId) {
    final nameController = TextEditingController(text: student['name'] ?? "");
    final codeController =
        TextEditingController(text: student['parent_code'] ?? "");
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("ئوقۇغۇچى تەھرىرلەش"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "ئوقۇغۇچى ئىسمى",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: "ۋەلى كودى",
                          prefixIcon: Icon(Icons.key),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("بىكار قىلىش"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              codeController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ئىسىم ۋە كودنى تولدۇرۇڭ!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setState(() => isSaving = true);
                          try {
                            await _dbService.updateStudent(
                              docId,
                              name: nameController.text.trim(),
                              parentCode: codeController.text.trim(),
                            );
                            if (dialogContext.mounted)
                              Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("ساقلاندى!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("خاتالىق: $e"),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("ساقلاش"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== ÖĞRENCİ SİLME DİALOGU ====================
  void _showDeleteStudentDialog(
      BuildContext context, Map<String, dynamic> student, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text("ئوقۇغۇچى ئۆچۈرۈش"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("«${student['name']}» نى ئۆچۈرۈشنى خالامسىز؟"),
            const SizedBox(height: 8),
            const Text(
              "بارلىق دەرس خاتىرىلىرى بىللە ئۆچۈرۈلىدۇ!\nبۇ مەشغۇلاتنى قايتۇرغىلى بولمايدۇ!",
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("بىكار قىلىش"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _dbService.deleteStudent(docId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("ئۆچۈرۈلدى!"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("خاتالىق: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("ئۆچۈرۈش", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== YARDIMCI WİDGETLAR ====================
  Widget _statusButton({
    required bool selected,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : Colors.grey, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? color : Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _surahSelector({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _ayahSelector(
      {required String label,
      required bool enabled,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: enabled ? Colors.grey.shade400 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(color: enabled ? Colors.black : Colors.grey)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Future<SurahInfo?> _showSurahPicker(BuildContext context) async {
    return showModalBottomSheet<SurahInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            // ئىزدەش نەتىجىسى
            final filteredSurahs = searchQuery.isEmpty
                ? QuranData.surahs
                : QuranData.surahs.where((surah) {
                    return surah.nameArabic.contains(searchQuery) ||
                        surah.nameUyghur.contains(searchQuery) ||
                        surah.number.toString() == searchQuery;
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        // Sürükleme göstergesi
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(128),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("سۈرە تاللاڭ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ئىزدەش رامكىسى
                        TextField(
                          onChanged: (value) {
                            setModalState(() {
                              searchQuery = value;
                            });
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "سۈرە ئىزدەش...",
                            hintStyle:
                                TextStyle(color: Colors.white.withAlpha(179)),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withAlpha(51),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredSurahs.isEmpty
                        ? const Center(
                            child: Text(
                              "ھېچقانداق نەتىجە تېپىلمىدى",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredSurahs.length,
                            itemBuilder: (_, index) {
                              final surah = filteredSurahs[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: Text("${surah.number}",
                                      style:
                                          const TextStyle(color: Colors.teal)),
                                ),
                                title: Text(surah.nameArabic,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    "${surah.ayahCount} ئايەت • ${surah.startJuz}-پارە"),
                                onTap: () => Navigator.pop(ctx, surah),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showAyahPicker(BuildContext context, int maxAyah) async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("ئايەت تاللاڭ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: maxAyah,
                  itemBuilder: (_, index) {
                    final ayah = index + 1;
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, ayah),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        alignment: Alignment.center,
                        child: Text("$ayah",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
