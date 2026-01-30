import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/teacher/add_quiz_page.dart';
import 'package:togoschool/pages/teacher/quiz_questions_page.dart';
import 'package:togoschool/services/api_service.dart';

class TeacherQuiz extends StatefulWidget {
  const TeacherQuiz({super.key});

  @override
  State<TeacherQuiz> createState() => _TeacherQuizState();
}

class _TeacherQuizState extends State<TeacherQuiz> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> quizzes = [];
  List<dynamic> subjects = [];
  final Map<int, int> _questionCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        api.read("/professeur/matieres"),
        api.read("/professeur/quiz"),
      ]);

      if (mounted) {
        setState(() {
          subjects = results[0]?.data ?? [];
          quizzes = results[1]?.data ?? [];
          isLoading = false;
        });
        _fetchQuestionCounts();
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

  Future<void> _fetchQuestionCounts() async {
    for (var quiz in quizzes) {
      final int quizId = quiz['id'];
      try {
        final response = await api.read("/professeur/quiz/$quizId/questions");
        if (response != null && mounted) {
          final List<dynamic> questions = response.data ?? [];
          setState(() {
            _questionCounts[quizId] = questions.length;
          });
        }
      } catch (e) {
        debugPrint("Erreur questions quiz $quizId: $e");
      }
    }
  }

  Future<void> _deleteQuiz(int id) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm == true) {
      try {
        await api.delete("/professeur/quiz/$id");
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Échec: $e")));
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Supprimer le Quiz ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Toutes les questions associées seront également supprimées.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "ANNULER",
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "SUPPRIMER",
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          DashHeader(
            color1: theme.primaryColor,
            color2: theme.primaryColorDark,
            title: "GESTION DES QUIZ",
            subtitle: 'Créez et gérez vos évaluations interactives',
            title1: quizzes.length.toString(),
            subtitle1: 'Quiz',
            title2: _questionCounts.values
                .fold(0, (sum, count) => sum + count)
                .toString(),
            subtitle2: 'Questions',
            title3: "",
            subtitle3: "",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: theme.primaryColor,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    )
                  : _buildQuizList(theme),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuizPage(subjects: subjects),
            ),
          );
          if (res == true) _loadData();
        },
        backgroundColor: theme.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          "NOUVEAU QUIZ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildQuizList(ThemeData theme) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 80,
                color: theme.primaryColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucun quiz créé pour le moment",
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final q = quizzes[index];
        return _buildQuizCard(q, theme);
      },
    );
  }

  Widget _buildQuizCard(dynamic quiz, ThemeData theme) {
    final int quizId = quiz['id'];
    final int? questionCount = _questionCounts[quizId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['titre'] ?? 'Sans titre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: 14,
                            color: theme.iconTheme.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quiz['matiere']?['nom'] ?? 'Matière non définie',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildQuizActions(quiz, theme),
              ],
            ),
          ),
          Container(
            height: 1,
            color: theme.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 16,
                      color: (questionCount ?? 0) > 0
                          ? theme.primaryColor
                          : theme.disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      questionCount != null
                          ? "$questionCount question(s)"
                          : "Chargement...",
                      style: TextStyle(
                        color: (questionCount ?? 0) > 0
                            ? theme.textTheme.bodyLarge?.color
                            : theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizQuestionsPage(quiz: quiz),
                    ),
                  ).then((_) => _loadData()),
                  style: TextButton.styleFrom(
                    backgroundColor: theme.primaryColor.withOpacity(0.08),
                    foregroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "Gérer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizActions(dynamic quiz, ThemeData theme) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.disabledColor,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) async {
        if (val == 'edit') {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuizPage(quiz: quiz, subjects: subjects),
            ),
          );
          if (res == true) _loadData();
        } else if (val == 'delete') {
          _deleteQuiz(quiz['id']);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 12),
              Text("Modifier"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: theme.colorScheme.error),
              SizedBox(width: 12),
              Text("Supprimer", style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}
