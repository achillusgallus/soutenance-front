import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/pages/students/quiz_result_page.dart';

class QuizTakingPage extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  final int duration; // en minutes

  const QuizTakingPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.duration,
  });

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> questions = [];
  Map<int, dynamic> answers = {}; // questionId -> selected answer
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.duration * 60;
    _fetchQuestions();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
        return true;
      } else {
        _submitQuiz(); // Auto-submit when time runs out
        return false;
      }
    });
  }

  Future<void> _fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read("/quiz/${widget.quizId}/questions");
      if (mounted) {
        setState(() {
          questions = res?.data ?? [];
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _submitQuiz() {
    // Pour l'instant, on simule les résultats
    // TODO: Envoyer les réponses à l'API et récupérer les vrais résultats

    final timeTaken = (widget.duration * 60) - remainingSeconds;

    // Simuler les résultats des questions
    final List<Map<String, dynamic>> questionResults = [];
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionId = question['id'];
      final userAnswer = answers[questionId];

      questionResults.add({
        'question': question['texte'] ?? 'Question sans texte',
        'userAnswer': userAnswer?.toString() ?? 'Pas de réponse',
        'correctAnswer': question['bonne_reponse'] ?? 'N/A',
        'isCorrect': userAnswer == question['bonne_reponse'],
      });
    }

    final correctCount = questionResults
        .where((r) => r['isCorrect'] == true)
        .length;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultPage(
          quizTitle: widget.quizTitle,
          totalQuestions: questions.length,
          correctAnswers: correctCount,
          timeSpent: timeTaken,
          questionResults: questionResults,
        ),
      ),
    );
  }

  void _confirmSubmit() {
    final unanswered = questions.length - answers.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Soumettre le quiz ?"),
        content: Text(
          unanswered > 0
              ? "Vous n'avez pas répondu à $unanswered question(s).\n\nVoulez-vous vraiment soumettre ?"
              : "Voulez-vous soumettre vos réponses ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Soumettre"),
          ),
        ],
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
              color1: const Color(0xFF10B981),
              color2: const Color(0xFF059669),
              title: widget.quizTitle,
              subtitle: 'Temps restant: ${_formatTime(remainingSeconds)}',
              title1: "${answers.length}/${questions.length}",
              subtitle1: "Réponses",
              title2: "",
              subtitle2: "",
              title3: "",
              subtitle3: "",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : questions.isEmpty
                  ? _buildEmptyState()
                  : _buildQuestionsList(),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question, index);
      },
    );
  }

  Widget _buildQuestionCard(dynamic question, int index) {
    final questionId = question['id'];
    final selectedAnswer = answers[questionId];

    // Parse les choix de réponses (supposé être un JSON array de strings)
    List<dynamic> choices = [];
    try {
      if (question['choix_reponses'] is List) {
        choices = question['choix_reponses'];
      } else if (question['choix_reponses'] is String) {
        // Si c'est une string JSON, essayer de la parser
        choices =
            []; // Pour l'instant on laisse vide si c'est pas déjà une liste
      }
    } catch (e) {
      choices = [];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Question ${index + 1}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (selectedAnswer != null)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question['texte'] ?? 'Question sans texte',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...choices.asMap().entries.map((entry) {
              final choiceIndex = entry.key;
              final choice = entry.value;
              final isSelected = selectedAnswer == choice;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    answers[questionId] = choice;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.green : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.green : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: answers.isEmpty ? null : _confirmSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
              "SOUMETTRE LE QUIZ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Aucune question disponible pour ce quiz",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
