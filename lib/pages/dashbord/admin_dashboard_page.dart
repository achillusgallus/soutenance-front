import 'package:flutter/material.dart';
import 'package:togoschool/components/navbar.dart';
import 'package:togoschool/pages/admin/admin_acceuil.dart';
import 'package:togoschool/pages/admin/admin_finance.dart';
import 'package:togoschool/pages/admin/admin_professeur.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {

   int _currentIndex = 0;

   final List<Widget> _pages = [
    const AdminAcceuil(),
    const AdminProfesseur(),
    const AdminFinance(),
   ];

    final List<NavigationBarItem> _navItems = [
    NavigationBarItem(icon: Icons.home, label: "Accueil"),
    NavigationBarItem(icon: Icons.person_add, label: "professeurs"),
    NavigationBarItem(icon: Icons.money, label: "finance"),
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