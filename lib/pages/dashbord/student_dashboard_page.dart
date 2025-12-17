import 'package:flutter/material.dart';
import 'package:togoschool/components/navbar.dart';
import 'package:togoschool/pages/students/student_acceuil.dart';
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/pages/students/student_forum.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {

   int _currentIndex = 0;

   final List<Widget> _pages = [
    const StudentAcceuil(),
    const StudentCours(),
    const StudentForum()
   ];

    final List<NavigationBarItem> _navItems = [
    NavigationBarItem(icon: Icons.home, label: "Accueil"),
    NavigationBarItem(icon: Icons.play_lesson, label: "cours"),
    NavigationBarItem(icon: Icons.message, label: "forum"),
  ];

    void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: _pages[_currentIndex],
    ),
    bottomNavigationBar: Navbar(
      items: _navItems,
      onTabChanged: _onTabChanged,
    ),
  );
}
}