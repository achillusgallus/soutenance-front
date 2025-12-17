import 'package:flutter/material.dart';

// 1. Définition d'un item de navigation personnalisé
class NavigationBarItem {
  final IconData icon;
  final String label;

  NavigationBarItem({required this.icon, required this.label});
}

// 2. Composant Navbar réutilisable
class Navbar extends StatefulWidget {
  final List<NavigationBarItem> items;
  final Function(int) onTabChanged;

  const Navbar({
    super.key,
    required this.items,
    required this.onTabChanged,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        widget.onTabChanged(index); // Notifier le parent du changement
      },
      items: widget.items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }
}