import 'package:flutter/material.dart';
import 'models.dart';
import 'session_page.dart';

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
    setState(() {
      _group.students.removeAt(index);
    });
    widget.onSave(_group);
  }

  void _addSession() {
    TextEditingController dateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('يېڭى كۈنلۈك خاتىرە'),
        content: TextField(
          controller: dateController,
          decoration: const InputDecoration(hintText: 'مەسىلەن: 2026/8/20 (پەيشەنبە)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بىكار قىلىش'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dateController.text.trim().isNotEmpty) {
                setState(() {
                  _group.sessions.add(DailySession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    dateString: dateController.text.trim(),
                    records: [], // Records are populated dynamically or saved as entered
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

  void _deleteSession(int index) {
    setState(() {
      _group.sessions.removeAt(index);
    });
    widget.onSave(_group);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_group.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'خاتىرىلەر (كۈنلۈك)'),
              Tab(text: 'ئوقۇغۇچىلار تىزىملىكى'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Sessions Tab
            _group.sessions.isEmpty
                ? const Center(child: Text('خاتىرە يوق. يېڭىدىن قوشۇڭ.'))
                : ListView.builder(
                    itemCount: _group.sessions.length,
                    itemBuilder: (context, index) {
                      final session = _group.sessions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(session.dateString, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('كۈنلۈك ئوقۇش ئەھۋالىنى كۆرۈش/كىرگۈزۈش'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSession(index),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionPage(
                                  group: _group,
                                  session: session,
                                  onSave: (updatedSession) {
                                    setState(() {
                                      _group.sessions[index] = updatedSession;
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
            // Students Tab
            _group.students.isEmpty
                ? const Center(child: Text('بۇ گۇرۇپتا ئوقۇغۇچى يوق. قوشۇڭ.'))
                : ListView.builder(
                    itemCount: _group.students.length,
                    itemBuilder: (context, index) {
                      final student = _group.students[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(student.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStudent(index),
                        ),
                      );
                    },
                  ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                if (DefaultTabController.of(context).index == 0) {
                  _addSession();
                } else {
                  _addStudent();
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
