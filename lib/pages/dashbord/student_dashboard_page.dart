import 'package:flutter/material.dart';
import 'package:togoschool/components/navbar.dart';
import 'package:togoschool/pages/students/student_acceuil.dart';
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/pages/students/student_forum.dart';
import 'package:togoschool/pages/students/student_profil.dart';
import 'package:togoschool/pages/students/student_quiz_page.dart';

class StudentDashboardPage extends StatefulWidget {
  final VoidCallback? toggleTheme;
  const StudentDashboardPage({super.key, this.toggleTheme});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _currentIndex = 0;

  final List<NavigationBarItem> _navItems = [
    NavigationBarItem(icon: Icons.home_outlined, label: "Accueil"),
    NavigationBarItem(icon: Icons.play_lesson_outlined, label: "Cours"),
    NavigationBarItem(icon: Icons.quiz_outlined, label: "Quiz"),
    NavigationBarItem(icon: Icons.forum_outlined, label: "Forum"),
    NavigationBarItem(icon: Icons.person_outline, label: "Profil"),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      StudentAcceuil(toggleTheme: widget.toggleTheme),
      const StudentCours(),
      const StudentQuizPage(),
      const StudentForum(),
      const StudentProfil(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: Navbar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}
