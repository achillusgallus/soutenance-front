import 'package:flutter/material.dart';
import 'package:togoschool/service/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _api = ApiService();

  int _currentStep = 0; // 0: Email, 1: Code, 2: New Password
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await _api.create("/password/send-code", {
        "email": _emailController.text.trim(),
      });

      if (res?.statusCode == 200) {
        setState(() => _currentStep = 1);
        _showSnackBar("Code envoyé à votre email !", Colors.green);
      } else {
        _showSnackBar("Erreur lors de l'envoi du code", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Une erreur est survenue", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      _showSnackBar("Le code doit contenir 6 chiffres", Colors.orange);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final res = await _api.create("/password/verify-code", {
        "email": _emailController.text.trim(),
        "code": _codeController.text.trim(),
      });

      if (res?.statusCode == 200) {
        setState(() => _currentStep = 2);
      } else {
        _showSnackBar("Code invalide", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erreur de vérification", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _api.create("/password/reset", {
        "email": _emailController.text.trim(),
        "code": _codeController.text.trim(),
        "password": _newPasswordController.text,
      });

      if (res?.statusCode == 200) {
        _showSnackBar("Mot de passe mis à jour !", Colors.green);
        Navigator.pop(context);
      } else {
        _showSnackBar("Échec de la mise à jour", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la mise à jour", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1E293B),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    if (_currentStep == 0) _buildEmailStep(),
                    if (_currentStep == 1) _buildCodeStep(),
                    if (_currentStep == 2) _buildPasswordStep(),
                    const SizedBox(height: 40),
                    _buildActionButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = "";
    String subtitle = "";
    IconData icon = Icons.lock_reset;

    if (_currentStep == 0) {
      title = "Mot de passe oublié ?";
      subtitle = "Entrez votre email pour recevoir un code de vérification.";
      icon = Icons.email_outlined;
    } else if (_currentStep == 1) {
      title = "Vérification";
      subtitle =
          "Saisissez le code de 6 chiffres envoyé à ${_emailController.text}";
      icon = Icons.mark_email_read_outlined;
    } else {
      title = "Nouveau mot de passe";
      subtitle = "Choisissez un mot de passe fort et facil à retenir.";
      icon = Icons.security_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 30),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return _buildTextField(
      controller: _emailController,
      label: "Email",
      hint: "votre@email.com",
      icon: Icons.alternate_email,
      validator: (val) =>
          (val == null || !val.contains("@")) ? "Email invalide" : null,
    );
  }

  Widget _buildCodeStep() {
    return _buildTextField(
      controller: _codeController,
      label: "Code secret",
      hint: "123456",
      icon: Icons.vpn_key_outlined,
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _newPasswordController,
          label: "Nouveau mot de passe",
          hint: "••••••••",
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (val) =>
              (val == null || val.length < 6) ? "Minimum 6 caractères" : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          label: "Confirmez le mot de passe",
          hint: "••••••••",
          icon: Icons.lock_outline,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            counterText: "",
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    String text = "ENVOYER LE CODE";
    VoidCallback? action = _sendResetCode;

    if (_currentStep == 1) {
      text = "VÉRIFIER LE CODE";
      action = _verifyCode;
    } else if (_currentStep == 2) {
      text = "MODIFIER LE MOT DE PASSE";
      action = _resetPassword;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }
}
