import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/service/token_storage.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/pages/auth/login_page.dart';
import 'package:togoschool/pages/common/legal_page.dart';
import 'package:togoschool/pages/common/notifications_page.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfil extends StatefulWidget {
  const StudentProfil({super.key});

  @override
  State<StudentProfil> createState() => _StudentProfilState();
}

class _StudentProfilState extends State<StudentProfil> {
  final api = ApiService();
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool _obscurePassword = true;
  bool _notificationsEnabled = true; // Local state for now

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
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: isEditing ? _buildEditForm() : _buildProfileView(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    final name = profileData?['name'] ?? 'Élève';
    final surname = profileData?['surname'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => isEditing
                    ? setState(() => isEditing = false)
                    : Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Text(
                "MON PROFIL",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Icon(
                FontAwesomeIcons.userGraduate,
                size: 36,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "$name $surname",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileData?['email'] ?? 'votre@ecole.com',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PARAMÈTRES DU COMPTE",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: FontAwesomeIcons.userPen,
          title: 'Modifier mes informations',
          onTap: () => setState(() => isEditing = true),
          color: const Color(0xFF6366F1),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.bell,
          title: 'Préférences de notification',
          onTap: _showNotificationSettings,
          color: const Color(0xFFF59E0B),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.shieldHalved,
          title: 'Sécurité & Mot de passe',
          onTap: () => setState(() => isEditing = true),
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 32),
        const Text(
          "RESSOURCES",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: FontAwesomeIcons.circleInfo,
          title: 'À propos de TogoSchool',
          onTap: _openAbout,
          color: const Color(0xFF64748B),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.headset,
          title: 'Aide & Support',
          onTap: _showSupportDialog,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 16),
            label: const Text(
              "SE DÉCONNECTER",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
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
            "MISE À JOUR DU PROFIL",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldLabel("Nom complet"),
          CustomTextFormField(
            label: 'Nom',
            hint: 'Entrez votre nom',
            prefixIcon: Icons.person_outline_rounded,
            controller: _nameController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel("Prénom"),
          CustomTextFormField(
            label: 'Prénom',
            hint: 'Entrez votre prénom',
            prefixIcon: Icons.person_outline_rounded,
            controller: _surnameController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel("Adresse Email"),
          CustomTextFormField(
            label: 'Email',
            hint: 'votre@ecole.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel("Sécurité"),
          CustomTextFormField(
            label: 'Nouveau mot de passe',
            hint: 'Laissez vide pour conserver l\'actuel',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            controller: _passwordController,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 48),
          PrimaryButton(
            text: 'ENREGISTRER LES MODIFICATIONS',
            isLoading: isSaving,
            onPressed: updateProfile,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() => isEditing = false),
              child: const Text(
                "Annuler les modifications",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Se déconnecter ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Êtes-vous sûr de vouloir quitter votre session ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ANNULER",
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("DÉCONNEXION"),
          ),
        ],
      ),
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
                    // Update main state/persist if needed
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
**TogoSchool v1.0.0**

TogoSchool est une initiative visant à numériser l'éducation au Togo. Nous fournissons aux élèves et aux enseignants une plateforme moderne pour échanger, apprendre et progresser.

© 2026 TogoSchool. Tous droits réservés.
          """,
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Besoin d'aide ?"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contactez notre équipe de support technique pour toute assistance.",
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  "support@togoschool.tg",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  "+228 90 00 00 00",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
          ElevatedButton(
            onPressed: () {
              // Launch email
              try {
                launchUrl(Uri.parse("mailto:support@togoschool.tg"));
              } catch (e) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text(
              "Contacter",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
