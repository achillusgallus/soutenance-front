import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/pages/students/student_forum.dart';
import 'package:togoschool/pages/students/student_profil.dart';
import 'package:togoschool/pages/students/student_quiz_page.dart';
import 'package:togoschool/service/api_service.dart';

class StudentAcceuil extends StatefulWidget {
  const StudentAcceuil({super.key});

  @override
  State<StudentAcceuil> createState() => _StudentAcceuilState();
}

class _StudentAcceuilState extends State<StudentAcceuil> {
  final api = ApiService();
  bool isLoading = true;
  String studentName = "Étudiant";
  String studentClasse = "";
  List<dynamic> matieres = [];

  @override
  void initState() {
    super.initState();
    studentMatieres();
  }

  Future<void> studentMatieres() async {
    setState(() {
      isLoading = true;
    });
    try {
      // 1. Récupérer les infos de l'étudiant via /me
      final userResponse = await api.read("/me");
      if (userResponse != null && userResponse.data != null) {
        final userData = userResponse.data;
        setState(() {
          studentName = userData['name'] ?? "Étudiant";
          studentClasse = userData['classe'] ?? "";
        });
        print("DEBUG - Student Name: $studentName");
        print("DEBUG - Student Classe: '$studentClasse'");
      }

      // 2. Récupérer les matières filtrées par le backend selon la classe de l'élève
      final matieresResponse = await api.read("/student/matieres");
      if (matieresResponse != null && matieresResponse.data != null) {
        // Le backend retourne soit { data: [...] } (paginé) soit directement [...]
        final dynamic responseData = matieresResponse.data;
        List<dynamic> fetchedMatieres = [];

        if (responseData is Map && responseData.containsKey('data')) {
          // Réponse paginée
          fetchedMatieres = responseData['data'] ?? [];
        } else if (responseData is List) {
          // Réponse directe
          fetchedMatieres = responseData;
        }

        print(
          "DEBUG - Total matieres fetched from backend: ${fetchedMatieres.length}",
        );

        setState(() {
          matieres = fetchedMatieres;
          isLoading = false;
        });

        // Afficher les matières reçues pour vérification
        for (var m in matieres) {
          print("DEBUG - Matiere reçue: ${m['nom']}, Classe: ${m['classe']}");
        }
      } else {
        print("DEBUG - No matieres response received");
        setState(() {
          isLoading = false;
          matieres = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Erreur lors de la récupération des données: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: studentMatieres,
        color: const Color(0xFF6366F1),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            DashHeader(
              color1: const Color(0xFF6366F1),
              color2: const Color(0xFF8B5CF6),
              title: "Bonjour, $studentName",
              subtitle: 'Prêt à apprendre aujourd\'hui ?',
              title1: matieres.length.toString(),
              subtitle1: 'Matières',
              title2: '0',
              subtitle2: 'Quiz',
              title3: '0',
              subtitle3: 'Forums',
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIONS RAPIDES',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionCard(
                        icon: FontAwesomeIcons.bookOpen,
                        title: 'Mes Cours',
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentCours(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: FontAwesomeIcons.vial,
                        title: 'Quiz',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentQuizPage(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: FontAwesomeIcons.comments,
                        title: 'Forum',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentForum(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: FontAwesomeIcons.user,
                        title: 'Profil',
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentProfil(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'MES MATIÈRES',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    )
                  else if (matieres.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.folderOpen,
                              size: 48,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Aucune matière trouvée pour votre classe.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matieres.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final matiere = matieres[index];
                        return _buildMatiereCard(matiere);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereCard(dynamic matiere) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to courses page filtered by this subject
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentCours(
                  matiereId: matiere['id'],
                  matiereName: matiere['nom'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.book,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matiere['nom'] ?? 'Matière sans nom',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matiere['description'] ??
                            'Aucune description disponible',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
