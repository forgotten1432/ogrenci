import 'package:flutter/material.dart';
import 'models.dart';

class TablePage extends StatefulWidget {
  final QuranTable quranTable;
  final Function(QuranTable) onSave;

  const TablePage({Key? key, required this.quranTable, required this.onSave}) : super(key: key);

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  late QuranTable _table;

  @override
  void initState() {
    super.initState();
    _table = widget.quranTable;
  }

  void _showRecordDialog({QuranRecord? record, int? index}) {
    final nameController = TextEditingController(text: record?.name ?? '');
    final startSurahController = TextEditingController(text: record?.startSurah ?? '');
    final startAyahController = TextEditingController(text: record?.startAyah ?? '');
    final endSurahController = TextEditingController(text: record?.endSurah ?? '');
    final endAyahController = TextEditingController(text: record?.endAyah ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record == null ? 'يېڭى قۇر قوشۇش' : 'ئۆزگەرتىش'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ئىسىم فامىلىسى')),
              Row(
                children: [
                  Expanded(child: TextField(controller: startSurahController, decoration: const InputDecoration(labelText: 'سۈرە (باشلىنىش)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: startAyahController, decoration: const InputDecoration(labelText: 'ئايەتتىن'), keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: endSurahController, decoration: const InputDecoration(labelText: 'سۈرە (ئاخىرلىشىش)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: endAyahController, decoration: const InputDecoration(labelText: 'ئايەتكىچە'), keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('بىكار قىلىش')),
          ElevatedButton(
            onPressed: () {
              final newRecord = QuranRecord(
                id: record?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                startSurah: startSurahController.text.trim(),
                startAyah: startAyahController.text.trim(),
                endSurah: endSurahController.text.trim(),
                endAyah: endAyahController.text.trim(),
              );

              setState(() {
                if (index != null) {
                  _table.records[index] = newRecord;
                } else {
                  _table.records.add(newRecord);
                }
              });
              widget.onSave(_table);
              Navigator.pop(context);
            },
            child: const Text('ساقلاش'),
          ),
        ],
      ),
    );
  }

  void _deleteRecord(int index) {
    setState(() {
      _table.records.removeAt(index);
    });
    widget.onSave(_table);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_table.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRecordDialog(),
          )
        ],
      ),
      body: SingleChildScrollView(
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
            rows: _table.records.asMap().entries.map((entry) {
              int idx = entry.key;
              QuranRecord rec = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(rec.name)),
                  DataCell(Text(rec.startSurah)),
                  DataCell(Text(rec.startAyah)),
                  DataCell(Text(rec.endSurah)),
                  DataCell(Text(rec.endAyah)),
                  DataCell(Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showRecordDialog(record: rec, index: idx)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRecord(idx)),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
