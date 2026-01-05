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
      backgroundColor: const Color(0xFFF8F9FD),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.08),
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
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Informations du Forum",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Créez un nouvel espace de discussion.",
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
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

                            final String titre = _titreController.text.trim();
                            final String matiere = _matiereController.text
                                .trim();

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
