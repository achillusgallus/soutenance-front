import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/services/progress_service.dart';
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class StudentFavoritesPage extends StatefulWidget {
  const StudentFavoritesPage({super.key});

  @override
  State<StudentFavoritesPage> createState() => _StudentFavoritesPageState();
}

class _StudentFavoritesPageState extends State<StudentFavoritesPage> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await _progressService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int courseId) async {
    try {
      final success = await _progressService.toggleFavorite(courseId);
      if (success) {
        setState(() {
          _favorites.removeWhere((course) => course['id'] == courseId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours retiré des favoris'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du retrait des favoris'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCourse(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCours(
          matiereId: course['category_id'] ?? 1,
          matiereName: course['category_name'] ?? 'Cours',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEC4899),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final course = _favorites[index];
                  return _buildFavoriteCard(course);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.heart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun cours favori',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des cours à vos favoris pour les retrouver facilement',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _navigateToCourse(course),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FontAwesomeIcons.book,
                  color: const Color(0xFFEC4899),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['course_name'] ?? 'Cours',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['category_name'] ?? 'Catégorie',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (course['progress'] != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (course['progress'] ?? 0) / 100,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEC4899),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _removeFavorite(course['id']),
                    icon: const Icon(
                      FontAwesomeIcons.heart,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  if (course['progress'] != null)
                    Text(
                      '${course['progress']}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
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
