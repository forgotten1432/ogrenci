import 'package:flutter/material.dart';
import 'models.dart';
import 'student_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;
  final Function(Group) onSave;

  const GroupPage({Key? key, required this.group, required this.onSave}) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late Group _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  void _addStudent() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئوقۇغۇچى قوشۇش'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'ئىسىم فامىلىسى'),
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
                  _group.students.add(Student(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    records: [],
                  ));
                });
                widget.onSave(_group);
                Navigator.pop(context);
              }
            },
            child: const Text('قوشۇش'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئۆچۈرۈش'),
        content: const Text('بۇ ئوقۇغۇچىنى راستىنلا ئۆچۈرەمسىز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ياق'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _group.students.removeAt(index);
              });
              widget.onSave(_group);
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
        title: Text('${_group.name} ئوقۇغۇچىلىرى'),
      ),
      body: _group.students.isEmpty
          ? const Center(child: Text('بۇ گۇرۇپتا ئوقۇغۇچى يوق. قوشۇڭ.'))
          : ListView.builder(
              itemCount: _group.students.length,
              itemBuilder: (context, index) {
                final student = _group.students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${student.records.length} قېتىملىق ئوقۇش خاتىرىسى بار'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStudent(index),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentPage(
                            student: student,
                            onSave: (updatedStudent) {
                              setState(() {
                                _group.students[index] = updatedStudent;
                              });
                              widget.onSave(_group);
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
        onPressed: _addStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
