import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/forum/page_message_forums.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/core/theme/app_theme.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: AppTheme.primaryColor,
              color2: AppTheme.primaryColor,
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
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: topics.length,
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return _buildTopicCard(topic, theme);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(dynamic topic, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          topic['titre'] ?? 'Sujet sans titre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  topic['auteur']?['name'] ?? topic['user_name'] ?? 'Élève',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                // Handling potential missing created_at_human if sticking to raw student endpoint
                Text(
                  topic['created_at_human'] ?? 'Récemment',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            if (topic['contenu'] != null) ...[
              const SizedBox(height: 4),
              Text(
                topic['contenu'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Répondre",
            style: TextStyle(
              color: AppTheme.primaryColor,
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune question pour le moment",
            style: TextStyle(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }
}
