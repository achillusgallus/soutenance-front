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
    final percentage = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).toInt();
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
              title: "Résultats du Quiz",
              subtitle: isPassed
                  ? 'Excellent travail !'
                  : 'Continuez vos efforts',
              title1: "$correctAnswers/$totalQuestions",
              subtitle1: "Correctes",
              title2: "$percentage%",
              subtitle2: "Votre Score",
              title3: _formatTime(timeSpent),
              subtitle3: "Durée",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceSummary(percentage, isPassed),
                    const SizedBox(height: 32),
                    const Text(
                      "RÉVISION DÉTAILLÉE",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...questionResults.asMap().entries.map((entry) {
                      return _buildQuestionResultCard(entry.key, entry.value);
                    }).toList(),
                  ],
                ),
              ),
            ),
            _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(int percentage, bool isPassed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPassed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$percentage%",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isPassed
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  Text(
                    isPassed ? "RÉUSSI" : "ÉCHOUÉ",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric(
                Icons.check_circle_rounded,
                "$correctAnswers",
                "Vraies",
                const Color(0xFF10B981),
              ),
              _buildStatMetric(
                Icons.cancel_rounded,
                "${totalQuestions - correctAnswers}",
                "Fausses",
                const Color(0xFFEF4444),
              ),
              _buildStatMetric(
                Icons.timer_rounded,
                "${timeSpent ~/ 60}m",
                "Temps",
                const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildQuestionResultCard(int index, Map<String, dynamic> result) {
    final bool isCorrect = result['isCorrect'] ?? false;
    final String question = result['question'] ?? '';
    final String userAnswer = result['userAnswer'] ?? 'Aucune réponse';
    final String correctAnswer = result['correctAnswer'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (isCorrect
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Question ${index + 1}",
                  style: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildReviewRow("Votre réponse", userAnswer, isCorrect),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            _buildReviewRow("Réponse correcte", correctAnswer, true),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, bool isSuccess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 14,
            color: isSuccess
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSuccess
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
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
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "QUITTER",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "RETOURNER",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m}m ${s}s";
  }
}
