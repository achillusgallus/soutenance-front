import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/pages/teacher_connexion_page.dart';

class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key});

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
          Container(
            margin: EdgeInsets.only(left: 10),
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ELEVE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color.fromARGB(255, 3, 3, 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
