import 'dart:async';
import 'package:flutter/material.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/pages/students/quiz_result_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  bool isSubmitting = false;
  Map<String, dynamic>? quizDetails;
  List<dynamic> questions = [];
  Map<int, int> selectedAnswerIds = {}; // questionId -> reponseId

  int currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  late Timer _timer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.duration * 60;
    _fetchQuizData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _submitQuiz(isAuto: true);
      }
    });
  }

  Future<void> _fetchQuizData() async {
    setState(() => isLoading = true);
    try {
      // On utilise l'endpoint show qui renvoie le quiz avec questions.reponses
      final res = await api.read("/quiz/${widget.quizId}");
      if (mounted) {
        setState(() {
          quizDetails = res?.data;
          questions = quizDetails?['questions'] ?? [];
          // Mélanger les questions pour plus de professionnalisme si besoin
          // questions.shuffle();
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

  void _submitQuiz({bool isAuto = false}) async {
    if (isSubmitting) return;

    // Si ce n'est pas automatique, on demande confirmation
    if (!isAuto) {
      final confirm = await _showSubmitConfirmation();
      if (confirm != true) return;
    }

    setState(() => isSubmitting = true);
    _timer.cancel();

    int score = 0;
    final List<Map<String, dynamic>> questionResults = [];

    for (var question in questions) {
      final questionId = question['id'];
      final selectedReponseId = selectedAnswerIds[questionId];
      final reponses = question['reponses'] as List<dynamic>? ?? [];

      dynamic selectedReponse;
      dynamic correctReponse;

      for (var r in reponses) {
        if (r['id'] == selectedReponseId) selectedReponse = r;
        if (r['est_correcte'] == 1 || r['est_correcte'] == true)
          correctReponse = r;
      }

      bool isCorrect =
          selectedReponse != null &&
          (selectedReponse['est_correcte'] == 1 ||
              selectedReponse['est_correcte'] == true);

      if (isCorrect) score++;

      questionResults.add({
        'question': question['question'] ?? 'Sans texte',
        'userAnswer': selectedReponse?['reponse'] ?? 'Pas de réponse',
        'correctAnswer': correctReponse?['reponse'] ?? 'Inconnue',
        'isCorrect': isCorrect,
      });
    }

    try {
      // Sauvegarder le résultat sur le backend
      // Éviter la division par zéro si questions est vide
      final finalScore = questions.isEmpty
          ? 0
          : (score / questions.length * 100).toInt();

      await api.create("/resultats", {
        'quiz_id': widget.quizId,
        'score': finalScore,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultPage(
              quizTitle: widget.quizTitle,
              totalQuestions: questions.length,
              correctAnswers: score,
              timeSpent: (widget.duration * 60) - remainingSeconds,
              questionResults: questionResults,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement: $e")),
        );
        // On affiche quand même les résultats localement même si le save a échoué
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultPage(
              quizTitle: widget.quizTitle,
              totalQuestions: questions.length,
              correctAnswers: score,
              timeSpent: (widget.duration * 60) - remainingSeconds,
              questionResults: questionResults,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<bool?> _showSubmitConfirmation() {
    final unanswered = questions.length - selectedAnswerIds.length;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Terminer le quiz ?"),
        content: Text(
          unanswered > 0
              ? "Il vous reste $unanswered question(s) sans réponse.\nVoulez-vous vraiment soumettre ?"
              : "Voulez-vous soumettre vos réponses et voir votre score ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Continuer"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Soumettre"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = questions.isEmpty
        ? 0
        : (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  _buildProgressBar(progress),
                  Expanded(
                    child: questions.isEmpty
                        ? const Center(child: Text("Aucune question trouvée"))
                        : PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: questions.length,
                            onPageChanged: (index) {
                              setState(() => currentQuestionIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return _buildQuestionCard(questions[index]);
                            },
                          ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                widget.quizTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "En cours...",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: remainingSeconds < 60
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  size: 14,
                  color: remainingSeconds < 60 ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(remainingSeconds),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remainingSeconds < 60 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.shade200,
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
      minHeight: 6,
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    final reponses = question['reponses'] as List<dynamic>? ?? [];
    final questionId = question['id'];
    final selectedId = selectedAnswerIds[questionId];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${currentQuestionIndex + 1} sur ${questions.length}",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question['question'] ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ...reponses.map((reponse) {
            bool isSelected = selectedId == reponse['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedAnswerIds[questionId] = reponse['id'];
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981).withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade200,
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
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          reponse['reponse'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF065F46)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (questions.isEmpty)
      return const SizedBox.shrink(); // Ne pas afficher si vide

    bool isLast = currentQuestionIndex == questions.length - 1;
    bool isFirst = currentQuestionIndex == 0;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirst)
            TextButton.icon(
              onPressed: () {
                if (_pageController.hasClients) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Précédent"),
            )
          else
            const SizedBox(width: 40),

          ElevatedButton(
            onPressed: isLast
                ? (isSubmitting ? null : () => _submitQuiz())
                : () {
                    if (_pageController.hasClients) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isLast ? "TERMINER" : "SUIVANT",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
