import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/student_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/students/student_cours.dart';


class StudentAcceuil extends StatefulWidget {
  const StudentAcceuil({super.key});

  @override
  State<StudentAcceuil> createState() => _StudentAcceuilState();
}

class _StudentAcceuilState extends State<StudentAcceuil> {

  final List<Map<String, dynamic>> datalist = [
    {'titre' : 'mathématique'},
    {'titre' : 'anglais'},
    {'titre' : 'français'},
    {'titre' : 'histoire-géographie'},
    {'titre' : 'phisique'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 216, 216, 219),
      body: SafeArea(
        child: ListView(
          children: [
            DashHeader(
              color1: Colors.blueAccent, 
              color2: Colors.green, 
              title: 'Bonjour cher étudiant', 
              title1: '6', 
              title2: '12', 
              title3: '45%', 
              subtitle: 'Prêt à apprendre aujourd\'hui', 
              subtitle1: 'matières', 
              subtitle2: ' les cours', 
              subtitle3: 'Progression'
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
                icon: FontAwesomeIcons.question,
                title: 'Quiz', 
                color: Colors.green,
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AdminDashboardPage())
                );
                 },
                ),
                ButtonCard(
                icon: FontAwesomeIcons.calendar,
                title: 'planning', 
                color: const Color.fromARGB(255, 216, 34, 180),
                onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const StudentDashboardPage() )
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
                MaterialPageRoute(builder: (context) => const TeacherDashboardPage())
                );
                 },
                )
              ],
            ),
          ]
        )
        ),
    );
  }
}