import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/services/service_progres.dart';
import 'package:togoschool/pages/eleves/cours_eleve.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class StudentFavoritesPage extends StatefulWidget {
  const StudentFavoritesPage({super.key});

  @override
  State<StudentFavoritesPage> createState() => _StudentFavoritesPageState();
}

class _StudentFavoritesPageState extends State<StudentFavoritesPage>
    with SingleTickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;
  List<dynamic> _favoriteCourses = [];
  List<dynamic> _favoriteMatieres = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFavorites() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _progressService.getFavorites(),
        _progressService.getMatiereFavorites(),
      ]);

      if (mounted) {
        setState(() {
          _favoriteCourses = results[0];
          _favoriteMatieres = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeCourseFavorite(int courseId) async {
    try {
      final success = await _progressService.toggleFavorite(courseId);
      if (success) {
        setState(() {
          _favoriteCourses.removeWhere((c) => c['id'] == courseId);
        });
      }
    } catch (e) {}
  }

  Future<void> _removeMatiereFavorite(int matiereId) async {
    try {
      final success = await _progressService.toggleMatiereFavorite(matiereId);
      if (success) {
        setState(() {
          _favoriteMatieres.removeWhere((m) => m['id'] == matiereId);
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Favoris',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.accentColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Cours", icon: Icon(FontAwesomeIcons.bookOpen, size: 16)),
            Tab(
              text: "Matières",
              icon: Icon(FontAwesomeIcons.layerGroup, size: 16),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildCoursesList(), _buildMatieresList()],
            ),
    );
  }

  Widget _buildCoursesList() {
    if (_favoriteCourses.isEmpty) {
      return _buildEmptyState("Aucun cours favori", FontAwesomeIcons.book);
    }
    return RefreshIndicator(
      onRefresh: _loadAllFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteCourses.length,
        itemBuilder: (context, index) {
          final course = _favoriteCourses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildMatieresList() {
    if (_favoriteMatieres.isEmpty) {
      return _buildEmptyState(
        "Aucune matière favorite",
        FontAwesomeIcons.layerGroup,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteMatieres.length,
        itemBuilder: (context, index) {
          final matiere = _favoriteMatieres[index];
          return _buildMatiereCard(matiere);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            FontAwesomeIcons.book,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          course['titre'] ?? 'Cours',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(course['matiere']?['nom'] ?? 'Matière'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeCourseFavorite(course['id']),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentCours(
                matiereId: course['matiere_id'] ?? 0,
                matiereName: course['matiere']?['nom'] ?? 'Cours',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            FontAwesomeIcons.layerGroup,
            color: AppTheme.accentColor,
            size: 20,
          ),
        ),
        title: Text(
          matiere['nom'] ?? 'Matière',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${matiere['classe'] ?? ''}"),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeMatiereFavorite(matiere['id']),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentCours(
                matiereId: matiere['id'],
                matiereName: matiere['nom'] ?? 'Cours',
              ),
            ),
          );
        },
      ),
    );
  }
}
