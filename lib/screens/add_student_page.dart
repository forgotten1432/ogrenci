import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DatabaseService().addStudent(
        _nameController.text.trim(),
        _codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ئوقۇغۇچى مۇۋەپپەقىيەتلىك ساقلاندى!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (e.toString().contains('zaten kullanılıyor')) {
          _errorMessage = "بۇ ۋەلى كودى ئىشلىتىلىۋاتىدۇ!";
        } else {
          _errorMessage = "ساقلاشتا خاتالىق يۈز بەردى. قايتا سىناڭ.";
        }
      });
      debugPrint("Öğrenci ekleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("يېڭى ئوقۇغۇچى قوشۇش")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.person_add,
                            size: 48, color: Colors.teal),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Öğrenci adı
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: "ئوقۇغۇچى ئىسمى",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "ئوقۇغۇچى ئىسمى زۆرۈر";
                            }
                            if (v.trim().length < 2) {
                              return "ئىسىم كەم دېگەندە 2 ھەرپ بولسۇن";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Veli kodu - LTR
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _codeController,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              labelText: "ۋەلى كودى",
                              prefixIcon: Icon(Icons.key),
                              border: OutlineInputBorder(),
                              helperText: "ۋەلى بۇ كود بىلەن كىرىدۇ",
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "ۋەلى كودى زۆرۈر";
                              }
                              if (v.trim().length < 4) {
                                return "كود كەم دېگەندە 4 ھەرپ بولسۇن";
                              }
                              if (v.trim() == "admin123") {
                                return "بۇ كودنى ئىشلەتكىلى بولمايدۇ";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  onPressed: _saveStudent,
                                  icon: const Icon(Icons.save),
                                  label: const Text("ساقلاش",
                                      style: TextStyle(fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
