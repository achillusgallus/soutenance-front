import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/forum/forum_topic_list_page.dart'; // To be created
import 'package:togoschool/service/api_service.dart';

class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
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
      final res = await api.read("/forums");
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
            const DashHeader(
              color1: Color(0xFFF59E0B),
              color2: Color(0xFFD97706),
              title: "Espaces Forum",
              subtitle: 'Échangez avec vos professeurs et camarades',
              title1: "",
              subtitle1: "",
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchForums,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : forums.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: forums.length,
                        itemBuilder: (context, index) {
                          final forum = forums[index];
                          return _buildForumCard(forum);
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.forum_outlined, color: Colors.amber),
        ),
        title: Text(
          forum['titre'] ?? 'Forum sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          "Matière: ${forum['matiere_nom'] ?? 'N/A'}",
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumTopicListPage(
                forumId: forum['id'],
                forumTitle: forum['titre'],
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
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Aucun forum disponible",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
