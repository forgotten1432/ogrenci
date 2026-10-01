import 'package:flutter/material.dart';
import 'models.dart';
import 'db_service.dart';
import 'group_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groups = await DbService.getGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await DbService.saveGroups(_groups);
  }

  void _addNewGroup() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('يېڭى گۇرۇپ قوشۇش'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'مەسىلەن: 1-گۇرۇپ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بىكار قىلىش'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _groups.add(Group(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    students: [],
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

  void _deleteGroup(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئۆچۈرۈش'),
        content: const Text('بۇ گۇرۇپنى راستىنلا ئۆچۈرەمسىز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ياق'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _groups.removeAt(index);
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
        title: const Text('قۇرئان ئوقۇش گۇرۇپپىلىرى'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('ھېچقانداق گۇرۇپ يوق. يېڭىدىن قوشۇڭ.'))
              : ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${group.students.length} ئوقۇغۇچى بار'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGroup(index),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupPage(
                                group: group,
                                onSave: (updatedGroup) {
                                  setState(() {
                                    _groups[index] = updatedGroup;
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
        onPressed: _addNewGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
}
