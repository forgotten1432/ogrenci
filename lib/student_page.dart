import 'package:flutter/material.dart';
import 'models.dart';
import 'constants.dart';
import 'package:intl/intl.dart' hide TextDirection;

class StudentPage extends StatefulWidget {
  final Student student;
  final Function(Student) onSave;

  const StudentPage({Key? key, required this.student, required this.onSave}) : super(key: key);

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  late Student _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  void _showRecordDialog({ReadingRecord? record, int? index}) {
    String? startSurah = record?.startSurah.isEmpty == true ? null : record?.startSurah;
    if (startSurah != null && !quranSurahs.contains(startSurah)) startSurah = null;
    
    int? startAyah = record?.startAyah;
    
    String? endSurah = record?.endSurah.isEmpty == true ? null : record?.endSurah;
    if (endSurah != null && !quranSurahs.contains(endSurah)) endSurah = null;
    
    int? endAyah = record?.endAyah;
    
    // Default to today if new record
    final dateController = TextEditingController(text: record?.dateString ?? DateFormat('yyyy/MM/dd').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(record == null ? 'يېڭى ئوقۇش خاتىرىسى' : 'ئۆزگەرتىش'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'چېسلا (كۈن)'),
                    ),
                    const SizedBox(height: 16),
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
                      id: record?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      dateString: dateController.text.trim(),
                      startSurah: startSurah ?? '',
                      startAyah: startAyah,
                      endSurah: endSurah ?? '',
                      endAyah: endAyah,
                    );
                    
                    setState(() {
                      if (index != null) {
                        _student.records[index] = newRecord;
                      } else {
                        _student.records.add(newRecord);
                      }
                    });
                    
                    widget.onSave(_student);
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

  void _deleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئۆچۈرۈش'),
        content: const Text('بۇ خاتىرىنى راستىنلا ئۆچۈرەمسىز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ياق'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _student.records.removeAt(index);
              });
              widget.onSave(_student);
              Navigator.pop(context);
            },
            child: const Text('ھەئە'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_student.name} ئوقۇش خاتىرىسى'),
      ),
      body: _student.records.isEmpty
          ? const Center(child: Text('ئوقۇش خاتىرىسى يوق. يېڭىدىن قوشۇڭ.'))
          : SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('چېسلا', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('سۈرە (باش)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ئايەت', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('سۈرە (ئاخىر)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ئايەت', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('مەشغۇلات', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _student.records.asMap().entries.map((entry) {
                        int index = entry.key;
                        ReadingRecord record = entry.value;
                        
                        return DataRow(
                          cells: [
                            DataCell(Text(record.dateString)),
                            DataCell(Text(record.startSurah)),
                            DataCell(Text(record.startAyah?.toString() ?? '')),
                            DataCell(Text(record.endSurah)),
                            DataCell(Text(record.endAyah?.toString() ?? '')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showRecordDialog(record: record, index: index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRecord(index),
                                ),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordDialog(),
        icon: const Icon(Icons.add),
        label: const Text('يېڭى دەرىس قوشۇش'),
      ),
    );
  }
}
