import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/pages/student_connexion_page.dart';
import 'package:togoschool/pages/teacher_connexion_page.dart';


class RoleToggleStudent extends StatelessWidget {
  const RoleToggleStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
              context, 
               MaterialPageRoute(builder: (context) => TeacherConnexionPage())
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PROFESSEUR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: CupertinoColors.tertiarySystemGroupedBackground,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
              context, 
               MaterialPageRoute(builder: (context) => StudentConnexionPage())
              );
            },
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: null,
              ),
              child: Text(
                'ELEVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color.fromARGB(255, 28, 28, 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
