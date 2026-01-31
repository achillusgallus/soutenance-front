import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/services/service_achievement.dart';

class StudentAchievementsPage extends StatefulWidget {
  const StudentAchievementsPage({super.key});

  @override
  State<StudentAchievementsPage> createState() =>
      _StudentAchievementsPageState();
}

class _StudentAchievementsPageState extends State<StudentAchievementsPage> {
  final AchievementService _achievementService = AchievementService();
  bool _isLoading = true;
  List<dynamic> _badges = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _achievementService.getAchievements();

    if (mounted) {
      if (data.isNotEmpty) {
        setState(() {
          _badges = data['badges'] ?? [];
          _stats = data;
          _isLoading = false;
        });
      } else {
        // Fallback or empty state
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForBadge(String id) {
    switch (id) {
      case 'premier_pas':
        return FontAwesomeIcons.shoePrints;
      case 'expert_quiz':
        return FontAwesomeIcons.award;
      case 'assidu':
        return FontAwesomeIcons.calendarCheck;
      case 'curieux':
        return FontAwesomeIcons.lightbulb;
      case 'maitre_temps':
        return FontAwesomeIcons.clock;
      case 'bibliothecaire':
        return FontAwesomeIcons.bookBookmark;
      default:
        return FontAwesomeIcons.medal;
    }
  }

  Color _getColorForBadge(String id) {
    switch (id) {
      case 'premier_pas':
        return const Color(0xFF6366F1);
      case 'expert_quiz':
        return const Color(0xFF10B981);
      case 'assidu':
        return const Color(0xFFF59E0B);
      case 'curieux':
        return const Color(0xFFEC4899);
      case 'maitre_temps':
        return const Color(0xFF8B5CF6);
      case 'bibliothecaire':
        return const Color(0xFF06B6D4);
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Badges & Succès',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelHeader(isDark),
                  const SizedBox(height: 32),
                  const Text(
                    'Vos Récompenses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_badges.isEmpty)
                    const Center(
                      child: Text("Aucun badge disponible pour le moment."),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _badges.length,
                      itemBuilder: (context, index) {
                        return _buildBadgeCard(_badges[index], isDark);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelHeader(bool isDark) {
    final level = _stats['level'] ?? 1;
    final title = _stats['title'] ?? 'Novice';
    final xp = _stats['xp'] ?? 0;
    final nextLevelXp = _stats['next_level_xp'] ?? 1000;
    final progress = (_stats['level_progress'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              'Lvl $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 1000).toInt()} / 1000 XP', // Approximation based on progress
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(dynamic badge, bool isDark) {
    // Les données du backend sont en Snake Case ou camelCase ?
    // Backend PHP retourne : 'title', 'desc', 'unlocked' (boolean), 'progress', 'id'
    final String id = badge['id'] ?? '';
    final String title = badge['title'] ?? '';
    final String desc = badge['desc'] ?? '';
    final bool unlocked = badge['unlocked'] == true;
    final double progress = (badge['progress'] ?? 0.0).toDouble();

    final IconData icon = _getIconForBadge(id);
    final Color color = _getColorForBadge(id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: unlocked
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          if (unlocked)
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? color : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: unlocked
                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                  : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          if (!unlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withOpacity(0.5),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${(progress * 100).toInt()}%",
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ] else ...[
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
          ],
        ],
      ),
    );
  }
}
