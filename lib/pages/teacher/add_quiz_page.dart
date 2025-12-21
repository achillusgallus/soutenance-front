import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/service/api_service.dart';

class AddQuizPage extends StatefulWidget {
  final Map<String, dynamic>? quiz;
  final List<dynamic> subjects;

  const AddQuizPage({super.key, this.quiz, required this.subjects});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final api = ApiService();

  int? _selectedSubjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!['titre'] ?? '';
      _selectedSubjectId = widget.quiz!['matiere_id'];
      _durationController.text = widget.quiz!['duree'] ?? '';
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubjectId = widget.subjects[0]['id'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedSubjectId == null)
      return;

    setState(() => _isSaving = true);
    try {
      final selectedSubject = widget.subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
        orElse: () => null,
      );

      final quizData = {
        'titre': _titleController.text,
        'matiere_id': _selectedSubjectId,
        'matiere_nom': selectedSubject?['nom'],
        'duree': int.tryParse(_durationController.text) ?? 30,
      };
      if (widget.quiz != null) {
        await api.update("/professeur/quiz/${widget.quiz!['id']}", quizData);
      } else {
        await api.create("/professeur/quiz", quizData);
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de sauvegarde: $e")));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: widget.quiz == null ? 'Créer un Quiz' : 'Modifier le Quiz',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSubjectDropdown(),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Titre du Quiz',
                          hint: 'Ex: Contrôle de fin de semestre',
                          prefixIcon: Icons.quiz_outlined,
                          controller: _titleController,
                        ),
                        const SizedBox(height: 40),
                        CustomTextFormField(
                          label: 'durée du Quiz (minutes)',
                          hint: 'Ex: 60',
                          prefixIcon: Icons.timer_outlined,
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          text: widget.quiz == null ? 'CRÉER' : 'MODIFIER',
                          isLoading: _isSaving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Matière concernée",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSubjectId,
              isExpanded: true,
              items: widget.subjects.map((s) {
                return DropdownMenuItem<int>(
                  value: s['id'],
                  child: Text(s['nom'] ?? 'Sans nom'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSubjectId = val),
            ),
          ),
        ),
      ],
    );
  }
}
