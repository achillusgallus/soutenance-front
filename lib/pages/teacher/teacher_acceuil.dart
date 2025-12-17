import 'package:flutter/material.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/students/student_cours.dart';

class TeacherAcceuil extends StatefulWidget {
  const TeacherAcceuil({super.key});

  @override
  State<TeacherAcceuil> createState() => _TeacherAcceuilState();
}

class _TeacherAcceuilState extends State<TeacherAcceuil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            DashHeader(
              color1: Colors.blueAccent, 
              color2: Colors.green, 
              title: 'Bonjour cher professeur', 
              title1: '243', 
              title2: '60', 
              title3: '45%', 
              subtitle: 'soyez la bienvenue sur notre plateforme de cours', 
              subtitle1: 'Elèves', 
              subtitle2: ' les cours', 
              subtitle3: 'Question'
              ),
              SizedBox(height: 10),
            Text('Action rapides',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
               ),
               ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                ButtonCard(
                icon: FontAwesomeIcons.bookBible,
                title: 'cours', 
                color: Colors.blueAccent,
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const StudentCours() )
                 );
                 },
                ),
                ButtonCard(
                icon: FontAwesomeIcons.plus,
                title: 'ajouter', 
                color: Colors.green,
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const StudentCours() )
                );
                 },
                ),
                ButtonCard(
                icon: FontAwesomeIcons.person,
                title: 'élèves', 
                color: const Color.fromARGB(255, 216, 34, 180),
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const StudentCours() )
                );
                 },
                ),
                ButtonCard(
                icon: FontAwesomeIcons.message,
                title: 'forum', 
                color: const Color.fromARGB(255, 181, 114, 14),
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const StudentCours() )
                );
                 },
                )
              ],
            )
          ],
        )
        ),
    );
  }
}