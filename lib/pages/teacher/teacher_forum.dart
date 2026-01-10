import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/teacher/teacher_topic_list_page.dart';
import 'package:togoschool/service/api_service.dart';

class TeacherForum extends StatefulWidget {
  const TeacherForum({super.key});

  @override
  State<TeacherForum> createState() => _TeacherForumState();
}

class _TeacherForumState extends State<TeacherForum> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> forums = [];

  @override
  void initState() {
    super.initState();
    _loadForums();
  }

  Future<void> _loadForums() async {
    setState(() => isLoading = true);
    try {
      // NEW ENDPOINT created in Laravel
      final res = await api.read("/professeur/forums-list");
      if (mounted) {
        setState(() {
          forums = res?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            const DashHeader(
              color1: Color(0xFF6366F1),
              color2: Color(0xFF4F46E5),
              title: "ESPACE FORUM",
              subtitle: "Échangez avec vos étudiants",
              title1: "",
              subtitle1: "",
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadForums,
                color: const Color(0xFF6366F1),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      )
                    : forums.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        itemCount: forums.length,
                        itemBuilder: (context, index) {
                          final f = forums[index];
                          return _buildForumCard(f);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForumCard(dynamic forum) {
    final matiereNom = forum['matiere']?['nom'] ?? 'Matière inconnue';
    final classe = forum['matiere']?['classe'] ?? '';
    final titre = forum['titre'] ?? 'Forum';
    final sujetsCount = forum['sujets_count'] ?? 0;
    final messagesCount = forum['messages_count'] ?? 0;

    // Generate color based on forum id
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final colorIndex = (forum['id'] ?? 0) % colors.length;
    final color = colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherTopicListPage(
                  forumId: forum['id'],
                  forumTitle: titre,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with first letter
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      titre.isEmpty ? '?' : titre[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (messagesCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$messagesCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 14,
                            color: color.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "$matiereNom ${classe.isNotEmpty ? '($classe)' : ''}",
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$sujetsCount sujet${sujetsCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 64,
              color: const Color(0xFF6366F1).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun forum assigné",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vos forums apparaîtront ici",
            style: TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
