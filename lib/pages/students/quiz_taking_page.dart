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
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildHeader(),
                  _buildProgressBar(progress),
                  Expanded(
                    child: questions.isEmpty
                        ? _buildEmptyQuestionsState()
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          Text(
            "Préparation de votre quiz...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    bool isUrgent = remainingSeconds < 60;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quizTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Question ${currentQuestionIndex + 1} sur ${questions.length}",
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isUrgent
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUrgent
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFE0E7FF),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  size: 14,
                  color: isUrgent
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(remainingSeconds),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isUrgent
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF6366F1),
                    fontFeatures: const [FontFeature.tabularFigures()],
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
    return Container(
      height: 6,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    final reponses = question['reponses'] as List<dynamic>? ?? [];
    final questionId = question['id'];
    final selectedId = selectedAnswerIds[questionId];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "ÉVALUATION",
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  question['question'] ?? 'Texte de la question manquant',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "CHOISISSEZ LA BONNE RÉPONSE",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...reponses.map((reponse) {
            bool isSelected = selectedId == reponse['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedAnswerIds[questionId] = reponse['id'];
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
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
                                ? const Color(0xFF4338CA)
                                : const Color(0xFF475569),
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
    if (questions.isEmpty) return const SizedBox.shrink();

    bool isLast = currentQuestionIndex == questions.length - 1;
    bool isFirst = currentQuestionIndex == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (_pageController.hasClients) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuart,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "PRÉCÉDENT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          if (!isFirst) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLast
                  ? (isSubmitting ? null : () => _submitQuiz())
                  : () {
                      if (_pageController.hasClients) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuart,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                      isLast ? "TERMINER LE QUIZ" : "QUESTION SUIVANTE",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "Ce quiz n'a pas encore de questions.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RETOUR"),
          ),
        ],
      ),
    );
  }
}
