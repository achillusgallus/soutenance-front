import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/utils/security_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          FormHeader(
            title: "Questions: ${widget.quiz['titre']}",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadQuestions,
              color: const Color(0xFF10B981),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    )
                  : _buildQuestionsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuestionForm(),
        backgroundColor: const Color(0xFF10B981),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                size: 80,
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Aucune question dans ce quiz",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        final List<dynamic> answers = q['reponses'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                q['question'] ?? 'Question sans titre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                "${answers.length} réponse(s) • ${q['type']?.toString().toUpperCase() ?? 'QCM'}",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              children: [
                Container(
                  height: 1,
                  color: const Color(0xFFF1F5F9),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...answers.map((a) {
                        final bool isCorrect =
                            a['est_correcte'] == 1 || a['est_correcte'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF10B981).withOpacity(0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCorrect
                                    ? const Color(0xFF10B981).withOpacity(0.2)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: isCorrect
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    a['reponse'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isCorrect
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isCorrect
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF64748B),
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
                          TextButton.icon(
                            onPressed: () => _showQuestionForm(question: q),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text("Modifier"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              backgroundColor: const Color(
                                0xFF6366F1,
                              ).withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => _deleteQuestion(q['id']),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text("Supprimer"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              backgroundColor: const Color(
                                0xFFEF4444,
                              ).withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuestionForm({Map<String, dynamic>? question}) {
    final titleController = TextEditingController(
      text: question?['question'] ?? '',
    );
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
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question == null
                            ? "Nouvelle Question"
                            : "Modifier la Question",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        "Configurez l'énoncé et les options de réponse",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextFormField(
                        label: "Énoncé de la question",
                        hint: "Ex: Quel est le plus grand pays du monde ?",
                        controller: titleController,
                        prefixIcon: Icons.help_outline_rounded,
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
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setInternalState(
                              () => answers.add({
                                'controller': TextEditingController(),
                                'est_correcte': false,
                              }),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text("Ajouter"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              backgroundColor: const Color(
                                0xFF10B981,
                              ).withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(answers.length, (index) {
                        bool correct = answers[index]['est_correcte'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: correct
                                  ? const Color(0xFF10B981).withOpacity(0.3)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    onPressed: () => setInternalState(() {
                                      if (answers[index]['id'] != null)
                                        deletedAnswerIds.add(
                                          answers[index]['id'],
                                        );
                                      answers.removeAt(index);
                                    }),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: correct
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Réponse Correcte",
                                        style: TextStyle(
                                          color: correct
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                          fontWeight: correct
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Switch.adaptive(
                                    value: correct,
                                    activeColor: const Color(0xFF10B981),
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
                          if (titleController.text.isEmpty || answers.isEmpty)
                            return;

                          setInternalState(() => isSavingLocal = true);
                          try {
                            final String safeQuestion =
                                SecurityUtils.sanitizeInput(
                                  titleController.text,
                                );
                            final questionData = {
                              'question': safeQuestion,
                              'type': 'qcm',
                            };
                            int? questionId;
                            if (question == null) {
                              final res = await api.create(
                                "/professeur/quiz/${widget.quiz['id']}/questions",
                                questionData,
                              );
                              final resData = res?.data;
                              if (resData != null) {
                                final actualData =
                                    (resData is Map &&
                                        resData.containsKey('data'))
                                    ? resData['data']
                                    : resData;
                                questionId = int.tryParse(
                                  (actualData['id'] ?? resData['id'])
                                      .toString(),
                                );
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

                            if (questionId == null)
                              throw Exception(
                                "Impossible de récupérer l'ID de la question.",
                              );

                            for (var id in deletedAnswerIds) {
                              try {
                                await api.delete("/professeur/reponses/$id");
                              } catch (_) {}
                            }

                            for (var a in answers) {
                              final String reponseText =
                                  SecurityUtils.sanitizeInput(
                                    a['controller'].text,
                                  );
                              if (reponseText.isEmpty) continue;
                              final reponseData = {
                                'reponse': reponseText,
                                'est_correcte': a['est_correcte'],
                                'question_id': questionId,
                              };
                              if (a['id'] == null) {
                                await api.create(
                                  "/professeur/questions/$questionId/reponses",
                                  reponseData,
                                );
                              } else {
                                await api.update(
                                  "/professeur/reponses/${a['id']}",
                                  reponseData,
                                );
                              }
                            }

                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadQuestions();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Question enregistrée avec succès !",
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text("Échec : $e"),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          } finally {
                            if (mounted)
                              setInternalState(() => isSavingLocal = false);
                          }
                        },
                      ),
                      const SizedBox(height: 48),
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
}
