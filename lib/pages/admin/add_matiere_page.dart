import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/service/api_service.dart';

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

  bool get isEditMode => widget.matiere != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.matiere!['nom'] ?? '';
      _descriptionController.text = widget.matiere!['description'] ?? '';
      _userNameController.text = widget.matiere!['user_name'] ?? '';
    }
  }

  Future<bool> addMatiere(
    String name,
    String description,
    String username,
  ) async {
    try {
      final response = await api.create("/admin/matieres", {
        "nom": name,
        "description": description,
        "user_name": username,
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
  ) async {
    try {
      final response = await api.update("/admin/matieres/$id", {
        "nom": name,
        "description": description,
        "user_name": username,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditMode ? 'Modifier la matière' : 'Nouvelle Matière',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode
                              ? "Modifier les détails"
                              : "Informations Générales",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditMode
                              ? "Mettez à jour les informations de cette matière."
                              : "Entrez le nom et la description de la nouvelle matière.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomTextFormField(
                          label: 'Nom de la matière',
                          hint: 'Ex: Mathématiques',
                          prefixIcon: Icons.book_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Le nom est requis";
                            return null;
                          },
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Description',
                          hint: 'Brève description du cours...',
                          prefixIcon: Icons.description_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "La description est requise";
                            return null;
                          },
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Professeur',
                          hint: 'Nom du professeur assigné',
                          prefixIcon: Icons.person_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Le professeur est requis";
                            return null;
                          },
                          controller: _userNameController,
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          text: isEditMode ? 'ENREGISTRER' : 'AJOUTER MATIÈRE',
                          isLoading: isSaving,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isSaving = true);

                              final String name = _nameController.text.trim();
                              final String description = _descriptionController
                                  .text
                                  .trim();
                              final String username = _userNameController.text
                                  .trim();

                              bool success;
                              if (isEditMode) {
                                success = await updateMatiere(
                                  widget.matiere!['id'],
                                  name,
                                  description,
                                  username,
                                );
                              } else {
                                success = await addMatiere(
                                  name,
                                  description,
                                  username,
                                );
                              }

                              if (!mounted) return;
                              setState(() => isSaving = false);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditMode
                                          ? "Matière modifiée !"
                                          : "Matière ajoutée !",
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Une erreur est survenue"),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
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
}
