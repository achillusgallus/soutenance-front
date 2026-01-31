import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/pages/auth/page_connexion.dart';

class TeacherProfil extends StatefulWidget {
  const TeacherProfil({super.key});

  @override
  State<TeacherProfil> createState() => _TeacherProfilState();
}

class _TeacherProfilState extends State<TeacherProfil> {
  final api = ApiService();
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  bool _obscurePassword = true;

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
      // Clear locally even if API fails
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
      if (response != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil mis à jour avec succès"),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          setState(() {
            isEditing = false;
            if (response.data is Map && response.data.containsKey('user')) {
              profileData = response.data['user'];
            } else {
              profileData = response.data;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Échec de la mise à jour"),
            backgroundColor: Color(0xFFEF4444),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
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
    final name = profileData?['name'] ?? 'Professeur';
    final surname = profileData?['surname'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
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
              const SizedBox(width: 48), // Spacer
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
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Icon(
                FontAwesomeIcons.chalkboardUser,
                size: 36,
                color: AppTheme.primaryColor,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PARAMÈTRES DU COMPTE",
          style: TextStyle(
            color: theme.hintColor,
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
          color: AppTheme.primaryColor,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.bell,
          title: 'Notifications & Alertes',
          onTap: () {},
          color: const Color(0xFFF59E0B),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.shieldHalved,
          title: 'Confidentialité & Sécurité',
          onTap: () {},
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 32),
        Text(
          "ACTIVITÉ",
          style: TextStyle(
            color: theme.hintColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: FontAwesomeIcons.chartLine,
          title: 'Statistiques de mes cours',
          onTap: () {},
          color: const Color(0xFF8B5CF6),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.bookOpenReader,
          title: 'Rapport d\'activité élèves',
          onTap: () {},
          color: const Color(0xFF3B82F6),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(icon, color: theme.iconTheme.color),
          filled: true,
          fillColor: isDark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MISE À JOUR DU PROFIL",
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldLabel("Nom"),
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
                color: Theme.of(context).hintColor,
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
              child: Text(
                "Annuler les modifications",
                style: TextStyle(
                  color: Theme.of(context).hintColor,
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleMedium?.color,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
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
}
