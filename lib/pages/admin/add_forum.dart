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

  Future<bool> addForum(String titre, String matiere) async {
    try {
      final response = await api.create("/admin/forums", {
        "titre": titre,
        "matiere_nom": matiere,
      });

      // Accept 200 or 201 as success depending on backend behavior
      if (response?.statusCode == 201 || response?.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Erreur: $e");
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
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: ListView(
          children: [
            FormHeader(
              title: 'Créer un forum',
              onBack: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 150),
            Container(
              margin: EdgeInsets.all(30),
              padding: EdgeInsets.all(30),
              width: double.infinity,
              // height: size.height * 0.68,
              decoration: BoxDecoration(
                color: (Colors.white),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                      label: 'Titre du forum',
                      hint: 'entrer le titre du forum',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _titreController,
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'Nom de la matière',
                      hint: 'entrer le nom de la matière',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _matiereController,
                    ),
                    SizedBox(height: 16),
                    PrimaryButton(
                      text: 'créer forum',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final String titre = _titreController.text.trim();
                          final String matiere = _matiereController.text.trim();
                          // Appel API login
                          final success = await addForum(titre, matiere);
                          if (success == true) {
                            final snack = ScaffoldMessenger.of(context)
                                .showSnackBar(
                                  SnackBar(
                                    content: Text("Forum créé avec succès !"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                            // Wait until the SnackBar is dismissed before navigating
                            await snack.closed;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminDashboardPage(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Échec de la création du forum"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
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
          ],
        ),
      ),
    );
  }
}
