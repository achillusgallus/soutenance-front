import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/utils/security_utils.dart';

class AddForumPage extends StatefulWidget {
  const AddForumPage({super.key});

  @override
  State<AddForumPage> createState() => _AddForumPageState();
}

class _AddForumPageState extends State<AddForumPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _matiereController = TextEditingController();
  final api = ApiService();
  bool isSaving = false;

  Future<bool> addForum(String titre, String matiere) async {
    try {
      final response = await api.create("/admin/forums", {
        "titre": titre,
        "matiere_nom": matiere,
      });

      return response?.statusCode == 201 || response?.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _matiereController.dispose();
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
            title: 'CRÉER UN FORUM',
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
                      color: AppTheme.warningColor.withOpacity(0.08),
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
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.forum_rounded,
                              color: AppTheme.warningColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Informations du Forum",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Créez un nouvel espace de discussion.",
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
                        label: 'TITRE DU FORUM',
                        hint: 'Ex: Forum de Mathématiques',
                        prefixIcon: Icons.forum_outlined,
                        controller: _titreController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Le titre est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'NOM DE LA MATIÈRE',
                        hint: 'Ex: Analyse 1',
                        prefixIcon: Icons.book_rounded,
                        controller: _matiereController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "La matière est requise"
                            : null,
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: 'LANCER LE FORUM',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isSaving = true);

                            final String titre = SecurityUtils.sanitizeInput(
                              _titreController.text,
                            );
                            final String matiere = SecurityUtils.sanitizeInput(
                              _matiereController.text,
                            );

                            final success = await addForum(titre, matiere);

                            if (!mounted) return;
                            setState(() => isSaving = false);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Forum créé avec succès !",
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
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
                                    "Échec de la création du forum",
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
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
