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
  final int currentIndex;

  const Navbar({
    super.key,
    required this.items,
    required this.onTabChanged,
    this.currentIndex = 0,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: widget.currentIndex,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        widget.onTabChanged(index);
      },
      items: widget.items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
