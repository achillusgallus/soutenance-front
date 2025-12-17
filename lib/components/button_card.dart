import 'package:flutter/material.dart';

class ButtonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const ButtonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });

@override
Widget build(BuildContext context) {
  return Container(
  width: 80, // largeur réduite
  padding: EdgeInsets.all(6),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(10),
  ),
  child: InkWell(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 30, color: Colors.white,),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
      ],
    ),
  ),
);
}
}