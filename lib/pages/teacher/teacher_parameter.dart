import 'package:flutter/material.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/service/token_storage.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/pages/auth/login_page.dart';
import 'package:togoschool/pages/common/legal_page.dart';
import 'package:togoschool/pages/common/notifications_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherParameter extends StatefulWidget {
  const TeacherParameter({super.key});

  @override
  State<TeacherParameter> createState() => _TeacherParameterState();
}

class _TeacherParameterState extends State<TeacherParameter> {
  final api = ApiService();
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool _obscurePassword = true;
  bool _notificationsEnabled = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> getProfile() async {
    try {
      final response = await api.read("/me");
      if (mounted) {
        setState(() {
          profileData = response?.data;
          if (profileData != null) {
            _nameController.text = profileData!['name'] ?? '';
            _surnameController.text = profileData!['surname'] ?? '';
            _emailController.text = profileData!['email'] ?? '';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du chargement du profil")),
        );
      }
    }
  }

  Future<void> logout() async {
    try {
      await api.create("/logout", {});
    } catch (e) {
      // Even if API fails, we clear local storage
    } finally {
      await TokenStorage.clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      final String safeName = SecurityUtils.sanitizeInput(_nameController.text);
      final String safeSurname = SecurityUtils.sanitizeInput(
        _surnameController.text,
      );
      final String safeEmail = SecurityUtils.sanitizeInput(
        _emailController.text,
      );

      final data = {
        "name": safeName,
        "surname": safeSurname,
        "email": safeEmail,
      };
      if (_passwordController.text.isNotEmpty) {
        data["password"] = _passwordController.text.trim();
      }

      data["_method"] = "PUT";
      final response = await api.create("/me", data);
      if (response?.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil mis à jour avec succès"),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            isEditing = false;
            // The backend returns {'user': {...}} on update but just {...} on read
            if (response?.data is Map && response?.data.containsKey('user')) {
              profileData = response?.data['user'];
            } else {
              profileData = response?.data;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Échec de la mise à jour"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Modifier le profil' : 'Paramètres',
              onBack: () {
                if (isEditing) {
                  setState(() => isEditing = false);
                } else {
                  Navigator.pop(context);
                }
              },
              // Add trailing icon for notifications here if FormHeader supports it,
              // but FormHeader implementation was not shown.
              // Assuming FormHeader is simple. I will add a Row/Stack or modifying FormHeader is risky without seeing it.
              // I'll stick to adding notification settings in the list.
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: isEditing
                            ? _buildEditForm()
                            : _buildProfileView(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(FontAwesomeIcons.userTie, size: 40, color: Colors.green),
        ),
        const SizedBox(height: 16),
        Text(
          '${profileData?['name'] ?? 'Professeur'} ${profileData?['surname'] ?? ''}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          profileData?['email'] ?? 'email@ecole.com',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Modifier le profil',
          onPressed: () => setState(() => isEditing = true),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: FontAwesomeIcons.bell,
          title: 'Notifications',
          onTap: _showNotificationSettings,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.shieldHalved,
          title: 'Sécurité',
          onTap: () => setState(() => isEditing = true),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.circleInfo,
          title: 'À propos',
          onTap: _openAbout,
        ),
        const SizedBox(height: 20),
        _buildSettingsTile(
          icon: FontAwesomeIcons.rightFromBracket,
          title: 'Se déconnecter',
          onTap: logout,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations du Compte",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          CustomTextFormField(
            label: 'Nom',
            hint: 'Votre nom',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          CustomTextFormField(
            label: 'Prénom',
            hint: 'Votre prénom',
            prefixIcon: Icons.person_outline,
            controller: _surnameController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          CustomTextFormField(
            label: 'Email',
            hint: 'votre@email.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          CustomTextFormField(
            label: 'Nouveau mot de passe',
            hint: 'Laisser vide pour ne pas changer',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            controller: _passwordController,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: 'ENREGISTRER LES MODIFICATIONS',
            isLoading: isSaving,
            onPressed: updateProfile,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => isEditing = false),
            child: const Center(
              child: Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Notifications"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recevoir des notifications"),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) {
                        setDialogState(() => _notificationsEnabled = v);
                        setState(() {});
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.bell, size: 16),
                    label: const Text("Voir mes notifications"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalPage(
          title: "À propos",
          content: """
**Espace Enseignant v1.0.0**

Gérez vos cours, évaluez vos élèves et participez aux forums de discussion.

© 2026 TogoSchool.
          """,
        ),
      ),
    );
  }
}
