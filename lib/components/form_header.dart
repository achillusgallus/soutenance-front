import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const FormHeader({
    Key? key,
    required this.title,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, CupertinoColors.activeGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [        // Bouton retour
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),

            // Titre dynamique
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }
}
