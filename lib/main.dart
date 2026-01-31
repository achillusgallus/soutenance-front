import 'package:flutter/material.dart';
import 'package:flutter_paygateglobal/flutter_paygateglobal.dart';
import 'package:togoschool/config/paygate_config.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/pages/tableau_de_bord/admin_dashboard_page.dart';
import 'package:togoschool/pages/tableau_de_bord/student_dashboard_page.dart';
import 'package:togoschool/pages/tableau_de_bord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/auth/page_connexion.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/services/service_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive pour le cache hors-ligne
  await Hive.initFlutter();
  await Hive.openBox('pdf_cache');

  // Bloquer les captures d'écran sur Mobile (Android/iOS)
  if (!kIsWeb) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  // Initialiser PayGate avec la clé API
  Paygate.init(
    apiKey: PaygateConfig.apiKey,
    apiKeyDebug: PaygateConfig.apiKeyDebug,
    apiVersion: PaygateVersion.v2,
    identifierLength: PaygateConfig.identifierLength,
  );

  final token = await TokenStorage.getToken();
  final roleId = await TokenStorage.getRole();

  runApp(MyApp(isLoggedIn: token != null, roleId: roleId));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final int? roleId;
  const MyApp({super.key, this.isLoggedIn = false, this.roleId});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _themeService.getTheme();
    setState(() => _isDarkMode = isDark);
  }

  void _toggleTheme() async {
    final newTheme = await _themeService.toggleTheme();
    setState(() => _isDarkMode = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    Widget homePage;

    if (!widget.isLoggedIn) {
      homePage = const LoginPage();
    } else {
      switch (widget.roleId) {
        case 1:
          homePage = const AdminDashboardPage();
          break;
        case 2:
          homePage = const TeacherDashboardPage();
          break;
        case 3:
          homePage = StudentDashboardPage(toggleTheme: _toggleTheme);
          break;
        default:
          homePage = const LoginPage();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.modernTheme,
      darkTheme: AppTheme.modernTheme.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: homePage,
    );
  }
}
