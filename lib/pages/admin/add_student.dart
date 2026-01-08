import 'package:flutter/material.dart';
import 'package:togoschool/components/class_dropdown.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/utils/security_utils.dart';

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
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          FormHeader(
            title: isEditMode ? 'MODIFIER L\'ÉLÈVE' : 'NOUVEL ÉTUDIANT',
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
                      color: const Color(0xFF6366F1).withOpacity(0.08),
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
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Color(0xFF6366F1),
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
                                      ? "Édition du profil"
                                      : "Informations Personnelles",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Gérez les informations d'accès de l'élève.",
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
                        label: 'NOM',
                        hint: 'Nom de famille',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _nameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Le nom est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'PRÉNOM',
                        hint: 'Prénom de l\'élève',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _surnameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Le prénom est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ClassDropdown(
                        value: selectedvalue,
                        onChanged: (value) =>
                            setState(() => selectedvalue = value),
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'ADRESSE EMAIL',
                        hint: 'exemple@togoschool.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "L'email est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'MOT DE PASSE',
                        hint: isEditMode
                            ? 'Laisser vide pour ne pas changer'
                            : 'Entrer un mot de passe',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        controller: _passwordController,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (value) =>
                            (!isEditMode && (value == null || value.isEmpty))
                            ? "Le mot de passe est requis"
                            : null,
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: isEditMode
                            ? 'ENREGISTRER LES MODIFICATIONS'
                            : 'CRÉER LE COMPTE ÉLÈVE',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isSaving = true);

                            final String name = SecurityUtils.sanitizeInput(
                              _nameController.text,
                            );
                            final String surname = SecurityUtils.sanitizeInput(
                              _surnameController.text,
                            );
                            final String email = SecurityUtils.sanitizeInput(
                              _emailController.text,
                            );
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
                                        ? "Élève mis à jour avec succès !"
                                        : "Nouvel élève créé avec succès !",
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
                                    "Une erreur est survenue lors de l'enregistrement",
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
                      if (isEditMode) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "ANNULER",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
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
