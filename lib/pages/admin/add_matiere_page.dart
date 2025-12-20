import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/service/api_service.dart';

class AddMatierePage extends StatefulWidget {
  const AddMatierePage({super.key});

  @override
  State<AddMatierePage> createState() => _AddMatierePageState();
}

class _AddMatierePageState extends State<AddMatierePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final api = ApiService();

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
    _nameController.dispose();
    _descriptionController.dispose();
    _userNameController.dispose();
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
              title: 'Ajouter une nouvelle matière',
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
                      label: 'Nom de la matière',
                      hint: 'entrer le nom de la matière',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _nameController,
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'Descriptionde la matière',
                      hint: 'entrer la description de la matière',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _descriptionController,
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'professeur de la matière',
                      hint: 'entrer le professeur de la matière',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _userNameController,
                    ),
                    SizedBox(height: 24),
                    PrimaryButton(
                      text: 'ajouter matière',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final String name = _nameController.text.trim();
                          final String description = _descriptionController.text
                              .trim();
                          final String username = _userNameController.text
                              .trim();
                          // Appel API login
                          final success = await addMatiere(
                            name,
                            description,
                            username,
                          );
                          if (success == true) {
                            final snack = ScaffoldMessenger.of(context)
                                .showSnackBar(
                                  SnackBar(
                                    content: Text("matière ajoutée !"),
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
                                content: Text("Échec de l'ajout de la matière"),
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
