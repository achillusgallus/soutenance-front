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

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read("/quiz");
      if (mounted) {
        setState(() {
          quizzes = res?.data ?? [];
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
              color1: Color(0xFF10B981),
              color2: Color(0xFF059669),
              title: "Quiz & Évaluations",
              subtitle: 'Mettez vos connaissances à l\'épreuve',
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
                onRefresh: _fetchQuizzes,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : quizzes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = quizzes[index];
                          return _buildQuizCard(quiz);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
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
          child: const Icon(Icons.help_outline, color: Colors.green),
        ),
        title: Text(
          quiz['titre'] ?? 'Quiz sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Matière: ${quiz['matiere_nom'] ?? 'N/A'}"),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${quiz['duree'] ?? '0'} min",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.layers_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${quiz['questions_count'] ?? '0'} questions",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizTakingPage(
                  quizId: quiz['id'],
                  quizTitle: quiz['titre'] ?? 'Quiz',
                  duration: quiz['duree'] ?? 30,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("DÉMARRER"),
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
            "Aucun quiz disponible pour le moment",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
