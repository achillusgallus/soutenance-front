import 'package:flutter/material.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/admin/add_forum.dart';
import 'package:togoschool/pages/admin/add_matiere_page.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/pages/admin/admin_forum_page.dart';
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
  List<dynamic> forums = [];

  @override
  void initState() {
    super.initState();
    getTeachers();
  }

  Future<void> getTeachers() async {
    try {
      final results = await Future.wait([
        api.read("/admin/users"),
        api.read("/admin/matieres"),
      ]);

      if (!mounted) return;

      setState(() {
        final List<dynamic> allUsers = results[0]?.data ?? [];
        teachers = allUsers.where((user) => user['role_id'] == 2).toList();
        matieres = results[1]?.data ?? [];
      });

      // Fetch forums separately as it's a new feature
      final forumRes = await api.read("/admin/forums");
      if (mounted) {
        setState(() {
          forums = forumRes?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Slightly off-white for professional look
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getTeachers,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              DashHeader(
                color1: Colors.blueAccent,
                color2: Colors.green,
                title: 'Bonjour Administrateur',
                title1: matieres.length.toString(),
                title2: teachers.length.toString(),
                title3: '45%',
                subtitle: 'Supervision du système',
                subtitle1: 'Matières',
                subtitle2: 'Enseignants',
                subtitle3: 'Progression',
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIONS RAPIDES',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.user,
                        size: 20,
                        color: Colors.black54,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ButtonCard(
                      icon: FontAwesomeIcons.book,
                      title: 'Créer',
                      color: Colors.blueAccent,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMatierePage(),
                          ),
                        );
                        getTeachers();
                      },
                    ),
                    ButtonCard(
                      icon: FontAwesomeIcons.userGraduate,
                      title: 'Créer',
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTeacherPage(),
                          ),
                        );
                        getTeachers();
                      },
                    ),
                    ButtonCard(
                      icon: FontAwesomeIcons.circleUser,
                      title: 'Voir',
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
                      title: 'Créer',
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
              ),
              const SizedBox(height: 30),

              // Teachers Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ENSEIGNANTS RECENTS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (teachers.length > 5)
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminProfesseur(),
                            ),
                          );
                          getTeachers();
                        },
                        child: const Text("Voir tout"),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (teachers.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Aucun enseignant trouvé",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: teachers.length > 5 ? 5 : teachers.length,
                    itemBuilder: (context, index) {
                      var teacher = teachers[index];
                      var color = cardColors[index % cardColors.length];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Icon(
                                    Icons.person,
                                    color: color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${teacher['email'] ?? ''}",
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
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

              const SizedBox(height: 30),

              // Matieres Section
              if (!isLoading && matieres.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "MATIÈRES",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (matieres.length > 1)
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminMatiere(),
                                  ),
                                );
                                getTeachers();
                              },
                              child: const Text("Voir tout"),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: matieres.length > 5 ? 5 : matieres.length,
                        itemBuilder: (context, index) {
                          var matiere = matieres[index];
                          var color =
                              MatiereColors[index % MatiereColors.length];

                          // Try to find professor name if user_name is missing
                          String profName = matiere['user_name'] ?? '';
                          if (profName.isEmpty && matiere['user_id'] != null) {
                            var prof = teachers.firstWhere(
                              (t) => t['id'] == matiere['user_id'],
                              orElse: () => null,
                            );
                            if (prof != null) {
                              profName = "${prof['name']} ${prof['surname']}";
                            }
                          }
                          if (profName.isEmpty) profName = "Non attribué";

                          return Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Card(
                              elevation: 2,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      color.withOpacity(0.1),
                                      color.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${matiere['nom'] ?? ''}",
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 10,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            profName,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
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

              const SizedBox(height: 30),

              // Recent Forums Section
              if (!isLoading && forums.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "FORUMS RÉCENTS",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 1.0,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminForumPage(),
                                ),
                              );
                            },
                            child: const Text("Voir tout"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: forums.length > 5 ? 5 : forums.length,
                        itemBuilder: (context, index) {
                          var forum = forums[index];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.forum,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    forum['titre'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    forum['matiere_nom'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
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
      ),
    );
  }
}
