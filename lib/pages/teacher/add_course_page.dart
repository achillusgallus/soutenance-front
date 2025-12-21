import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio_multipart;
import 'package:path/path.dart' as p;

class AddCoursePage extends StatefulWidget {
  final Map<String, dynamic>? course;
  final List<dynamic> subjects;

  const AddCoursePage({super.key, this.course, required this.subjects});

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
      // On ne peut pas facilement restaurer un fichier local depuis un lien URL
      _linkController.text = widget.course!['fichier'] ?? '';
      _selectedSubjectId = widget.course!['matiere_id'];
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubjectId = widget.subjects[0]['id'];
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

      final Map<String, dynamic> dataMap = {
        'titre': _titleController.text,
        'contenu': _contentController.text,
        'matiere_nom': selectedSubject?['nom'],
        'matiere_id': _selectedSubjectId,
      };

      final formData = dio_multipart.FormData.fromMap(dataMap);

      if (_pickedFile != null && _pickedFile!.path != null) {
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

      await api.create("/professeur/cours", formData);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur est survenue: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCourse() async {
    try {
      setState(() => _isSaving = true);

      final selectedSubject = widget.subjects.firstWhere(
        (s) => s['id'] == _selectedSubjectId,
        orElse: () => null,
      );

      final Map<String, dynamic> dataMap = {
        'titre': _titleController.text,
        'contenu': _contentController.text,
        'matiere_nom': selectedSubject?['nom'],
        'matiere_id': _selectedSubjectId,
        '_method':
            'PUT', // Certains frameworks PHP (comme Laravel) exigent cela pour le multipart PUT
      };

      final formData = dio_multipart.FormData.fromMap(dataMap);

      if (_pickedFile != null && _pickedFile!.path != null) {
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

      // On utilise POST avec _method: PUT car multipart/form-data via PUT est souvent problématique sur les serveurs
      await api.create("/professeur/cours/${widget.course!['id']}", formData);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur est survenue: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: widget.course == null
                  ? 'Ajouter un cours'
                  : 'Modifier le cours',
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Détails du cours",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSubjectDropdown(),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Titre du cours',
                          hint: 'Ex: Introduction à l\'Algèbre',
                          prefixIcon: Icons.title,
                          controller: _titleController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Description / Contenu',
                          hint: 'Décrivez brièvement le cours...',
                          prefixIcon: Icons.description_outlined,
                          controller: _contentController,
                          // MaxLines could be added to CustomTextFormField if supported
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Document ou Vidéo du cours",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickFile,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickedFile == null
                                      ? Icons.upload_file
                                      : Icons.check_circle,
                                  color: _pickedFile == null
                                      ? Colors.grey
                                      : Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _pickedFile?.name ??
                                        (widget.course?['fichier'] != null
                                            ? p.basename(
                                                widget.course!['fichier'],
                                              )
                                            : "Choisir un fichier (PDF, MP4...)"),
                                    style: TextStyle(
                                      color:
                                          _pickedFile == null &&
                                              widget.course?['fichier'] == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_pickedFile != null)
                                  const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                              ],
                            ),
                          ),
                        ),
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
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sélectionner la matière",
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
