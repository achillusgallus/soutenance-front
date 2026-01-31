import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/pages/forum/page_message_forums.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/utils/security_utils.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    _fetchTopics();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        !isLoading &&
        currentPage < lastPage) {
      _loadMoreTopics();
    }
  }

  Future<void> _loadMoreTopics() async {
    if (mounted) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
      await _fetchTopics();
    }
  }

  Future<void> _fetchTopics() async {
    if (topics.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final res = await api.read(
        "/forums/${widget.forumId}/sujets?page=$currentPage",
      );
      if (mounted) {
        final data = res?.data;
        List<dynamic> fetchedTopics = [];

        if (data is Map && data.containsKey('data')) {
          fetchedTopics = data['data'];
          lastPage = data['last_page'] ?? 1;
        } else if (data is List) {
          fetchedTopics = data;
        }

        List<dynamic> newTopicsList;
        if (currentPage == 1) {
          newTopicsList = fetchedTopics;
        } else {
          newTopicsList = [...topics, ...fetchedTopics];
        }

        setState(() {
          topics = newTopicsList;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
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
              color1: AppTheme.primaryColor,
              color2: const Color(0xFF4F46E5),
              title: widget.forumTitle.toUpperCase(),
              subtitle: 'Discussions en cours',
              title1: topics.length.toString(),
              subtitle1: 'Sujets',
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    currentPage = 1;
                    topics = [];
                  });
                  await _fetchTopics();
                },
                color: const Color(0xFFF59E0B),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF59E0B),
                          ),
                        ),
                      )
                    : topics.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        itemCount: topics.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == topics.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            );
                          }
                          final topic = topics[index];
                          return _buildTopicCard(topic);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTopicDialog,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          "NOUVEAU SUJET",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
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
            color: Color(0xFFF8F9FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "Lancer une discussion",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Posez votre question ou partagez une idée avec la communauté.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 28),
              _buildFieldLabel("Titre du sujet"),
              CustomTextFormField(
                label: "Ex: Comment résoudre l'exercice 3 ?",
                hint: "",
                controller: titleController,
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: 20),
              _buildFieldLabel("Message / Description"),
              CustomTextFormField(
                label: "Détails de votre sujet...",
                hint: "",
                controller: subjectController,
                maxLines: 4,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "CRÉER LA DISCUSSION",
                isLoading: isSaving,
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  setInternalState(() => isSaving = true);
                  try {
                    final String safeTitle = SecurityUtils.sanitizeInput(
                      titleController.text,
                    );
                    final String safeContent = SecurityUtils.sanitizeInput(
                      subjectController.text,
                    );
                    await api.create("/forums/sujets", {
                      "forum_id": widget.forumId,
                      "titre": safeTitle,
                      "contenu": safeContent,
                    });
                    Navigator.pop(ctx);

                    // Refresh topics
                    setState(() {
                      currentPage = 1;
                      topics = [];
                    });
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTopicCard(dynamic topic) {
    final title = topic['titre'] ?? 'Sujet sans titre';
    final auteur =
        topic['auteur']?['name'] ?? topic['user_name'] ?? 'Utilisateur';
    final time = topic['created_at_human'] ?? '';
    final messagesCount = topic['messages_count'] ?? 0;
    final contenu = topic['contenu'] ?? '';

    // Generate avatar color based on author name
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final colorIndex = auteur.hashCode.abs() % colors.length;
    final avatarColor = colors[colorIndex];

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ForumChatPage(topicId: topic['id'], topicTitle: title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Larger avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [avatarColor.withOpacity(0.8), avatarColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      auteur.isEmpty ? '?' : auteur[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              auteur,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contenu.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          contenu,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (messagesCount > 0) ...[
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$messagesCount réponse${messagesCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pas encore de réponse',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
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
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.speaker_notes_off_rounded,
              size: 64,
              color: const Color(0xFFF59E0B).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucune discussion",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Soyez le premier à poser une question !",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _showAddTopicDialog,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "DÉMARRER UNE DISCUSSION",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
