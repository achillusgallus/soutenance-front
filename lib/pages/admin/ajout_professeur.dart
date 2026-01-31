import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/utils/security_utils.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          FormHeader(
            title: isEditMode ? 'MODIFIER LE PROFESSEUR' : 'NOUVEAU PROFESSEUR',
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
                      color: AppTheme.primaryColor.withOpacity(0.08),
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
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppTheme.primaryColor,
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
                                      : "Informations du Compte",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Configurez les accès pour ce professeur.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color,
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
                        hint: 'Prénom du professeur',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _surnameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Le prénom est requis"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'EMAIL PROFESSIONNEL',
                        hint: 'prof@togoschool.com',
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
                            color: theme.disabledColor,
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
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => isSaving = true);

                                    final String name =
                                        SecurityUtils.sanitizeInput(
                                          _nameController.text,
                                        );
                                    final String surname =
                                        SecurityUtils.sanitizeInput(
                                          _surnameController.text,
                                        );
                                    final String email =
                                        SecurityUtils.sanitizeInput(
                                          _emailController.text,
                                        );
                                    final String password = _passwordController
                                        .text
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditMode
                                                ? "Professeur mis à jour avec succès !"
                                                : "Nouveau professeur créé avec succès !",
                                          ),
                                          backgroundColor:
                                              AppTheme.successColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context, true);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            "Une erreur est survenue lors de l'enregistrement",
                                          ),
                                          backgroundColor: AppTheme.errorColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isEditMode
                                          ? Icons.save_rounded
                                          : Icons.check_circle_outline_rounded,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditMode
                                          ? "Enregistrer les modifications"
                                          : "Créer le compte",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (isEditMode) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "ANNULER",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
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
