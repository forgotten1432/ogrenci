import 'package:flutter/material.dart';
import 'models.dart';
import 'db_service.dart';
import 'table_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QuranTable> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tables = await DbService.getTables();
    setState(() {
      _tables = tables;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await DbService.saveTables(_tables);
  }

  void _addNewTable() {
    TextEditingController titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('يېڭى جەدۋەل قوشۇش'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'مەسىلەن: ئىككىنچى گۇرۇپ 2026/8/20'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بىكار قىلىش'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _tables.add(QuranTable(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    records: [],
                  ));
                });
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('قوشۇش'),
          ),
        ],
      ),
    );
  }

  void _deleteTable(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئۆچۈرۈش'),
        content: const Text('بۇ جەدۋەلنى راستىنلا ئۆچۈرەمسىز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ياق'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _tables.removeAt(index);
              });
              _saveData();
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
        title: const Text('قۇرئان ئوقۇش جەدۋىلى'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? const Center(child: Text('ھېچقانداق جەدۋەل يوق. يېڭىدىن قوشۇڭ.'))
              : ListView.builder(
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(table.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${table.records.length} قۇر مەلۇمات بار'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTable(index),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TablePage(
                                quranTable: table,
                                onSave: (updatedTable) {
                                  setState(() {
                                    _tables[index] = updatedTable;
                                  });
                                  _saveData();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTable,
        child: const Icon(Icons.add),
      ),
    );
  }
}
