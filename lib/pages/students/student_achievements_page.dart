import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StudentAchievementsPage extends StatelessWidget {
  const StudentAchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> badges = [
      {
        'title': 'Premier Pas',
        'desc': 'A fini son premier cours sur la plateforme.',
        'icon': FontAwesomeIcons.shoePrints,
        'color': const Color(0xFF6366F1),
        'unlocked': true,
      },
      {
        'title': 'Expert Quiz',
        'desc': 'A obtenu 100% à 3 quiz différents.',
        'icon': FontAwesomeIcons.award,
        'color': const Color(0xFF10B981),
        'unlocked': true,
      },
      {
        'title': 'Assidu',
        'desc': 'S\'est connecté 5 jours consécutifs.',
        'icon': FontAwesomeIcons.calendarCheck,
        'color': const Color(0xFFF59E0B),
        'unlocked': false,
      },
      {
        'title': 'Curieux',
        'desc': 'A posé 5 questions aux professeurs.',
        'icon': FontAwesomeIcons.lightbulb,
        'color': const Color(0xFFEC4899),
        'unlocked': true,
      },
      {
        'title': 'Maître du Temps',
        'desc': 'A passé plus de 10 heures à étudier.',
        'icon': FontAwesomeIcons.clock,
        'color': const Color(0xFF8B5CF6),
        'unlocked': false,
      },
      {
        'title': 'Bibliothécaire',
        'desc': 'A ajouté 10 cours en favoris.',
        'icon': FontAwesomeIcons.bookBookmark,
        'color': const Color(0xFF06B6D4),
        'unlocked': true,
      },
    ];

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
      body: SingleChildScrollView(
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                return _buildBadgeCard(badges[index], isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelHeader(bool isDark) {
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
            child: const Text(
              'Lvl 5',
              style: TextStyle(
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
                const Text(
                  'Apprenti Sage',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1250 / 2000 XP',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.625,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildBadgeCard(Map<String, dynamic> badge, bool isDark) {
    bool unlocked = badge['unlocked'];
    Color color = badge['color'];

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
              badge['icon'],
              color: unlocked ? color : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge['title'],
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
            badge['desc'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            Icon(Icons.lock, size: 14, color: Colors.grey[400]),
          ],
        ],
      ),
    );
  }
}
