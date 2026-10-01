import 'package:flutter/material.dart';
import 'models.dart';
import 'constants.dart';

class SessionPage extends StatefulWidget {
  final Group group;
  final DailySession session;
  final Function(DailySession) onSave;

  const SessionPage({Key? key, required this.group, required this.session, required this.onSave}) : super(key: key);

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late DailySession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  void _showRecordDialog(Student student, ReadingRecord? record) {
    String? startSurah = record?.startSurah.isEmpty == true ? null : record?.startSurah;
    if (startSurah != null && !quranSurahs.contains(startSurah)) startSurah = null;
    
    int? startAyah = record?.startAyah;
    
    String? endSurah = record?.endSurah.isEmpty == true ? null : record?.endSurah;
    if (endSurah != null && !quranSurahs.contains(endSurah)) endSurah = null;
    
    int? endAyah = record?.endAyah;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${student.name} نىڭ ئوقۇشىنى كىرگۈزۈش'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'سۈرە (باشلىنىش)'),
                            value: startSurah,
                            items: quranSurahs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setDialogState(() => startSurah = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'ئايەتتىن'),
                            value: startAyah,
                            items: List.generate(286, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                            onChanged: (v) => setDialogState(() => startAyah = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // End
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'سۈرە (ئاخىرلىشىش)'),
                            value: endSurah,
                            items: quranSurahs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setDialogState(() => endSurah = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'ئايەتكىچە'),
                            value: endAyah,
                            items: List.generate(286, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                            onChanged: (v) => setDialogState(() => endAyah = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('بىكار قىلىش')),
                ElevatedButton(
                  onPressed: () {
                    final newRecord = ReadingRecord(
                      studentId: student.id,
                      startSurah: startSurah ?? '',
                      startAyah: startAyah,
                      endSurah: endSurah ?? '',
                      endAyah: endAyah,
                    );
                    
                    setState(() {
                      final index = _session.records.indexWhere((r) => r.studentId == student.id);
                      if (index != -1) {
                        _session.records[index] = newRecord;
                      } else {
                        _session.records.add(newRecord);
                      }
                    });
                    
                    widget.onSave(_session);
                    Navigator.pop(context);
                  },
                  child: const Text('ساقلاش'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearRecord(String studentId) {
    setState(() {
      _session.records.removeWhere((r) => r.studentId == studentId);
    });
    widget.onSave(_session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} - ${_session.dateString}'),
      ),
      body: widget.group.students.isEmpty
          ? const Center(child: Text('بۇ گۇرۇپتا ئوقۇغۇچى يوق. ئالدى بىلەن ئوقۇغۇچى قوشۇڭ.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ئىسىم فامىلىسى', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('سۈرە', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ئايەتتىن', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('سۈرە', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ئايەتكىچە', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('مەشغۇلات', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: widget.group.students.map((student) {
                    final recordIndex = _session.records.indexWhere((r) => r.studentId == student.id);
                    final record = recordIndex != -1 ? _session.records[recordIndex] : null;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(student.name)),
                        DataCell(Text(record?.startSurah ?? '')),
                        DataCell(Text(record?.startAyah?.toString() ?? '')),
                        DataCell(Text(record?.endSurah ?? '')),
                        DataCell(Text(record?.endAyah?.toString() ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showRecordDialog(student, record),
                            ),
                            if (record != null)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.red),
                                onPressed: () => _clearRecord(student.id),
                              ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
