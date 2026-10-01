import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    String code = _codeController.text.trim();

    try {
      // Sadece admin girişi
      if (code == "admin") {
        // Önce navigasyon yap, oturumu arka planda kaydet
        SessionService.saveSession(userType: 'teacher');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "كود خاتا! قايتا سىناڭ."; // Kod hatalı
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "تور ئۇلىنىشىدا خاتالىق! تورنى تەكشۈرۈڭ."; // Ağ hatası
      });
      debugPrint("Login hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              size: 60, color: Colors.teal),
                        ),
                        const SizedBox(height: 20),

                        // Başlık
                        const Text(
                          "مىئ‍راج",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "قارىلىق 3-سىنىپ ئوقۇغۇچىلىرى",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "دەرس ئەھۋالى",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Hata mesajı
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

                        // Kod girişi - LTR
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _codeController,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: "كىرىش كودى",
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              hintText: "كودنى كىرگۈزۈڭ",
                              alignLabelWithHint: true,
                              floatingLabelStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'كود كىرگۈزۈڭ';
                              }
                              if (value.trim().length < 3) {
                                return 'كود كەم دېگەندە 3 ھەرپ بولسۇن';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Giriş butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _login,
                                  child: const Text("كىرىش",
                                      style: TextStyle(fontSize: 18)),
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
