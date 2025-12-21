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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await api.read(
        "/professeur/quiz/${widget.quiz['id']}/questions",
      );

      List<dynamic> fetchedQuestions = res?.data ?? [];

      // Si les questions n'ont pas de réponses incluses, on les récupère une par une
      for (int i = 0; i < fetchedQuestions.length; i++) {
        final q = fetchedQuestions[i];
        if (q['reponses'] == null || (q['reponses'] as List).isEmpty) {
          try {
            final respRes = await api.read(
              "/professeur/questions/${q['id']}/reponses",
            );
            fetchedQuestions[i]['reponses'] = respRes?.data ?? [];
          } catch (e) {
            fetchedQuestions[i]['reponses'] = [];
          }
        }
      }

      if (mounted) {
        setState(() {
          questions = fetchedQuestions;
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
    List<int> deletedAnswerIds = [];

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
                                    onPressed: () => setInternalState(() {
                                      if (answers[index]['id'] != null) {
                                        deletedAnswerIds.add(
                                          answers[index]['id'],
                                        );
                                      }
                                      answers.removeAt(index);
                                    }),
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
                          if (answers.isEmpty) return;

                          setInternalState(() => isSavingLocal = true);
                          try {
                            final questionData = {
                              'question': titleController.text,
                              'type': 'qcm',
                            };

                            int? questionId;
                            if (question == null) {
                              final res = await api.create(
                                "/professeur/quiz/${widget.quiz['id']}/questions",
                                questionData,
                              );

                              // Extraction robuste de l'ID depuis la réponse du serveur
                              final resData = res?.data;
                              if (resData != null) {
                                if (resData is Map) {
                                  // Certains serveurs enveloppent dans 'data', d'autres non
                                  final actualData = resData.containsKey('data')
                                      ? resData['data']
                                      : resData;
                                  if (actualData['id'] != null) {
                                    questionId = int.tryParse(
                                      actualData['id'].toString(),
                                    );
                                  } else if (resData['id'] != null) {
                                    questionId = int.tryParse(
                                      resData['id'].toString(),
                                    );
                                  }
                                }
                              }
                            } else {
                              await api.update(
                                "/professeur/quiz/${widget.quiz['id']}/questions/${question['id']}",
                                questionData,
                              );
                              questionId = int.tryParse(
                                question['id'].toString(),
                              );
                            }

                            if (questionId == null) {
                              throw Exception(
                                "L'enregistrement de la question a réussi mais l'ID n'a pas pu être récupéré.",
                              );
                            }

                            // Gérer les suppressions de réponses si on est en mode édition
                            for (var id in deletedAnswerIds) {
                              try {
                                await api.delete("/professeur/reponses/$id");
                              } catch (e) {
                                // On continue même si la suppression échoue
                                print("Erreur suppression réponse: $e");
                              }
                            }

                            // Gérer les ajouts/modifications de réponses
                            int answerIndex = 1;
                            for (var a in answers) {
                              final String reponseText = a['controller'].text
                                  .trim();
                              if (reponseText.isEmpty) continue;

                              final reponseData = {
                                'reponse': reponseText,
                                'est_correcte': a['est_correcte']
                                    ? true
                                    : false,
                                'question_id': questionId,
                              };

                              try {
                                if (a['id'] == null) {
                                  // Nouvelle réponse
                                  await api.create(
                                    "/professeur/questions/$questionId/reponses",
                                    reponseData,
                                  );
                                } else {
                                  // Mise à jour réponse existante
                                  await api.update(
                                    "/professeur/reponses/${a['id']}",
                                    reponseData,
                                  );
                                }
                              } catch (e) {
                                print("Erreur sur l'option $answerIndex : $e");
                                // On peut choisir d'arrêter ou de continuer. Ici on lance une exception pour alerter.
                                throw Exception(
                                  "Erreur sur l'option $answerIndex : $e",
                                );
                              }
                              answerIndex++;
                            }

                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadQuestions(); // Recharger la liste
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Question et réponses enregistrées !",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text("Échec : $e"),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setInternalState(() => isSavingLocal = false);
                            }
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
        final List<dynamic> answers = q['reponses'] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              q['question'] ?? 'Question sans titre',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${answers.length} réponse(s) - ${q['type']?.toString().toUpperCase() ?? 'QCM'}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...answers.map((a) {
                      final bool isCorrect =
                          a['est_correcte'] == 1 || a['est_correcte'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.05)
                                : Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCorrect
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                size: 20,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  a['reponse'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isCorrect
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCorrect
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showQuestionForm(question: q),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Modifier"),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _deleteQuestion(q['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text("Supprimer"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
