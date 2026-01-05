import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/pages/students/quiz_taking_page.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> quizzes = [];
  List<dynamic> results = [];
  double totalPoints = 0;
  bool showHistory = false; // Bascule entre quiz disponibles et historique

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([_fetchQuizzes(), _fetchResults()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchQuizzes() async {
    try {
      final res = await api.read("/quiz");
      if (mounted) {
        setState(() {
          quizzes = res?.data ?? [];
        });
      }
    } catch (e) {
      debugPrint("Erreur quiz: $e");
    }
  }

  Future<void> _fetchResults() async {
    try {
      final res = await api.read("/resultats");
      if (mounted) {
        setState(() {
          results = res?.data ?? [];
          // Calcul du score total
          totalPoints = 0;
          for (var r in results) {
            totalPoints += double.tryParse(r['score'].toString()) ?? 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur resultats: $e");
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
              color1: const Color(0xFF10B981),
              color2: const Color(0xFF059669),
              title: "Quiz & Évaluations",
              subtitle: 'Suivez vos progrès',
              title1: "${results.length}",
              subtitle1: "Quiz faits",
              title2: "${totalPoints.toInt()}",
              subtitle2: "Points",
              title3: "${quizzes.length}",
              subtitle3: "Disponibles",
            ),
            const SizedBox(height: 20),
            _buildTabToggle(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : showHistory
                    ? _buildResultsList()
                    : _buildQuizzesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton("Disponibles", !showHistory)),
          Expanded(child: _toggleButton("Mon Historique", showHistory)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => showHistory = label == "Mon Historique"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizzesList() {
    if (quizzes.isEmpty) return _buildEmptyState("Aucun quiz disponible");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quizzes.length,
      itemBuilder: (context, index) => _buildQuizCard(quizzes[index]),
    );
  }

  Widget _buildResultsList() {
    if (results.isEmpty)
      return _buildEmptyState("Vous n'avez pas encore de résultats");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultCard(results[index]),
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.quiz_outlined, color: Colors.green),
        ),
        title: Text(
          quiz['titre'] ?? 'Quiz sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Matière: ${quiz['matiere']['nom'] ?? 'N/A'}"),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${quiz['duree'] ?? '0'} min",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startQuiz(quiz),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("FAIRE"),
        ),
      ),
    );
  }

  Widget _buildResultCard(dynamic result) {
    final quiz = result['quiz'] ?? {};
    final score = double.tryParse(result['score'].toString()) ?? 0;
    final date = result['date_passage'] != null
        ? DateTime.parse(result['date_passage'].toString())
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: score >= 50
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${score.toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: score >= 50 ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['titre'] ?? 'Quiz fait',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Fait le : ${date.day}/${date.month}/${date.year}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              score >= 50 ? Icons.check_circle : Icons.error_outline,
              color: score >= 50 ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz(dynamic quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingPage(
          quizId: quiz['id'],
          quizTitle: quiz['titre'] ?? 'Quiz',
          duration: quiz['duree'] ?? 30,
        ),
      ),
    ).then((_) => _loadData()); // Refresh data after quiz
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
