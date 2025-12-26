import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/pages/forum/forum_chat_page.dart';
import 'package:togoschool/service/api_service.dart';

class ForumTopicListPage extends StatefulWidget {
  final int forumId;
  final String forumTitle;

  const ForumTopicListPage({
    super.key,
    required this.forumId,
    required this.forumTitle,
  });

  @override
  State<ForumTopicListPage> createState() => _ForumTopicListPageState();
}

class _ForumTopicListPageState extends State<ForumTopicListPage> {
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
      }
    }
  }

  void _showAddTopicDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setInternalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nouveau sujet de discussion",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextFormField(
                label: "Titre du sujet",
                hint: "Quel est votre problème ?",
                controller: titleController,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: "Matière / Thème",
                hint: "Ex: Équations quadratiques",
                controller: subjectController,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "CRÉER LA DISCUSSION",
                isLoading: isSaving,
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  setInternalState(() => isSaving = true);
                  try {
                    await api.create("/forums/sujets", {
                      "forum_id": widget.forumId,
                      "titre": titleController.text.trim(),
                      "matiere_nom": subjectController.text.trim(),
                    });
                    Navigator.pop(ctx);
                    _fetchTopics();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                  } finally {
                    setInternalState(() => isSaving = false);
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: const Color(0xFFF59E0B),
              color2: const Color(0xFFD97706),
              title: widget.forumTitle,
              subtitle: 'Discussions en cours',
              title1: topics.length.toString(),
              subtitle1: 'Sujets',
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add_comment),
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
                  topic['user_name'] ?? 'Élève',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  topic['created_at_human'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumChatPage(
                topicId: topic['id'],
                topicTitle: topic['titre'],
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
            Icons.speaker_notes_off_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucune discussion dans ce forum",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showAddTopicDialog,
            child: const Text("Démarrer la première discussion"),
          ),
        ],
      ),
    );
  }
}
