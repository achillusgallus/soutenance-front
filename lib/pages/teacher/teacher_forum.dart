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
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: Color(0xFF6366F1),
              color2: Color(0xFF4F46E5),
              title: "Mes Forums",
              subtitle: "Sélectionnez une matière",
              title1: "${forums.length}",
              subtitle1: "Total",
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadForums,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : forums.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              builder: (context) => TeacherTopicListPage(
                forumId: forum['id'],
                forumTitle: forum['titre'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.forum, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forum['titre'] ?? 'Forum',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$matiereNom ${classe.isNotEmpty ? '($classe)' : ''}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
            "Aucun forum assigné à vos matières",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
