import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/pages/auth/page_connexion.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/pages/common/legal_page.dart';

class StudentInscriptionPage extends StatefulWidget {
  const StudentInscriptionPage({super.key});

  @override
  State<StudentInscriptionPage> createState() => _StudentInscriptionPageState();
}

class _StudentInscriptionPageState extends State<StudentInscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedClasse = 'tle_D';
  final _api = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  final List<Map<String, String>> _classes = [
    {'value': 'tle_D', 'label': 'Terminale D'},
    {'value': 'tle_C', 'label': 'Terminale C'},
    {'value': 'tle_A', 'label': 'Terminale A'},
    {'value': '1ere_D', 'label': 'Première D'},
    {'value': '1ere_C', 'label': 'Première C'},
    {'value': '1ere_A', 'label': 'Première A'},
    {'value': '2nde_S', 'label': 'Seconde S'},
    {'value': '2nde_A', 'label': 'Seconde A'},
    {'value': '3eme', 'label': 'Troisième'},
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Vous devez accepter les conditions d'utilisation.",
          ),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String safeName = SecurityUtils.sanitizeInput(_nomController.text);
      final String safeSurname = SecurityUtils.sanitizeInput(
        _prenomController.text,
      );
      final String safeEmail = SecurityUtils.sanitizeInput(
        _emailController.text,
      );

      final response = await _api.create("/register", {
        "name": safeName,
        "surname": safeSurname,
        "email": safeEmail,
        "password": _passwordController.text.trim(),
        "classe": _selectedClasse,
      });

      if (response?.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie ! Connectez-vous."),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Échec de l'inscription. L'email est peut-être déjà utilisé.",
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Une erreur est survenue : $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App Bar like back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Créer un compte",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Rejoignez TOGOSCHOOL dès aujourd'hui",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _nomController,
                                label: "Nom",
                                hint: "Doe",
                                icon: Icons.person_outline,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? "Requis"
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildInputField(
                                controller: _prenomController,
                                label: "Prénom",
                                hint: "John",
                                icon: Icons.person_outline,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? "Requis"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _emailController,
                          label: "Email",
                          hint: "nom@exemple.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "L'email est requis";
                            if (!value.contains("@")) return "Email invalide";
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _passwordController,
                          label: "Mot de passe",
                          hint: "••••••••",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.hintColor,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Le mot de passe est requis";
                            if (value.length < 6) return "Minimum 6 caractères";
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Terms and Conditions Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptedTerms,
                                activeColor: theme.primaryColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) =>
                                    setState(() => _acceptedTerms = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "J'accepte les ",
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  _buildLegalLink(
                                    "conditions",
                                    () => _openTerms(context),
                                  ),
                                  Text(
                                    " et la ",
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  _buildLegalLink(
                                    "politique de confidentialité",
                                    () => _openPrivacy(context),
                                  ),
                                  Text(".", style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "S'INSCRIRE",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Footer info cards or link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Déjà un compte ?",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Connectez-vous",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildBenefitItem(
                    icon: FontAwesomeIcons.bookOpen,
                    color: theme.primaryColor,
                    title: "Cours complets",
                    desc: "PDF, audio et vidéo à portée de main",
                  ),
                  _buildBenefitItem(
                    icon: FontAwesomeIcons.vials,
                    color: AppTheme.successColor,
                    title: "Quiz interactifs",
                    desc: "Testez vos connaissances en temps réel",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.hintColor, fontSize: 15),
            prefixIcon: Icon(icon, color: theme.primaryColor, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Classe",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedClasse,
              icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.school_outlined,
                  color: theme.primaryColor,
                  size: 22,
                ),
              ),
              items: _classes.map((classe) {
                return DropdownMenuItem<String>(
                  value: classe['value'],
                  child: Text(classe['label']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedClasse = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(desc, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String text, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalPage(
          title: "Conditions Générales d'Utilisation",
          content: """
**Dernière mise à jour : 24 Janvier 2026**

Bienvenue sur **TogoSchool**, la plateforme numérique d'excellence pour l'éducation au Togo. L'utilisation de cette application est soumise aux présentes conditions générales. En créant un compte, vous acceptez de vous y conformer sans réserve.

### 1. Accès au Service
L'accès à TogoSchool est réservé aux élèves et enseignants régulièrement inscrits. L'utilisateur est responsable de la confidentialité de ses identifiants (email et mot de passe). Toute action effectuée depuis votre compte est réputée être effectuée par vous.

### 2. Propriété Intellectuelle
Tous les contenus pédagogiques présents sur l'application (cours vidéo, fiches PDF, questions de quiz, corrigés) sont la propriété exclusive de TogoSchool et de ses enseignants partenaires.
* **Il est strictement interdit** de copier, distribuer, vendre ou publier ces contenus sur d'autres plateformes (WhatsApp, Telegram, Facebook, etc.) sans autorisation écrite.
* Tout contrevenant s'expose à la suppression immédiate de son compte et à des poursuites judiciaires.

### 3. Usage des Forums et Communauté
Les espaces de discussion (Forums) sont destinés à l'entraide pédagogique.
* **Respect** : Aucun propos injurieux, haineux ou discriminatoire ne sera toléré.
* **Pertinence** : Les messages doivent concerner les cours ou la vie scolaire.
* **Sécurité** : Ne partagez jamais vos informations personnelles (numéro de téléphone, adresse) publiquement sur le forum.

### 4. Téléchargements et Paiements
Certains contenus peuvent être soumis à un quota de téléchargement gratuit. Au-delà, l'utilisateur peut être invité à utiliser des services de paiement mobile (ex: Flooz, T-Money via PayGate) pour accéder à des ressources supplémentaires. Ces transactions sont définitives et non remboursables, sauf dysfonctionnement technique avéré de notre part.

### 5. Disponibilité
Nous nous efforçons de maintenir la plateforme accessible 24h/24 et 7j/7. Toutefois, l'accès peut être suspendu pour maintenance ou en cas de force majeure. TogoSchool ne saurait être tenu responsable des interruptions liées au réseau internet de l'utilisateur.

### 6. Sanctions
Le non-respect de ces règles peut entraîner un avertissement, une suspension temporaire ou la suppression définitive du compte, selon la gravité de l'infraction.
""",
        ),
      ),
    );
  }

  void _openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalPage(
          title: "Politique de Confidentialité",
          content: """
**Engagement de confidentialité TogoSchool**

Votre vie privée est essentielle. Cette politique détaille comment nous traitons vos données personnelles dans le cadre de votre scolarité sur TogoSchool.

### 1. Les Données que nous collectons
Pour assurer le bon fonctionnement du service, nous collectons :
* **Informations d'inscription** : Nom, Prénom, Email, Classe, Établissement.
* **Données d'activité** : Cours consultés, vidéos regardées, fichiers téléchargés.
* **Données pédagogiques** : Scores aux quiz, progrès dans les chapitres, questions posées sur les forums.

### 2. Pourquoi utilisons-nous vos données ?
Vos données ne sont utilisées que dans un but éducatif et technique :
* **Suivi Pédagogique** : Permettre à vos enseignants de suivre vos progrès et d'adapter leurs cours.
* **Personnalisation** : Vous proposer des contenus adaptés à votre niveau (ex: Terminale D).
* **Amélioration** : Analyser les statistiques globales pour améliorer la qualité de l'application.

### 3. Partage des Données
**Nous ne vendons jamais vos données à des tiers.**
Vos informations sont accessibles uniquement :
* À l'équipe technique de TogoSchool (pour la maintenance).
* À l'équipe pédagogique (Professeurs et Administration) pour le suivi scolaire.
* Aux autorités compétentes si la loi l'exige.

### 4. Sécurité
Vos mots de passe sont chiffrés et nous utilisons des protocoles sécurisés pour protéger les échanges de données. Cependant, la sécurité dépend aussi de vous : choisissez un mot de passe complexe et gardez-le secret.

### 5. Vos Droits
Conformément à la réglementation en vigueur au Togo sur la protection des données à caractère personnel, vous disposez d'un droit d'accès, de rectification et suppression de vos informations. Pour toute demande, veuillez contacter le support via l'application ou par email à support@togoschool.tg.
""",
        ),
      ),
    );
  }
}
