import 'package:flutter/material.dart';
import 'package:togoschool/services/service_api.dart';

class StudentQuestionsPage extends StatefulWidget {
  final int? courseId;
  final String? courseName;

  const StudentQuestionsPage({super.key, this.courseId, this.courseName});

  @override
  State<StudentQuestionsPage> createState() => _StudentQuestionsPageState();
}

class _StudentQuestionsPageState extends State<StudentQuestionsPage> {
  final ApiService _api = ApiService();
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.read(
        '/student/questions${widget.courseId != null ? '?course_id=${widget.courseId}' : ''}',
      );
      if (mounted) {
        setState(() {
          _questions = response?.data is List ? response!.data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    try {
      final response = await _api.create('/student/questions', {
        'course_id': widget.courseId ?? 1,
        'content': _questionController.text.trim(),
      });

      if (response?.statusCode == 201 || response?.statusCode == 200) {
        _questionController.clear();
        _loadQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question posée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Questions & Réponses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildAskSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                ? _buildEmptyState()
                : _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAskSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseName != null
                ? 'Une question sur ${widget.courseName} ?'
                : 'Posez une question à vos profs',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ecrivez votre question ici...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: const Color(0xFF10B981),
                radius: 25,
                child: IconButton(
                  onPressed: _submitQuestion,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final q = _questions[index];
        return _buildQuestionCard(q);
      },
    );
  }

  Widget _buildQuestionCard(dynamic q) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAnswered =
        q['responses'] != null && (q['responses'] as List).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          q['content'] ?? 'Question sans contenu',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(
              isAnswered ? 'Répondu' : 'En attente',
              style: TextStyle(
                fontSize: 12,
                color: isAnswered ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              q['course_name'] ?? 'Général',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: (isAnswered ? Colors.green : Colors.orange)
              .withOpacity(0.1),
          child: Icon(
            isAnswered ? Icons.check_circle : Icons.help_outline,
            color: isAnswered ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        children: [
          if (isAnswered)
            ...(q['responses'] as List)
                .map((r) => _buildResponseItem(r))
                .toList()
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Pas encore de réponse de votre professeur.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponseItem(dynamic r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                r['user_name'] ?? 'Professeur',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(r['content'] ?? '', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune question posée',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Soyez le premier à poser une question !',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
