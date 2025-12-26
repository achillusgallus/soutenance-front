import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/forum/forum_chat_page.dart';
import 'package:togoschool/service/api_service.dart';

class TeacherForum extends StatefulWidget {
  const TeacherForum({super.key});

  @override
  State<TeacherForum> createState() => _TeacherForumState();
}

class _TeacherForumState extends State<TeacherForum> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read("/professeur/forums/sujets");
      if (mounted) {
        setState(() {
          topics = res?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            const DashHeader(
              color1: Color(0xFF6366F1),
              color2: Color(0xFF4F46E5),
              title: "Forum Professeur",
              subtitle: "Répondez aux questions des élèves",
              title1: "0",
              subtitle1: "Total",
              title2: "0",
              subtitle2: "Nouveaux",
              title3: "0",
              subtitle3: "Répondus",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTopics,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : topics.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: topics.length,
                        itemBuilder: (context, index) {
                          final t = topics[index];
                          return _buildTopicCard(t);
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumChatPage(
                topicId: topic['id'],
                topicTitle: topic['titre'],
                isTeacher: true,
              ),
            ),
          ).then((_) => _loadTopics());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    radius: 18,
                    child: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic['user_name'] ?? 'Élève',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          topic['created_at_human'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      topic['matiere_nom'] ?? 'Matière',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topic['titre'] ?? 'Sans titre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${topic['messages_count'] ?? 0} messages",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "RÉPONDRE",
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Aucun sujet de discussion disponible",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
