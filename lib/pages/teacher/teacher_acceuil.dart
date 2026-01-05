import 'package:flutter/material.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/teacher/add_course_page.dart';
import 'package:togoschool/pages/teacher/teach_cours.dart';
import 'package:togoschool/pages/teacher/teacher_quiz.dart';
import 'package:togoschool/pages/teacher/teacher_forum.dart';
import 'package:togoschool/pages/teacher/teacher_parameter.dart';
import 'package:togoschool/service/api_service.dart';

class TeacherAcceuil extends StatefulWidget {
  const TeacherAcceuil({super.key});

  @override
  State<TeacherAcceuil> createState() => _TeacherAcceuilState();
}

class _TeacherAcceuilState extends State<TeacherAcceuil> {
  final api = ApiService();
  List<dynamic> matieres = [];
  List<dynamic> cours = [];
  List<dynamic> quiz = [];
  Map<String, dynamic>? profileData;
  bool isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final results = await Future.wait([
        getMatieresByUser(),
        api.read("/me"),
        api.read("/professeur/cours"),
        api.read("/professeur/quiz"),
      ]);

      setState(() {
        matieres = results[0] as List<dynamic>;
        profileData = (results[1] as dynamic)?.data;
        cours = (results[2] as dynamic)?.data ?? [];
        quiz = (results[3] as dynamic)?.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<List<dynamic>> getMatieresByUser() async {
    final response = await api.read("/professeur/matieres");

    if (response != null && response.statusCode == 200) {
      return response.data; // Liste des matières
    } else {
      throw Exception("Impossible de récupérer les matières");
    }
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere, int index) {
    final color = MatiereColors[index % MatiereColors.length];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeachCours(
                  filterSubjectId: matiere['id'],
                  filterSubjectName: matiere['nom'],
                ),
              ),
            );
            // Refresh data when returning, in case a course was added/deleted
            _refreshData();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 6, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matiere['nom'] ?? 'Sans nom',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            matiere['description'] ??
                                'Pas de description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              matiere['classe'] ?? 'Classe non définie',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Slightly off-white for professional look
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              DashHeader(
                color1: Colors.blueAccent,
                color2: Colors.green,
                title: 'Bonjour Mr/Mme ${profileData?['name'] ?? 'Enseignant'}',
                title1: matieres.length.toString(),
                title2: cours.length.toString(),
                title3: quiz.length.toString(),
                subtitle: 'Votre espace enseignant',
                subtitle1: 'Mes Matières',
                subtitle2: 'Mes Cours',
                subtitle3: 'Mes Quiz',
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
                            builder: (context) => const TeacherParameter(),
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
                      icon: Icons.add_box,
                      title: 'Nouveau',
                      color: Colors.blueAccent,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCoursePage(subjects: matieres),
                          ),
                        );
                      },
                    ),
                    ButtonCard(
                      icon: Icons.library_books,
                      title: 'Mes Cours',
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeachCours(),
                          ),
                        );
                      },
                    ),
                    ButtonCard(
                      icon: Icons.quiz,
                      title: 'Quiz',
                      color: const Color.fromARGB(255, 216, 34, 180),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeacherQuiz(),
                          ),
                        );
                      },
                    ),
                    ButtonCard(
                      icon: Icons.forum,
                      title: 'Forum',
                      color: const Color.fromARGB(255, 181, 114, 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeacherForum(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'MES MATIÈRES',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (matieres.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune matière affectée',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...matieres.asMap().entries.map((entry) {
                  return _buildMatiereCard(entry.value, entry.key);
                }).toList(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
