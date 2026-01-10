import 'package:flutter/material.dart';
import 'package:flutter_paygateglobal/flutter_paygateglobal.dart';
import 'package:togoschool/config/paygate_config.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/student_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/auth/login_page.dart';
import 'package:togoschool/service/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int? roleId;
  const MyApp({super.key, this.isLoggedIn = false, this.roleId});

  @override
  Widget build(BuildContext context) {
    Widget homePage;

    if (!isLoggedIn) {
      homePage = const LoginPage();
    } else {
      switch (roleId) {
        case 1:
          homePage = const AdminDashboardPage();
          break;
        case 2:
          homePage = const TeacherDashboardPage();
          break;
        case 3:
          homePage = const StudentDashboardPage();
          break;
        default:
          homePage = const LoginPage();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: homePage,
    );
  }
}
