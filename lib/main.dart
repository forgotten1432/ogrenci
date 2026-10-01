import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/session_service.dart';
import 'screens/login_page.dart';
import 'screens/teacher_dashboard.dart';

void main() async {
  await _initApp();
}

Future<void> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase kaldırıldı, yerel veritabanı kullanılacak.

  // Ekran yönleri - sadece native mobil için (Web'de atla - iOS Safari crash)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مىئراج دەرس ئەھۋالى',
      debugShowCheckedModeBanner: false,
      // Localization ayarları - DatePicker için gerekli
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'), // Türkçe (DatePicker için)
        Locale('en'), // İngilizce (fallback)
      ],
      locale: const Locale('tr'), // Türkçe kullan
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SessionChecker(),
    );
  }
}

/// Uygulama açılışında oturum kontrolü yapar.
/// Daha önce giriş yapılmışsa doğrudan ilgili ekrana yönlendirir.
class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // 5 saniye timeout ekle - takılma olmasın
      await _doCheckSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Oturum kontrolü zaman aşımına uğradı');
        },
      );
    } catch (e) {
      debugPrint('Oturum kontrolü hatası: $e');
    }

    // Oturum yoksa veya hata varsa → LoginPage'e git
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _doCheckSession() async {
    final sessionData = await SessionService.getSession();
    final isLoggedIn = sessionData['is_logged_in'] as bool;
    final userType = sessionData['user_type'] as String?;

    if (!mounted) return;

    if (isLoggedIn && userType != null) {
      if (userType == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text(
                "يۈكلىنىۋاتىدۇ...",
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
            ],
          ),
        ),
      );
    }

    return const LoginPage();
  }
}
