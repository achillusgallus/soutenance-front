import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class AddMatierePage extends StatefulWidget {
  final Map<String, dynamic>? matiere;
  const AddMatierePage({super.key, this.matiere});

  @override
  State<AddMatierePage> createState() => _AddMatierePageState();
}

class _AddMatierePageState extends State<AddMatierePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final api = ApiService();
  bool isSaving = false;

  final List<String> classes = [
    'tle_D',
    'tle_A4',
    'tle_C',
    'pre_D',
    'pre_A4',
    'pre_C',
    'troisieme',
  ];
  String? _selectedClasse;

  bool get isEditMode => widget.matiere != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.matiere!['nom'] ?? '';
      _descriptionController.text = widget.matiere!['description'] ?? '';
      _userNameController.text = widget.matiere!['user_name'] ?? '';
      _selectedClasse = widget.matiere!['classe'];
    }
  }

  Future<bool> addMatiere(
    String name,
    String description,
    String username,
    String classe,
  ) async {
    try {
      final response = await api.create("/admin/matieres", {
        "nom": name,
        "description": description,
        "user_name": username,
        "classe": classe,
      });
      return response?.statusCode == 201 || response?.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMatiere(
    int id,
    String name,
    String description,
    String username,
    String classe,
  ) async {
    try {
      final response = await api.update("/admin/matieres/$id", {
        "nom": name,
        "description": description,
        "user_name": username,
        "classe": classe,
      });
      return response?.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          FormHeader(
            title: isEditMode ? 'MODIFIER LA MATIÈRE' : 'NOUVELLE MATIÈRE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditMode
                                      ? "Édition des détails"
                                      : "Informations Générales",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Configurez les paramètres de cette matière.",
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      CustomTextFormField(
                        label: 'NOM DE LA MATIÈRE',
                        hint: 'Ex: Mathématiques',
                        prefixIcon: Icons.book_rounded,
                        controller: _nameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Le nom est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'DESCRIPTION',
                        hint: 'Brève description du cours...',
                        prefixIcon: Icons.description_rounded,
                        controller: _descriptionController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "La description est requise"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'PROFESSEUR REPLACÉ (NOM COMPLET)',
                        hint: 'Nom de l\'enseignant responsable',
                        prefixIcon: Icons.person_rounded,
                        controller: _userNameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "L'enseignant est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CLASSE ASSIGNÉE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedClasse,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.school_rounded,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            dropdownColor: theme.cardColor,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            items: classes.map((String c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c.replaceAll('_', ' ').toUpperCase(),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) =>
                                setState(() => _selectedClasse = value),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? "La classe est requise"
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: isEditMode
                            ? 'METTRE À JOUR LA MATIÈRE'
                            : 'CRÉER LA MATIÈRE',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isSaving = true);

                            final String name = SecurityUtils.sanitizeInput(
                              _nameController.text,
                            );
                            final String description =
                                SecurityUtils.sanitizeInput(
                                  _descriptionController.text,
                                );
                            final String username = SecurityUtils.sanitizeInput(
                              _userNameController.text,
                            );

                            bool success;
                            if (isEditMode) {
                              success = await updateMatiere(
                                widget.matiere!['id'],
                                name,
                                description,
                                username,
                                _selectedClasse!,
                              );
                            } else {
                              success = await addMatiere(
                                name,
                                description,
                                username,
                                _selectedClasse!,
                              );
                            }

                            if (!mounted) return;
                            setState(() => isSaving = false);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditMode
                                        ? "Matière mise à jour avec succès !"
                                        : "Nouvelle matière créée avec succès !",
                                  ),
                                  backgroundColor: AppTheme.successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Une erreur est survenue lors de l'enregistrement",
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (isEditMode) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "ANNULER",
                              style: TextStyle(
                                color: theme.disabledColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
