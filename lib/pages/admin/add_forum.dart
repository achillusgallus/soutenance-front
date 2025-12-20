import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/service/api_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Créer un forum',
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
                        const Text(
                          "Informations du Forum",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Remplissez les détails pour créer un nouvel espace de discussion.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomTextFormField(
                          label: 'Titre du forum',
                          hint: 'Ex: Forum de Mathématiques',
                          prefixIcon: Icons.forum_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Le titre est requis";
                            }
                            return null;
                          },
                          controller: _titreController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Nom de la matière',
                          hint: 'Ex: Analyse 1',
                          prefixIcon: Icons.book_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "La matière est requise";
                            }
                            return null;
                          },
                          controller: _matiereController,
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          text: 'CRÉER LE FORUM',
                          isLoading: isSaving,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isSaving = true);

                              final String titre = _titreController.text.trim();
                              final String matiere = _matiereController.text
                                  .trim();

                              final success = await addForum(titre, matiere);

                              if (!mounted) return;
                              setState(() => isSaving = false);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Forum créé avec succès !"),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Échec de la création du forum",
                                    ),
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
