import 'package:flutter/material.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/admin/add_forum.dart';
import 'package:togoschool/pages/admin/add_matiere_page.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/pages/admin/admin_parameter.dart';
import 'package:togoschool/pages/admin/admin_professeur.dart';
import 'package:togoschool/pages/admin/admin_matiere.dart';
import 'package:togoschool/pages/admin/admin_student_page.dart';
import 'package:togoschool/service/api_service.dart';

class AdminAcceuil extends StatefulWidget {
  const AdminAcceuil({super.key});

  @override
  State<AdminAcceuil> createState() => _AdminAcceuilState();
}

class _AdminAcceuilState extends State<AdminAcceuil> {
  final api = ApiService();
  final List<Color> cardColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.redAccent,
    Colors.teal,
  ];

  final List<Color> MatiereColors = [
    const Color.fromARGB(255, 206, 88, 14),
    const Color.fromARGB(255, 53, 4, 252),
    const Color.fromARGB(255, 143, 221, 156),
    const Color.fromARGB(255, 176, 39, 39),
    const Color.fromARGB(255, 223, 82, 255),
    const Color.fromARGB(255, 186, 210, 7),
  ];

  bool isLoading = true;
  List<dynamic> teachers = [];
  List<dynamic> matieres = [];

  @override
  void initState() {
    super.initState();
    getTeachers();
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await api.read("/admin/users");
      final responseMatieres = await api.read("/admin/matieres");
      setState(() {
        final List<dynamic> allUsers = response?.data ?? [];
        teachers = allUsers.where((user) => user['role_id'] == 2).toList();
        matieres = responseMatieres?.data ?? [];
        isLoading = false;
      });
      return teachers;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: ListView(
          children: [
            DashHeader(
              color1: Colors.blueAccent,
              color2: Colors.green,
              title: 'Bonjour cher administrateur',
              title1: '6',
              title2: '12',
              title3: '45%',
              subtitle: 'admnistration du système',
              subtitle1: 'matières',
              subtitle2: ' les cours',
              subtitle3: 'Progression',
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              // width: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Action rapides',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          FontAwesomeIcons.gear,
                          color: Color.fromARGB(255, 50, 6, 132),
                        ),
                        label: Text(
                          '',
                          style: TextStyle(
                            color: Color.fromARGB(255, 50, 6, 132),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminParameter(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ButtonCard(
                  icon: FontAwesomeIcons.book,
                  title: 'créer',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMatierePage(),
                      ),
                    );
                  },
                ),
                ButtonCard(
                  icon: FontAwesomeIcons.userGraduate,
                  title: 'créer',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTeacherPage(),
                      ),
                    );
                  },
                ),
                ButtonCard(
                  icon: FontAwesomeIcons.circleUser,
                  title: 'voir',
                  color: const Color.fromARGB(255, 216, 34, 180),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminStudentPage(),
                      ),
                    );
                  },
                ),
                ButtonCard(
                  icon: FontAwesomeIcons.message,
                  title: 'créer',
                  color: const Color.fromARGB(255, 181, 114, 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddForumPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (teachers.isEmpty)
              const Center(child: Text("Aucun enseignant trouvé"))
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Enseignants",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (teachers.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminProfesseur(),
                                ),
                              );
                            },
                            child: const Text(
                              "Voir tout",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: teachers.length > 5 ? 5 : teachers.length,
                      itemBuilder: (context, index) {
                        var teacher = teachers[index]; // Map dynamique
                        var color =
                            cardColors[index %
                                cardColors.length]; // variation auto
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Card(
                            color: color.withOpacity(0.2), // couleur douce
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: color,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${teacher['email'] ?? ''}",
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            // Matieres Section
            if (!isLoading && matieres.isNotEmpty)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Matières",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (matieres.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminMatiere(),
                                ),
                              );
                            },
                            child: const Text(
                              "Voir tout",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: matieres.length > 5 ? 5 : matieres.length,
                      itemBuilder: (context, index) {
                        var matiere = matieres[index];
                        var color = MatiereColors[index % MatiereColors.length];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Card(
                            color: color.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: color,
                                    child: const Icon(
                                      Icons.book,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${matiere['nom'] ?? ''}",
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
