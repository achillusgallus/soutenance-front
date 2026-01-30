import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/pages/students/quiz_taking_page.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  final api = ApiService();
  final ScrollController _scrollController = ScrollController();

  // State for Quizzes
  bool isLoadingQuizzes = true;
  bool isLoadingMoreQuizzes = false;
  int currentQuizPage = 1;
  int lastQuizPage = 1;
  List<dynamic> quizzes = [];

  // State for Results
  bool isLoadingResults = false;
  List<dynamic> results = [];
  double totalPoints = 0;

  bool showHistory = false; // Bascule entre quiz disponibles et historique

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
    _fetchResults();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!showHistory &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMoreQuizzes &&
        !isLoadingQuizzes &&
        currentQuizPage < lastQuizPage) {
      _loadMoreQuizzes();
    }
  }

  Future<void> _loadMoreQuizzes() async {
    if (mounted) {
      setState(() {
        isLoadingMoreQuizzes = true;
        currentQuizPage++;
      });
      await _fetchQuizzes();
    }
  }

  Future<void> _fetchQuizzes() async {
    if (quizzes.isEmpty) {
      setState(() => isLoadingQuizzes = true);
    }

    try {
      final res = await api.read("/quiz?page=$currentQuizPage");
      if (mounted) {
        final data = res?.data;
        List<dynamic> fetchedQuizzes = [];

        if (data is Map && data.containsKey('data')) {
          fetchedQuizzes = data['data'];
          lastQuizPage = data['last_page'] ?? 1;
        } else if (data is List) {
          fetchedQuizzes = data;
        }

        List<dynamic> newQuizzesList;
        if (currentQuizPage == 1) {
          newQuizzesList = fetchedQuizzes;
        } else {
          newQuizzesList = [...quizzes, ...fetchedQuizzes];
        }

        setState(() {
          quizzes = newQuizzesList;
          isLoadingQuizzes = false;
          isLoadingMoreQuizzes = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur quiz: $e");
      if (mounted) {
        setState(() {
          isLoadingQuizzes = false;
          isLoadingMoreQuizzes = false;
        });
      }
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
              subtitle: 'Suivez vos progrès scolaires',
              title1: "${results.length}",
              subtitle1: "Complétés",
              title2: "${totalPoints.toInt()}",
              subtitle2: "Score Total",
              title3: "${quizzes.length}",
              subtitle3: "Disponibles",
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
            _buildTabToggle(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (showHistory) {
                    await _fetchResults();
                  } else {
                    setState(() {
                      currentQuizPage = 1;
                      quizzes = [];
                    });
                    await _fetchQuizzes();
                  }
                },
                color: const Color(0xFF10B981),
                child: showHistory
                    ? (isLoadingResults
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                              ),
                            )
                          : _buildResultsList())
                    : (isLoadingQuizzes
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF10B981),
                              ),
                            )
                          : _buildQuizzesList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton("Disponibles", !showHistory)),
          const SizedBox(width: 4),
          Expanded(child: _toggleButton("Historique", showHistory)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => showHistory = label == "Historique"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizzesList() {
    if (quizzes.isEmpty && !isLoadingQuizzes)
      return _buildEmptyState("Aucun quiz disponible pour le moment.");
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: quizzes.length + (isLoadingMoreQuizzes ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == quizzes.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }
        return _buildQuizCard(quizzes[index]);
      },
    );
  }

  Widget _buildResultsList() {
    if (results.isEmpty)
      return _buildEmptyState("Vous n'avez pas encore passé de quiz.");
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultCard(results[index]),
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startQuiz(quiz),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['titre'] ?? 'Quiz sans titre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Matière: ${quiz['matiere']['nom'] ?? 'N/A'}",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${quiz['duree'] ?? '0'} min",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ],
            ),
          ),
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

    final bool isSuccess = score >= 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    (isSuccess
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${score.toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['titre'] ?? 'Examen',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Le ${date.day}/${date.month}/${date.year}",
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              size: 24,
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
    ).then((_) {
      // Refresh lists after quiz
      _fetchResults();
      // Optionally refresh quiz list if needed, but usually not needed unless status changed
    });
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 60,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
