import 'package:flutter/material.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';

import 'package:togoschool/service/api_service.dart';

class AddTeacherPage extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  const AddTeacherPage({super.key, this.teacher});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final api = ApiService();

  bool get isEditMode => widget.teacher != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.teacher!['name'] ?? '';
      _surnameController.text = widget.teacher!['surname'] ?? '';
      _emailController.text = widget.teacher!['email'] ?? '';
      // Password is usually not pre-filled for security, or handled differently.
      // Leaving it empty for now, user can enter new password to change it.
    }
  }

  Future<bool> addTeacher(
    String name,
    String surname,
    String email,
    String password,
  ) async {
    try {
      final response = await api.create("/admin/users", {
        "name": name,
        "surname": surname,
        "email": email,
        "password": password,
      });

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

  Future<bool> updateTeacher(
    int id,
    String name,
    String surname,
    String email,
    String password,
  ) async {
    try {
      final data = {"name": name, "surname": surname, "email": email};
      if (password.isNotEmpty) {
        data["password"] = password;
      }

      final response = await api.update("/admin/users/$id", data);

      if (response?.statusCode == 200) {
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
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
              title: isEditMode
                  ? 'Modifier le professeur'
                  : 'Création un professeur',
              onBack: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 100),
            Container(
              margin: EdgeInsets.all(30),
              padding: EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: (Colors.white),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                      label: 'Nom du professeur',
                      hint: 'entrer le nom du professeur',
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
                      label: 'Prenom du professeur',
                      hint: 'entrer le prenom du professeur',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _surnameController,
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'Email du professeur',
                      hint: 'entrer l\'email du professeur',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _emailController,
                    ),
                    SizedBox(height: 24),
                    CustomTextFormField(
                      label: 'Mot de passe',
                      hint: isEditMode
                          ? 'laisser vide pour ne pas changer'
                          : 'entrer le mot de passe du professeur',
                      obscureText: false,
                      validator: (value) {
                        if (!isEditMode && (value == null || value.isEmpty)) {
                          return "tu dois remplir le champ";
                        }
                        return null;
                      },
                      controller: _passwordController,
                    ),
                    SizedBox(height: 24),
                    PrimaryButton(
                      text: isEditMode ? 'Modifier' : 'Créer un professeur',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final String name = _nameController.text.trim();
                          final String surname = _surnameController.text.trim();
                          final String email = _emailController.text.trim();
                          final String password = _passwordController.text
                              .trim();

                          bool success;
                          if (isEditMode) {
                            success = await updateTeacher(
                              widget.teacher!['id'],
                              name,
                              surname,
                              email,
                              password,
                            );
                          } else {
                            success = await addTeacher(
                              name,
                              surname,
                              email,
                              password,
                            );
                          }

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditMode
                                      ? "Professeur modifié avec succès !"
                                      : "Professeur créé avec succès !",
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            Navigator.pop(
                              context,
                              true,
                            ); // Return true to indicate success
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditMode
                                      ? "Échec de la modification"
                                      : "Échec de la création",
                                ),
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
