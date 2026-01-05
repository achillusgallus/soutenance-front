import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/forum/forum_chat_page.dart';
import 'package:togoschool/service/api_service.dart';

class TeacherTopicListPage extends StatefulWidget {
  final int forumId;
  final String forumTitle;

  const TeacherTopicListPage({
    super.key,
    required this.forumId,
    required this.forumTitle,
  });

  @override
  State<TeacherTopicListPage> createState() => _TeacherTopicListPageState();
}

class _TeacherTopicListPageState extends State<TeacherTopicListPage> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() => isLoading = true);
    try {
      // Reusing the general endpoint to get topics for this forum
      final res = await api.read("/forums/${widget.forumId}/sujets");
      if (mounted) {
        setState(() {
          topics = res?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
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
            DashHeader(
              color1: const Color(0xFF6366F1),
              color2: const Color(0xFF4F46E5),
              title: widget.forumTitle,
              subtitle: 'Questions des élèves',
              title1: topics.length.toString(),
              subtitle1: 'Sujets',
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchTopics,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : topics.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: topics.length,
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return _buildTopicCard(topic);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(dynamic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          topic['titre'] ?? 'Sujet sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  topic['auteur']?['name'] ?? topic['user_name'] ?? 'Élève',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                // Handling potential missing created_at_human if sticking to raw student endpoint
                Text(
                  topic['created_at_human'] ?? 'Récemment',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (topic['contenu'] != null) ...[
              const SizedBox(height: 4),
              Text(
                topic['contenu'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Répondre",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumChatPage(
                topicId: topic['id'],
                topicTitle: topic['titre'],
                isTeacher: true, // IMPORTANT: Enable teacher mode
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucune question pour le moment",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
