import 'package:flutter/material.dart';
import 'package:togoschool/components/navbar.dart';
import 'package:togoschool/pages/teacher/teach_cours.dart';
import 'package:togoschool/pages/teacher/teacher_acceuil.dart';
import 'package:togoschool/pages/teacher/teacher_eleves.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {

   int _currentIndex = 0;

   final List<Widget> _pages = [
    const TeacherAcceuil(),
    const TeachCours(),
    const TeacherEleves()
   ];

    final List<NavigationBarItem> _navItems = [
    NavigationBarItem(icon: Icons.home, label: "Accueil"),
    NavigationBarItem(icon: Icons.book, label: "cours"),
    NavigationBarItem(icon: Icons.person_4, label: "élèves"),
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