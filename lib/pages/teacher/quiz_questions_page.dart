import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/service/api_service.dart';

class QuizQuestionsPage extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizQuestionsPage({super.key, required this.quiz});

  @override
  State<QuizQuestionsPage> createState() => _QuizQuestionsPageState();
}

class _QuizQuestionsPageState extends State<QuizQuestionsPage> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read(
        "/professeur/quiz/${widget.quiz['id']}/questions",
      );
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
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la Question"),
        content: const Text("Êtes-vous sûr ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await api.delete("/professeur/quiz/${widget.quiz['id']}/questions/$id");
        _loadQuestions();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  void _showQuestionForm({Map<String, dynamic>? question}) {
    final titleController = TextEditingController(
      text: question?['question'] ?? '',
    );

    // Initialiser les réponses existantes ou une liste vide
    List<Map<String, dynamic>> answers = [];
    if (question != null && question['reponses'] != null) {
      answers = List<Map<String, dynamic>>.from(
        question['reponses'].map(
          (r) => {
            'id': r['id'],
            'controller': TextEditingController(text: r['reponse']),
            'est_correcte': r['est_correcte'] == 1 || r['est_correcte'] == true,
          },
        ),
      );
    } else {
      // Commencer avec 2 options par défaut
      answers = [
        {'controller': TextEditingController(), 'est_correcte': true},
        {'controller': TextEditingController(), 'est_correcte': false},
      ];
    }

    bool isSavingLocal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInternalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question == null
                            ? "Nouvelle Question"
                            : "Modifier la Question",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        label: "Énoncé de la question",
                        hint: "Ex: Quel est le plus grand pays du monde ?",
                        controller: titleController,
                        prefixIcon: Icons.help_outline,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Réponses possibles",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setInternalState(
                              () => answers.add({
                                'controller': TextEditingController(),
                                'est_correcte': false,
                              }),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text("Ajouter"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(answers.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: answers[index]['controller'],
                                      decoration: InputDecoration(
                                        hintText: "Option ${index + 1}",
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => setInternalState(
                                      () => answers.removeAt(index),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Text("Bonne réponse ?"),
                                  const Spacer(),
                                  Switch(
                                    value: answers[index]['est_correcte'],
                                    activeColor: Colors.blueAccent,
                                    onChanged: (val) => setInternalState(
                                      () =>
                                          answers[index]['est_correcte'] = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: "ENREGISTRER LA QUESTION",
                        isLoading: isSavingLocal,
                        onPressed: () async {
                          if (titleController.text.isEmpty) return;

                          setInternalState(() => isSavingLocal = true);
                          try {
                            final data = {
                              'question': titleController.text,
                              'type': 'qcm',
                              'reponses': answers
                                  .map(
                                    (a) => {
                                      'reponse': a['controller'].text,
                                      'est_correcte': a['est_correcte'],
                                    },
                                  )
                                  .toList(),
                            };

                            if (question == null) {
                              await api.create(
                                "/professeur/quiz/${widget.quiz['id']}/questions",
                                data,
                              );
                            } else {
                              await api.update(
                                "/professeur/quiz/${widget.quiz['id']}/questions/${question['id']}",
                                data,
                              );
                            }
                            Navigator.pop(ctx);
                            _loadQuestions();
                          } catch (e) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text("Erreur: $e")),
                            );
                          } finally {
                            setInternalState(() => isSavingLocal = false);
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: "Questions: ${widget.quiz['titre']}",
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadQuestions,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildQuestionsList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuestionForm(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (questions.isEmpty) {
      return const Center(
        child: Text(
          "Aucune question dans ce quiz",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['question'] ?? 'Question sans titre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      q['type']?.toString().toUpperCase() ?? 'QCM',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showQuestionForm(question: q),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteQuestion(q['id']),
              ),
            ],
          ),
        );
      },
    );
  }
}
