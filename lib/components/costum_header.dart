import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final TextEditingController searchController;
  final Function(String) onSearch;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.onBack,
    required this.searchController,
    required this.onSearch,
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
              icon: Icon(Icons.arrow_back, color: Colors.black),
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
          const SizedBox(height: 12),
          // Barre de recherche
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: onSearch,
          ),
        ],
      ),
    );
  }
}


