import 'package:flutter/material.dart';
import 'package:togoschool/components/class_dropdown.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';

import 'package:togoschool/service/api_service.dart';

class AddStudent extends StatefulWidget {
  final Map<String, dynamic>? Student;
  const AddStudent({super.key, this.Student});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  String? selectedvalue = 'tle_D';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final api = ApiService();
  bool isSaving = false;
  bool _obscurePassword = true;

  bool get isEditMode => widget.Student != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.Student!['name'] ?? '';
      _surnameController.text = widget.Student!['surname'] ?? '';
      _emailController.text = widget.Student!['email'] ?? '';
    }
  }

  Future<bool> AddStudentAPI(
    String name,
    String surname,
    String email,
    String password,
    String classe,
  ) async {
    try {
      final response = await api.create("/admin/users", {
        "name": name,
        "surname": surname,
        "email": email,
        "password": password,
        "classe": classe,
        "role_id": 3, // Assuming students are role 3
      });
      return response?.statusCode == 201 || response?.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStudent(
    int id,
    String name,
    String surname,
    String email,
    String password,
    String classe,
  ) async {
    try {
      final data = {
        "name": name,
        "surname": surname,
        "email": email,
        "classe": classe,
      };
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
              title: isEditMode ? 'Modifier l\'élève' : 'Nouvel Étudiant',
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
                              ? "Édition du profil"
                              : "Informations Personnelles",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Gérez les informations d'accès et d'identité de l'élève.",
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
                          hint: 'Prénom de l\'élève',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => (value == null || value.isEmpty)
                              ? "Le prénom est requis"
                              : null,
                          controller: _surnameController,
                        ),
                        const SizedBox(height: 20),
                        ClassDropdown(
                          value: selectedvalue,
                          onChanged: (value) =>
                              setState(() => selectedvalue = value),
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          label: 'Email',
                          hint: 'exemple@ecole.com',
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
                          text: isEditMode ? 'ENREGISTRER' : 'CRÉER L\'ÉLÈVE',
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
                              final String classe = selectedvalue ?? 'tle_D';

                              bool success;
                              if (isEditMode) {
                                success = await updateStudent(
                                  widget.Student!['id'],
                                  name,
                                  surname,
                                  email,
                                  password,
                                  classe,
                                );
                              } else {
                                success = await AddStudentAPI(
                                  name,
                                  surname,
                                  email,
                                  password,
                                  classe,
                                );
                              }

                              if (!mounted) return;
                              setState(() => isSaving = false);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditMode
                                          ? "Élève mis à jour !"
                                          : "Élève créé !",
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
