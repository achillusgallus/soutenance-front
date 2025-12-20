import 'package:flutter/material.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/student_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/student_connexion_page.dart';
import 'package:togoschool/service/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await TokenStorage.getToken();
  final roleId = await TokenStorage.getRole();

  runApp( MyApp(
    isLoggedIn: token != null,
    roleId: roleId,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int? roleId;
  const MyApp({super.key, this.isLoggedIn = false, this.roleId});

  @override
  Widget build(BuildContext context) {

    Widget homePage;

    if (!isLoggedIn) { 
      homePage = const StudentConnexionPage(); 
      } else { 
        switch (roleId) { 
          case 1: homePage = const AdminDashboardPage(); 
          break; 
          case 2: homePage = const TeacherDashboardPage(); 
          break; 
          case 3: homePage = const StudentDashboardPage(); 
          break; 
          default: homePage = const StudentConnexionPage(); 
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
