import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/admin/add_forum.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/pages/forum/forum_topic_list_page.dart';

class AdminForumPage extends StatefulWidget {
  const AdminForumPage({super.key});

  @override
  State<AdminForumPage> createState() => _AdminForumPageState();
}

class _AdminForumPageState extends State<AdminForumPage> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> forums = [];

  @override
  void initState() {
    super.initState();
    _fetchForums();
  }

  Future<void> _fetchForums() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read("/admin/forums");
      if (mounted) {
        setState(() {
          forums = res?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la récupération des forums: $e"),
          ),
        );
      }
    }
  }

  Future<void> _deleteForum(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le forum"),
        content: const Text("Êtes-vous sûr de vouloir supprimer ce forum ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await api.delete("/admin/forums/$id");
        _fetchForums();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Forum supprimé avec succès")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          DashHeader(
            color1: const Color(0xFFF59E0B),
            color2: const Color(0xFFD97706),
            title: "GESTION FORUMS",
            subtitle: "Supervisez les espaces de discussion",
            title1: forums.length.toString(),
            subtitle1: "Forums",
            title2: forums
                .where((f) => (f['sujets_count'] ?? 0) > 0)
                .length
                .toString(),
            subtitle2: "Actifs",
            title3: forums
                .fold<int>(
                  0,
                  (sum, f) => sum + (f['sujets_count'] as int? ?? 0),
                )
                .toString(),
            subtitle3: "Sujets",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchForums,
              color: const Color(0xFFF59E0B),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFF59E0B),
                        ),
                      ),
                    )
                  : forums.isEmpty
                  ? _buildEmptyState()
                  : _buildForumList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddForumPage()),
          );
          if (result == true) _fetchForums();
        },
        backgroundColor: const Color(0xFFF59E0B),
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          "NOUVEAU FORUM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildForumList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: forums.length,
      itemBuilder: (context, index) {
        final forum = forums[index];
        final sujetsCount = forum['sujets_count'] ?? 0;
        final messagesCount = forum['messages_count'] ?? 0;

        // Generate color based on index
        final colors = [
          const Color(0xFF6366F1),
          const Color(0xFF10B981),
          const Color(0xFFEC4899),
          const Color(0xFFF59E0B),
          const Color(0xFF8B5CF6),
        ];
        final colorIndex = index % colors.length;
        final color = colors[colorIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Navigate to topics list
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForumTopicListPage(
                      forumId: forum['id'],
                      forumTitle: forum['titre'] ?? 'Forum',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                              (forum['titre'] ?? '?')[0].toUpperCase(),
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
                              Text(
                                forum['titre'] ?? 'Sans titre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 14,
                                    color: color.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    forum['matiere_nom'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteForum(forum['id']),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ).withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatBadge(
                          icon: Icons.chat_bubble_outline,
                          label:
                              '$sujetsCount sujet${sujetsCount > 1 ? 's' : ''}',
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBadge(
                          icon: Icons.message_outlined,
                          label:
                              '$messagesCount message${messagesCount > 1 ? 's' : ''}',
                          color: const Color(0xFF10B981),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 80,
              color: const Color(0xFFF59E0B).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun forum trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Commencez par créer votre premier espace de discussion.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
