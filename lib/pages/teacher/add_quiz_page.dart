import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/utils/security_utils.dart';

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

      final String safeTitle = SecurityUtils.sanitizeInput(
        _titleController.text,
      );

      final quizData = {
        'titre': safeTitle,
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
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          FormHeader(
            title: widget.quiz == null ? 'Nouveau Quiz' : 'Modifier le Quiz',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Configuration du Quiz"),
                      const SizedBox(height: 24),
                      _buildLabel("Matière concernée"),
                      _buildSubjectDropdown(),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'Titre du Quiz',
                        hint: 'Ex: Contrôle de fin de semestre',
                        prefixIcon: Icons.quiz_rounded,
                        controller: _titleController,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'Durée (minutes)',
                        hint: 'Ex: 60',
                        prefixIcon: Icons.timer_outlined,
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: widget.quiz == null
                            ? 'CRÉER LE QUIZ'
                            : 'METTRE À JOUR',
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSubjectId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          borderRadius: BorderRadius.circular(16),
          items: widget.subjects.map((s) {
            return DropdownMenuItem<int>(
              value: s['id'],
              child: Text(s['nom'] ?? 'Sans nom'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubjectId = val),
        ),
      ),
    );
  }
}
