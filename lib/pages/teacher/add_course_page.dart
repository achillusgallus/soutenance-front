import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio_multipart;
import 'package:path/path.dart' as p;
import 'package:togoschool/core/theme/app_theme.dart';

class AddCoursePage extends StatefulWidget {
  final Map<String, dynamic>? course;
  final List<dynamic> subjects;
  final int? initialSubjectId;

  const AddCoursePage({
    super.key,
    this.course,
    required this.subjects,
    this.initialSubjectId,
  });

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();

  int? _selectedSubjectId;
  bool _isSaving = false;
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _titleController.text = widget.course!['titre'] ?? '';
      _contentController.text = widget.course!['contenu'] ?? '';
      _linkController.text = widget.course!['fichier'] ?? '';
      _selectedSubjectId = widget.course!['matiere_id'];
    } else {
      if (widget.initialSubjectId != null) {
        _selectedSubjectId = widget.initialSubjectId;
      } else if (widget.subjects.isNotEmpty) {
        _selectedSubjectId = widget.subjects[0]['id'];
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (widget.course != null) {
      await _updateCourse();
    } else {
      await _createCourse();
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'wmv', 'webm'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _linkController.text = _pickedFile!.name;
      });
    }
  }

  Future<void> _createCourse() async {
    try {
      setState(() => _isSaving = true);

      final selectedSubject = widget.subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
        orElse: () => null,
      );

      final String safeTitle = SecurityUtils.sanitizeInput(
        _titleController.text,
      );
      final String safeContent = SecurityUtils.sanitizeInput(
        _contentController.text,
      );

      final Map<String, dynamic> dataMap = {
        'titre': safeTitle,
        'contenu': safeContent,
        'matiere_nom': selectedSubject?['nom'],
        'matiere_id': _selectedSubjectId,
      };

      final formData = dio_multipart.FormData.fromMap(dataMap);

      if (_pickedFile != null) {
        if (kIsWeb) {
          if (_pickedFile!.bytes != null) {
            formData.files.add(
              MapEntry(
                'fichier',
                dio_multipart.MultipartFile.fromBytes(
                  _pickedFile!.bytes!,
                  filename: _pickedFile!.name,
                ),
              ),
            );
          }
        } else if (_pickedFile!.path != null) {
          formData.files.add(
            MapEntry(
              'fichier',
              await dio_multipart.MultipartFile.fromFile(
                _pickedFile!.path!,
                filename: _pickedFile!.name,
              ),
            ),
          );
        }
      }

      await api.create("/professeur/cours", formData);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Une erreur est survenue: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCourse() async {
    try {
      setState(() => _isSaving = true);

      final selectedSubject = widget.subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
        orElse: () => null,
      );

      final String safeTitle = SecurityUtils.sanitizeInput(
        _titleController.text,
      );
      final String safeContent = SecurityUtils.sanitizeInput(
        _contentController.text,
      );

      final Map<String, dynamic> dataMap = {
        'titre': safeTitle,
        'contenu': safeContent,
        'matiere_nom': selectedSubject?['nom'],
        'matiere_id': _selectedSubjectId,
        '_method': 'PUT',
      };

      final formData = dio_multipart.FormData.fromMap(dataMap);

      if (_pickedFile != null) {
        if (kIsWeb) {
          if (_pickedFile!.bytes != null) {
            formData.files.add(
              MapEntry(
                'fichier',
                dio_multipart.MultipartFile.fromBytes(
                  _pickedFile!.bytes!,
                  filename: _pickedFile!.name,
                ),
              ),
            );
          }
        } else if (_pickedFile!.path != null) {
          formData.files.add(
            MapEntry(
              'fichier',
              await dio_multipart.MultipartFile.fromFile(
                _pickedFile!.path!,
                filename: _pickedFile!.name,
              ),
            ),
          );
        }
      }

      await api.create("/professeur/cours/${widget.course!['id']}", formData);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Une erreur est survenue: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          FormHeader(
            title: widget.course == null
                ? 'Nouveau Cours'
                : 'Modifier le Cours',
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
                      color: AppTheme.primaryColor.withOpacity(0.06),
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
                      _buildSectionTitle("Informations Générales"),
                      const SizedBox(height: 24),
                      _buildLabel("Matière associée"),
                      _buildSubjectDropdown(),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'Titre du cours',
                        hint: 'Ex: Introduction à l\'Algèbre',
                        prefixIcon: Icons.title_rounded,
                        controller: _titleController,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'Description / Contenu',
                        hint: 'Décrivez brièvement le contenu du cours...',
                        prefixIcon: Icons.description_outlined,
                        controller: _contentController,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Ressources Pédagogiques"),
                      const SizedBox(height: 8),
                      _buildLabel("Fichier du cours (PDF, Vidéo...)"),
                      const SizedBox(height: 8),
                      _buildFilePicker(),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: widget.course == null
                            ? 'CRÉER LE COURS'
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

  Widget _buildFilePicker() {
    bool hasFile = _pickedFile != null || widget.course?['fichier'] != null;
    String fileName =
        _pickedFile?.name ??
        (widget.course?['fichier'] != null
            ? p.basename(widget.course!['fichier'])
            : "Choisir un fichier");

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasFile
              ? const Color(0xFF6366F1).withOpacity(0.03)
              : const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFile
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFF6366F1).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!hasFile)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                _pickedFile == null
                    ? Icons.cloud_upload_outlined
                    : Icons.check_circle_rounded,
                color: hasFile
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF94A3B8),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: hasFile
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!hasFile)
                    const Text(
                      "PDF, MP4, MOV...",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                ],
              ),
            ),
            if (hasFile)
              Icon(
                Icons.edit_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
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
