import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
// import 'package:togoschool/service/api_service.dart'; // Supprimé

class TeacherForum extends StatefulWidget {
  const TeacherForum({super.key});

  @override
  State<TeacherForum> createState() => _TeacherForumState();
}

class _TeacherForumState extends State<TeacherForum> {
  // final api = ApiService(); // Supprimé
  bool isLoading = false; // Initialisé à false
  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    // Les appels d'API ont été supprimés par l'utilisateur
  }

  void _showReplyDialog(dynamic topic) {
    final replyController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInternalState) => Padding(
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
              Text(
                "Répondre à: ${topic['titre']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: "Votre réponse",
                hint: "Écrivez votre message ici...",
                controller: replyController,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: "ENVOYER",
                isLoading: isSaving,
                onPressed: () async {
                  if (replyController.text.isEmpty) return;
                  // L'appel d'envoi de réponse API a été supprimé par l'utilisateur
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          FormHeader(
            title: "Forum Enseignant",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTopics,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTopicsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList() {
    if (topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "Aucun sujet de discussion affecté",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final t = topics[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['user']?['name'] ?? 'Élève',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          t['created_at'] ?? 'Aujourd\'hui',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
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
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t['matiere']?['nom'] ?? 'Matière',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                t['titre'] ?? 'Pas de titre',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t['description'] ?? '',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(t),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text("Répondre"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
