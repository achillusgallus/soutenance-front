import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';

class QuizResultPage extends StatelessWidget {
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent; // en secondes
  final List<Map<String, dynamic>> questionResults;

  const QuizResultPage({
    super.key,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.questionResults,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    final isPassed = percentage >= 50;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: isPassed
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              color2: isPassed
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              title: quizTitle,
              subtitle: isPassed ? 'Félicitations !' : 'Continuez vos efforts',
              title1: "$correctAnswers/$totalQuestions",
              subtitle1: "Bonnes réponses",
              title2: "$percentage%",
              subtitle2: "Score",
              title3: "${_formatTime(timeSpent)}",
              subtitle3: "Temps",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildScoreCard(percentage, isPassed),
                    const SizedBox(height: 20),
                    _buildQuestionReview(),
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int percentage, bool isPassed) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$percentage%",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      isPassed ? "Réussi" : "Échoué",
                      style: TextStyle(
                        fontSize: 14,
                        color: isPassed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.check_circle_outline,
                  "$correctAnswers",
                  "Correctes",
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.cancel_outlined,
                  "${totalQuestions - correctAnswers}",
                  "Incorrectes",
                  Colors.red,
                ),
                _buildStatItem(
                  Icons.access_time,
                  _formatTime(timeSpent),
                  "Temps",
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuestionReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Révision des questions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...questionResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return _buildQuestionResultCard(index, result);
        }).toList(),
      ],
    );
  }

  Widget _buildQuestionResultCard(int index, Map<String, dynamic> result) {
    final isCorrect = result['isCorrect'] ?? false;
    final question = result['question'] ?? '';
    final userAnswer = result['userAnswer'] ?? 'Pas de réponse';
    final correctAnswer = result['correctAnswer'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    color: isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Question ${index + 1}",
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildAnswerRow("Votre réponse", userAnswer, isCorrect),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              _buildAnswerRow("Bonne réponse", correctAnswer, true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check : Icons.close,
            color: isCorrect ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // Retour à la page du quiz
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "RETOUR",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Retour à la liste des quiz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "TERMINER",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}min ${secs}s';
  }
}
