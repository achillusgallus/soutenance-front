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
  bool isSaving = false;
  bool _obscurePassword = true;

  bool get isEditMode => widget.teacher != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.teacher!['name'] ?? '';
      _surnameController.text = widget.teacher!['surname'] ?? '';
      _emailController.text = widget.teacher!['email'] ?? '';
    }
  }

  Future<bool> addTeacherAPI(
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
        "role_id": 2, // Teachers are role 2
      });
      return response?.statusCode == 201 || response?.statusCode == 200;
    } catch (e) {
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
      if (password.isNotEmpty) data["password"] = password;

      final response = await api.update("/admin/users/$id", data);
      return response?.statusCode == 200;
    } catch (e) {
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditMode
                  ? 'Modifier le professeur'
                  : 'Nouveau Professeur',
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
                              ? "Édition de l'enseignant"
                              : "Informations du Compte",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Configurez les accès pour ce membre du corps enseignant.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomTextFormField(
                          label: 'Nom',
                          hint: 'Nom de famille',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => (value == null || value.isEmpty)
                              ? "Le nom est requis"
                              : null,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Prénom',
                          hint: 'Prénom du professeur',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => (value == null || value.isEmpty)
                              ? "Le prénom est requis"
                              : null,
                          controller: _surnameController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Email professionnel',
                          hint: 'prof@ecole.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value == null || value.isEmpty)
                              ? "L'email est requis"
                              : null,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Mot de passe',
                          hint: isEditMode
                              ? 'Laisser vide pour ne pas changer'
                              : 'Entrer un mot de passe',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) =>
                              (!isEditMode && (value == null || value.isEmpty))
                              ? "Le mot de passe est requis"
                              : null,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          text: isEditMode
                              ? 'ENREGISTRER'
                              : 'CRÉER LE PROFESSEUR',
                          isLoading: isSaving,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isSaving = true);

                              final String name = _nameController.text.trim();
                              final String surname = _surnameController.text
                                  .trim();
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
                                success = await addTeacherAPI(
                                  name,
                                  surname,
                                  email,
                                  password,
                                );
                              }

                              if (!mounted) return;
                              setState(() => isSaving = false);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditMode
                                          ? "Professeur mis à jour !"
                                          : "Professeur créé !",
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Une erreur est survenue lors de l'enregistrement",
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
