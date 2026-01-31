import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:dio/dio.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/pages/auth/page_connexion.dart';
import 'package:togoschool/pages/common/legal_page.dart';
import 'package:togoschool/pages/common/page_notifications.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/services/service_paygate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:togoschool/pages/eleves/page_progres_eleve.dart';
import 'package:togoschool/pages/eleves/page_favoris_eleve.dart';
import 'package:togoschool/pages/eleves/page_notes_eleve.dart';
import 'package:togoschool/pages/eleves/page_calendrier_eleve.dart';
import 'package:togoschool/pages/eleves/page_flashcards_eleve.dart';
import 'package:togoschool/pages/eleves/page_questions_eleve.dart';
import 'package:togoschool/pages/eleves/page_succes_eleve.dart';
import 'package:togoschool/pages/eleves/page_historique_paiements.dart';
import 'package:togoschool/services/service_progres.dart';

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
  bool _notificationsEnabled = true;
  String? _selectedClasse;
  bool hasPaid = false;
  int totalPaid = 0;
  final _paygateService = PaygateService();

  final List<Map<String, String>> _classes = [
    {'value': 'tle_D', 'label': 'Terminale D'},
    {'value': 'tle_A4', 'label': 'Terminale A4'},
    {'value': 'tle_C', 'label': 'Terminale C'},
    {'value': 'pre_D', 'label': 'Première D'},
    {'value': 'pre_A4', 'label': 'Première A4'},
    {'value': 'pre_C', 'label': 'Première C'},
    {'value': 'troisieme', 'label': 'Troisième'},
  ];

  final ProgressService _progressService = ProgressService();
  int quizCount = 0;
  int forumCount = 0;
  int favoriteCount = 0;
  int matieresCount = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getProfile();
    _loadStats();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final status = await _paygateService.getAccessStatus();
      if (mounted && status != null) {
        setState(() {
          hasPaid = status['has_paid'] ?? false;
        });
      }
      final total = await _paygateService.getTotalPaid();
      if (mounted) {
        setState(() {
          totalPaid = total;
        });
      }
    } catch (e) {
      debugPrint("Erreur statut premium: $e");
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        api.read("/student/matieres"),
        api.read("/quiz"),
        api.read("/forums"),
        _progressService.getFavorites(),
      ]);

      if (mounted) {
        setState(() {
          // Matieres
          final matRes = (results[0] as Response?)?.data;
          if (matRes is List) {
            matieresCount = matRes.length;
          } else if (matRes is Map && matRes.containsKey('data')) {
            matieresCount = (matRes['data'] as List).length;
          }

          // Quiz
          final quizRes = (results[1] as Response?)?.data;
          if (quizRes is List) {
            quizCount = quizRes.length;
          } else if (quizRes is Map && quizRes.containsKey('total')) {
            quizCount = quizRes['total'] ?? 0;
          } else if (quizRes is Map && quizRes.containsKey('data')) {
            quizCount = (quizRes['data'] as List).length;
          }

          // Forums
          final forumsRes = (results[2] as Response?)?.data;
          if (forumsRes is List) {
            forumCount = forumsRes.length;
          } else if (forumsRes is Map && forumsRes.containsKey('data')) {
            forumCount = (forumsRes['data'] as List).length;
          }

          // Favorites
          final favRes = results[3];
          if (favRes is List) favoriteCount = favRes.length;
        });
      }
    } catch (e) {
      debugPrint("Erreur Stats Profil: $e");
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
            _selectedClasse = profileData!['classe'];
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
        "classe": _selectedClasse,
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
          SnackBar(
            content: const Text("Échec de la mise à jour"),
            backgroundColor: AppTheme.errorColor,
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
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
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
    final theme = Theme.of(context);
    final name = profileData?['name'] ?? 'Élève';
    final surname = profileData?['surname'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColorDark],
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
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Icon(
                FontAwesomeIcons.userGraduate,
                size: 36,
                color: theme.primaryColor,
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
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          if (profileData?['classe'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FontAwesomeIcons.graduationCap,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Classe : ${_getClassName(profileData!['classe'])}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: hasPaid
                  ? Colors.amber.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPaid ? Icons.star_rounded : Icons.person_outline,
                  size: 14,
                  color: hasPaid ? Colors.brown : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPaid ? "COMPTE PREMIUM" : "COMPTE GRATUIT",
                  style: TextStyle(
                    color: hasPaid ? Colors.brown : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClassName(String code) {
    final found = _classes.firstWhere(
      (c) => c['value'] == code,
      orElse: () => {'label': code},
    );
    return found['label'] ?? code;
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
          color: theme.primaryColor,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.bell,
          title: 'Préférences de notification',
          onTap: _showNotificationSettings,
          color: AppTheme.warningColor,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.shieldHalved,
          title: 'Sécurité & Mot de passe',
          onTap: () => setState(() => isEditing = true),
          color: AppTheme.successColor,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.creditCard,
          title: 'Mon abonnement & Paiements',
          subtitle: hasPaid ? 'Premium Activé' : 'Passer au Premium',
          onTap: _showSubscriptionInfo,
          color: Colors.amber,
          trailing: hasPaid
              ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
              : null,
        ),
        const SizedBox(height: 32),
        Text(
          "MES OUTILS & APPRENTISSAGE",
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
          title: "Suivi de Progression",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentProgressPage()),
          ),
          color: const Color(0xFF8B5CF6),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.heart,
          title: "Mes Favoris",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentFavoritesPage()),
          ),
          color: const Color(0xFFEC4899),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.stickyNote,
          title: "Mes Notes",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentNotesPage()),
          ),
          color: const Color(0xFF10B981),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.calendarDay,
          title: "Calendrier de la session",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentCalendarPage()),
          ),
          color: const Color(0xFFF59E0B),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.layerGroup,
          title: "Révision Flashcards",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentFlashcardsPage()),
          ),
          color: const Color(0xFF6366F1),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.questionCircle,
          title: "Questions & Réponses",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentQuestionsPage()),
          ),
          color: const Color(0xFF10B981),
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.trophy,
          title: "Mes Succès & Badges",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentAchievementsPage()),
          ),
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 32),
        Text(
          "RESSOURCES",
          style: TextStyle(
            color: theme.hintColor,
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
          color: Colors.blueGrey,
        ),
        _buildSettingsTile(
          icon: FontAwesomeIcons.headset,
          title: 'Aide & Support',
          onTap: _showSupportDialog,
          color: theme.primaryColor,
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
              backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.errorColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);
    final color = theme.primaryColor;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MISE À JOUR DU PROFIL",
            style: TextStyle(
              color: theme.hintColor,
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
          _buildFieldLabel("Classe"),
          DropdownButtonFormField<String>(
            value: _selectedClasse,
            decoration: InputDecoration(
              prefixIcon: Icon(
                FontAwesomeIcons.graduationCap,
                size: 18,
                color: color,
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            items: _classes.map((c) {
              return DropdownMenuItem(
                value: c['value'],
                child: Text(c['label']!),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedClasse = val);
            },
            validator: (v) =>
                (v == null) ? "Veuillez choisir une classe" : null,
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
                color: theme.hintColor,
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
                  color: theme.hintColor,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              )
            : null,
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
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
            child: Text(
              "ANNULER",
              style: TextStyle(color: theme.disabledColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
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
                  activeColor: Theme.of(context).primaryColor,
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Besoin d'aide ?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contactez notre équipe de support technique pour toute assistance.",
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                const Text(
                  "support@togoschool.tg",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                const Text(
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
              backgroundColor: theme.primaryColor,
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

  void _showSubscriptionInfo() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              hasPaid ? Icons.verified_user_rounded : Icons.stars_rounded,
              size: 60,
              color: hasPaid ? AppTheme.successColor : Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              hasPaid ? "Compte Premium Actif" : "Devenez Membre Premium",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasPaid
                  ? "Vous profitez de l'accès illimité à tous nos services."
                  : "Débloquez les forums, les téléchargements illimités et bien plus encore.",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            const Divider(height: 40),
            _buildInfoRow(
              "Montant total investi",
              "$totalPaid FCFA",
              Icons.payments_outlined,
            ),
            _buildInfoRow(
              "Statut de l'accès",
              hasPaid ? "Illimité" : "Restreint",
              Icons.lock_open_rounded,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
                );
              },
              icon: const Icon(Icons.history, size: 18),
              label: const Text("Voir l'historique des paiements"),
            ),
            const Spacer(),
            if (!hasPaid)
              PrimaryButton(
                text: "PASSER AU PREMIUM",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
