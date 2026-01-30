import 'package:flutter/material.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/services/token_storage.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/pages/auth/login_page.dart';
import 'package:togoschool/pages/common/legal_page.dart';
import 'package:togoschool/pages/common/notifications_page.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class AdminParameter extends StatefulWidget {
  const AdminParameter({super.key});

  @override
  State<AdminParameter> createState() => _AdminParameterState();
}

class _AdminParameterState extends State<AdminParameter> {
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
            SnackBar(
              content: const Text("Profil mis à jour avec succès"),
              backgroundColor: AppTheme.successColor,
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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Échec de la mise à jour"),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: isEditing ? _buildEditForm() : _buildProfileView(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (isEditing) {
                        setState(() => isEditing = false);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Text(
                    "PARAMÈTRES",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${profileData?['name'] ?? 'Administrateur'} ${profileData?['surname'] ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              profileData?['email'] ?? 'admin@togoschool.com',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildActionCard(
          title: "Modifier mes informations",
          subtitle: "Mettez à jour votre nom, email et mot de passe",
          icon: Icons.edit_note_rounded,
          color: AppTheme.primaryColor,
          onTap: () => setState(() => isEditing = true),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "APPARENCE & SÉCURITÉ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: _showNotificationSettings,
                color: AppTheme.warningColor,
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingsTile(
                icon: Icons.shield_outlined,
                title: 'Sécurité du compte',
                onTap: () => setState(() => isEditing = true),
                color: AppTheme.successColor,
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'À propos de TogoSchool',
                onTap: _openAbout,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _buildSettingsTile(
            icon: Icons.logout_rounded,
            title: 'Se déconnecter',
            onTap: logout,
            color: AppTheme.errorColor,
            showArrow: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MODIFIER MON PROFIL",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextFormField(
                  label: 'NOM',
                  hint: 'Votre nom',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Champ requis" : null,
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  label: 'PRÉNOM',
                  hint: 'Votre prénom',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _surnameController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Champ requis" : null,
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  label: 'ADRESSE EMAIL',
                  hint: 'votre@email.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Champ requis" : null,
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  label: 'NOUVEAU MOT DE PASSE',
                  hint: 'Laissez vide pour ne pas changer',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: theme.hintColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'ENREGISTRER LES MODIFICATIONS',
            isLoading: isSaving,
            onPressed: updateProfile,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() => isEditing = false),
              child: Text(
                "ANNULER",
                style: TextStyle(
                  color: theme.hintColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
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
    required Color color,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color.withAlpha(200),
        ),
      ),
      trailing: showArrow
          ? const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFCBD5E1),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Notifications"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recevoir des notifications"),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setDialogState(() => _notificationsEnabled = v);
                    setState(() {});
                  },
                  activeColor: const Color(0xFF6366F1),
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
          title: "À propos de TogoSchool",
          content: """
**TogoSchool Admin v1.0.0**

Outil de gestion pour la plateforme éducative TogoSchool.

© 2026 TogoSchool.
          """,
        ),
      ),
    );
  }
}
