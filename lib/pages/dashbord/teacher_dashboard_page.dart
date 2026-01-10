import 'package:flutter/material.dart';
import 'package:togoschool/components/navbar.dart';
import 'package:togoschool/pages/teacher/teacher_quiz.dart';
import 'package:togoschool/pages/teacher/teacher_forum.dart';
import 'package:togoschool/pages/teacher/teach_cours.dart';
import 'package:togoschool/pages/teacher/teacher_acceuil.dart';
import 'package:togoschool/pages/teacher/teacher_eleves.dart';

class TeacherDashboardPage extends StatefulWidget {
  final bool isAdminViewing;
  final Map<String, dynamic>? teacherData;

  const TeacherDashboardPage({
    super.key,
    this.isAdminViewing = false,
    this.teacherData,
  });

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _currentIndex = 0;

  final List<NavigationBarItem> _navItems = [
    NavigationBarItem(icon: Icons.home, label: "Accueil"),
    NavigationBarItem(icon: Icons.book, label: "Cours"),
    NavigationBarItem(icon: Icons.quiz, label: "Quiz"),
    NavigationBarItem(icon: Icons.forum, label: "Forum"),
    NavigationBarItem(icon: Icons.person_add, label: "Élèves"),
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
      TeacherAcceuil(teacherData: widget.teacherData),
      const TeachCours(),
      const TeacherQuiz(),
      const TeacherForum(),
      TeacherEleves(onBack: () => _onTabChanged(0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _pages[_currentIndex],
            if (widget.isAdminViewing)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: const Color(0xFF6366F1),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Retour Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}
