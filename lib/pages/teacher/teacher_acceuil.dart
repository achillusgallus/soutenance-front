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
  final Map<String, dynamic>? teacherData;

  const TeacherAcceuil({super.key, this.teacherData});

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
      // If teacher data is provided (admin viewing), use it instead of fetching from /me
      if (widget.teacherData != null) {
        final results = await Future.wait([
          getMatieresByUser(),
          api.read("/professeur/cours"),
          api.read("/professeur/quiz"),
        ]);

        setState(() {
          matieres = results[0] as List<dynamic>;
          profileData = widget.teacherData;
          cours = (results[1] as dynamic)?.data ?? [];
          quiz = (results[2] as dynamic)?.data ?? [];
          isLoading = false;
        });
      } else {
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
      }
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

  @override
  Widget build(BuildContext context) {
    String profName = profileData?['name'] ?? 'Enseignant';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF6366F1),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              DashHeader(
                color1: const Color(0xFF6366F1),
                color2: const Color(0xFF4F46E5),
                title: 'Bonjour, $profName',
                subtitle: 'Gérez vos cours et quiz aujourd\'hui',
                title1: matieres.length.toString(),
                subtitle1: 'Matières',
                title2: cours.length.toString(),
                subtitle2: 'Cours',
                title3: quiz.length.toString(),
                subtitle3: 'Quiz',
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('ACTIONS RAPIDES'),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Color(0xFF64748B),
                            size: 24,
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ButtonCard(
                          icon: FontAwesomeIcons.plus,
                          title: 'Nouveau',
                          color: const Color(0xFF6366F1),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddCoursePage(subjects: matieres),
                              ),
                            );
                            _refreshData();
                          },
                        ),
                        ButtonCard(
                          icon: FontAwesomeIcons.book,
                          title: 'Cours',
                          color: const Color(0xFF10B981),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeachCours(),
                              ),
                            );
                            _refreshData();
                          },
                        ),
                        ButtonCard(
                          icon: FontAwesomeIcons.vial,
                          title: 'Quiz',
                          color: const Color(0xFFF59E0B),
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
                          icon: FontAwesomeIcons.comments,
                          title: 'Forum',
                          color: const Color(0xFFEC4899),
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
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildSectionTitle('MES MATIÈRES'),
              ),
              const SizedBox(height: 20),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (matieres.isEmpty)
                _buildEmptyState()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: matieres.asMap().entries.map((entry) {
                      return _buildMatiereCard(entry.value, entry.key);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune matière affectée pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere, int index) {
    final color = MatiereColors[index % MatiereColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
            _refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(FontAwesomeIcons.book, color: color, size: 20),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matiere['nom'] ?? 'Sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matiere['classe'] ?? 'Classe non définie',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        matiere['description'] ?? 'Aucune description',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
