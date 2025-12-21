import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';

class TeacherEleves extends StatefulWidget {
  const TeacherEleves({super.key});

  @override
  State<TeacherEleves> createState() => _TeacherElevesState();
}

class _TeacherElevesState extends State<TeacherEleves> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          FormHeader(title: "Mes Élèves", onBack: () => Navigator.pop(context)),
          Expanded(child: _buildEmptyState()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun élève trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Les élèves apparaîtront ici une fois inscrits.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
