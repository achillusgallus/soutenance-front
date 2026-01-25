import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/dash_header.dart'; // We will replace DashHeader usage with custom modern header
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/pages/students/student_forum.dart';
import 'package:togoschool/pages/students/student_profil.dart';
import 'package:togoschool/pages/students/student_quiz_page.dart';
import 'package:togoschool/pages/students/student_progress_page.dart';
import 'package:togoschool/pages/students/student_favorites_page.dart';
import 'package:togoschool/pages/students/student_notes_page.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/service/progress_service.dart';
import 'package:togoschool/utils/security_utils.dart'; // Used for search input sanitization

class StudentAcceuil extends StatefulWidget {
  final VoidCallback? toggleTheme;
  const StudentAcceuil({super.key, this.toggleTheme});

  @override
  State<StudentAcceuil> createState() => _StudentAcceuilState();
}

class _StudentAcceuilState extends State<StudentAcceuil> {
  final api = ApiService();
  final ProgressService _progressService = ProgressService();
  bool isLoading = true;
  String studentName = "Étudiant";
  String studentClasse = "";
  List<dynamic> matieres = [];
  List<dynamic> filteredMatieres = [];
  int quizCount = 0;
  int forumCount = 0;
  int favoriteCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    studentMatieres();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMatieres(String query) {
    if (query.isEmpty) {
      setState(() => filteredMatieres = matieres);
      return;
    }
    final safeQuery = SecurityUtils.sanitizeInput(query).toLowerCase();
    setState(() {
      filteredMatieres = matieres.where((m) {
        final nom = (m['nom'] ?? '').toString().toLowerCase();
        final desc = (m['description'] ?? '').toString().toLowerCase();
        return nom.contains(safeQuery) || desc.contains(safeQuery);
      }).toList();
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _progressService.getFavorites();
      if (mounted) {
        setState(() {
          favoriteCount = favorites.length;
        });
      }
    } catch (e) {
      // En cas d'erreur, on garde 0
      if (mounted) {
        setState(() {
          favoriteCount = 0;
        });
      }
    }
  }

  Future<void> studentMatieres() async {
    setState(() => isLoading = true);
    try {
      // 1. Infos user
      final userResponse = await api.read("/me");
      if (userResponse?.data != null) {
        final userData = userResponse!.data is Map
            ? userResponse.data
            : userResponse.data['user'];
        // Adjust depending on API response structure
        setState(() {
          studentName = userData is Map
              ? (userData['name'] ?? "Étudiant")
              : "Étudiant";
          studentClasse = userData is Map ? (userData['classe'] ?? "") : "";
        });
      }

      // 2. Data
      final results = await Future.wait([
        api.read("/student/matieres"),
        api.read("/quiz"),
        api.read("/forums"),
      ]);

      if (mounted) {
        setState(() {
          // Matières
          final matieresRes = results[0]?.data;
          if (matieresRes is Map && matieresRes.containsKey('data')) {
            matieres = matieresRes['data'] ?? [];
          } else if (matieresRes is List) {
            matieres = matieresRes;
          }
          filteredMatieres = matieres;

          // Quiz
          final quizRes = results[1]?.data;
          // Handle potential pagination wrapper
          if (quizRes is Map && quizRes.containsKey('total')) {
            quizCount = quizRes['total'] ?? 0;
          } else if (quizRes is List) {
            quizCount = quizRes.length;
          } else if (quizRes is Map && quizRes.containsKey('data')) {
            quizCount = (quizRes['data'] as List).length;
          }

          // Forums
          final forumsRes = results[2]?.data;
          if (forumsRes is List) {
            forumCount = forumsRes.length;
          } else if (forumsRes is Map && forumsRes.containsKey('data')) {
            forumCount = (forumsRes['data'] as List).length;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Erreur Accueil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Design Palette
    const bgGradient = LinearGradient(
      colors: [Color(0xFFF8F9FD), Color(0xFFF1F5F9)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : RefreshIndicator(
                onRefresh: studentMatieres,
                color: const Color(0xFF6366F1),
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 32),
                            _buildSearchBar(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              "Mes Matières",
                              filteredMatieres.length,
                            ),
                            const SizedBox(height: 16),
                            _buildMatieresList(),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6366F1),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bonjour,",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (studentClasse.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Classe : $studentClasse",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentProfil()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Première ligne de cartes existantes
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Cours",
                matieres.length.toString(),
                FontAwesomeIcons.bookOpen,
                const Color(0xFF6366F1),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentCours()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Quiz",
                quizCount.toString(),
                FontAwesomeIcons.vial,
                const Color(0xFF10B981),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentQuizPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Forums",
                forumCount.toString(),
                FontAwesomeIcons.comments,
                const Color(0xFFF59E0B),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentForum()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Deuxième ligne avec les nouvelles fonctionnalités
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Progression",
                "Voir",
                FontAwesomeIcons.chartLine,
                const Color(0xFF8B5CF6),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentProgressPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Favoris",
                favoriteCount.toString(),
                FontAwesomeIcons.heart,
                const Color(0xFFEC4899),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentFavoritesPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Notes",
                "Voir",
                FontAwesomeIcons.stickyNote,
                const Color(0xFF14B8A6),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentNotesPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMatieres,
        decoration: const InputDecoration(
          hintText: "Rechercher une matière...",
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$count",
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatieresList() {
    if (filteredMatieres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                FontAwesomeIcons.folderOpen,
                size: 48,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              const Text(
                "Aucune matière trouvée.",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredMatieres.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return _buildMatiereCard(filteredMatieres[index]);
      },
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818cf8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      FontAwesomeIcons.bookOpen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matiere['nom'] ?? 'Matière',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matiere['description'] ?? 'Appuyez pour voir les cours',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
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
