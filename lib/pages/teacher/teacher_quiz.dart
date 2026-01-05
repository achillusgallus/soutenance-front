import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/pages/teacher/add_quiz_page.dart';
import 'package:togoschool/pages/teacher/quiz_questions_page.dart';
import 'package:togoschool/service/api_service.dart';

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

        // Fetch question counts after loading quizzes
        _fetchQuestionCounts();
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

  Future<void> _fetchQuestionCounts() async {
    for (var quiz in quizzes) {
      try {
        final quizId = quiz['id'];
        final response = await api.read("/professeur/quiz/$quizId/questions");
        if (response != null && mounted) {
          final List<dynamic> questions = response.data ?? [];
          setState(() {
            _questionCounts[quizId] = questions.length;
          });
        }
      } catch (e) {
        print("Erreur fetching questions for quiz ${quiz['id']}: $e");
      }
    }
  }

  Future<void> _deleteQuiz(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le Quiz"),
        content: const Text("Êtes-vous sûr ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await api.delete("/professeur/quiz/$id");
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec de la suppression: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          FormHeader(
            title: "Mes Quiz",
            onBack: Navigator.canPop(context)
                ? () => Navigator.pop(context)
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildQuizList(),
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
        label: const Text("Nouveau Quiz"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildQuizList() {
    if (quizzes.isEmpty) {
      return const Center(
        child: Text("Aucun quiz créé", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final q = quizzes[index];
        return _buildQuizCard(q);
      },
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    final int quizId = quiz['id'];
    final int? questionCount = _questionCounts[quizId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz['titre'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      quiz['matiere']?['nom'] ?? 'Matière',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddQuizPage(quiz: quiz, subjects: subjects),
                      ),
                    );
                    if (res == true) _loadData();
                  } else if (val == 'delete') {
                    _deleteQuiz(quiz['id']);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text("Modifier")),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      "Supprimer",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                questionCount != null
                    ? "$questionCount questions"
                    : "Chargement...",
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizQuestionsPage(quiz: quiz),
                  ),
                ).then((_) => _loadData()),
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text("Gérer les questions"),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
