import 'package:flutter/material.dart';
import 'package:togoschool/services/service_flashcard.dart';
import 'package:togoschool/services/service_api.dart'; // Pour charger les matières
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ManageLearningContent extends StatefulWidget {
  const ManageLearningContent({super.key});

  @override
  State<ManageLearningContent> createState() => _ManageLearningContentState();
}

class _ManageLearningContentState extends State<ManageLearningContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contenu Pédagogique"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Flashcards", icon: Icon(FontAwesomeIcons.layerGroup)),
            Tab(
              text: "Questions & Réponses",
              icon: Icon(FontAwesomeIcons.question),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [FlashcardFormPage(), QuestionsAdminPage()],
      ),
    );
  }
}

class FlashcardFormPage extends StatefulWidget {
  const FlashcardFormPage({super.key});

  @override
  State<FlashcardFormPage> createState() => _FlashcardFormPageState();
}

class _FlashcardFormPageState extends State<FlashcardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FlashcardService _flashcardService = FlashcardService();
  final ApiService _api = ApiService();

  late TextEditingController _questionController;
  late TextEditingController _answerController;
  int? _selectedCourseId;
  List<dynamic> _courses = [];
  bool _isLoadingCourses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _answerController = TextEditingController();
    _loadCourses();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final response = await _api.read(
        '/student/matieres',
      ); // Ou endpoint admin
      if (mounted && response?.data != null) {
        final data = response!.data;
        if (data is List) {
          setState(() {
            _courses = data;
            _isLoadingCourses = false;
          });
        } else if (data is Map && data['data'] is List) {
          setState(() {
            _courses = data['data'];
            _isLoadingCourses = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCourses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une matière")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await _flashcardService.createFlashcard(
        _selectedCourseId!,
        _questionController.text,
        _answerController.text,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Flashcard créée avec succès"),
              backgroundColor: Colors.green,
            ),
          );
          _questionController.clear();
          _answerController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erreur lors de la création"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Créer une nouvelle Flashcard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: "Matière",
                border: OutlineInputBorder(),
                prefixIcon: Icon(FontAwesomeIcons.book),
              ),
              items: _courses.map<DropdownMenuItem<int>>((course) {
                return DropdownMenuItem<int>(
                  value: course['id'] as int,
                  child: Text(course['nom'] ?? course['titre'] ?? 'Matière'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCourseId = val),
              validator: (v) => v == null ? "Requis" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
                prefixIcon: Icon(FontAwesomeIcons.questionCircle),
              ),
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? "Requis" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: "Réponse",
                border: OutlineInputBorder(),
                prefixIcon: Icon(FontAwesomeIcons.lightbulb),
              ),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? "Requis" : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFlashcard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text("ENREGISTRER LA FLASHCARD"),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionsAdminPage extends StatefulWidget {
  const QuestionsAdminPage({super.key});

  @override
  State<QuestionsAdminPage> createState() => _QuestionsAdminPageState();
}

class _QuestionsAdminPageState extends State<QuestionsAdminPage> {
  final ApiService _api = ApiService();
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
      final response = await _api.read('/admin/questions');
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

  Future<void> _replyToQuestion(int id, String content) async {
    try {
      final response = await _api.create('/admin/questions/$id/reply', {
        'content': content,
      });
      if (response?.statusCode == 201) {
        _loadQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réponse envoyée'),
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

  void _showReplyDialog(Map<String, dynamic> question) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réponse à ${question['student_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Question: ${question['content']}",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Votre réponse',
                  border: OutlineInputBorder(),
                  hintText: 'Saisissez votre réponse ici...',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _replyToQuestion(question['id'], controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.circleQuestion, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text("Aucune question d'élève pour le moment."),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final q = _questions[index];
          final bool isResolved =
              q['is_resolved'] == 1 || q['is_resolved'] == true;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(
                isResolved
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circleQuestion,
                color: isResolved ? Colors.green : Colors.orange,
              ),
              title: Text(
                q['content'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "${q['student_name'] ?? 'Élève inconnu'} • ${q['course_name'] ?? 'Général'}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              trailing: isResolved
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.reply, color: Colors.blue),
                      onPressed: () => _showReplyDialog(q),
                      tooltip: "Répondre",
                    ),
              children: [
                if (q['responses'] != null &&
                    (q['responses'] as List).isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Réponses :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  for (var r in q['responses'])
                    ListTile(
                      leading: const Icon(FontAwesomeIcons.userTie, size: 14),
                      title: Text(r['content'] ?? ''),
                      subtitle: Text(
                        "Par ${r['user_name']}",
                        style: const TextStyle(fontSize: 10),
                      ),
                      dense: true,
                      tileColor: Colors.grey.withOpacity(0.05),
                    ),
                ],
                if (!isResolved)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showReplyDialog(q),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text("Répondre"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
