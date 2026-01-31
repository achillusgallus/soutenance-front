class SecurityUtils {
  /// Nettoie une chaîne de caractères pour empêcher l'injection de scripts de base.
  /// Supprime les balises HTML et les espaces inutiles.
  static String sanitizeInput(String? value) {
    if (value == null || value.isEmpty) return "";

    // 1. Trim les espaces
    String sanitized = value.trim();

    // 2. Suppression rudimentaire des balises HTML/Script
    // On remplace les caractères < et > par des versions encodées ou on les supprime
    // Pour Flutter, le plus sûr est de les supprimer ou de les échapper si on veut rester simple.
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

    return sanitized;
  }

  /// Prévient l'utilisation de caractères suspects pour les injections SQL.
  /// Note: Le backend Laravel gère déjà cela avec Eloquent, mais c'est une sécurité en plus.
  static String preventSqlChars(String value) {
    // Liste de mots clés SQL sensibles à éviter ou à surveiller
    // Dans une app Flutter, on va surtout éviter les guillemets qui ferment les strings SQL
    return value.replaceAll("'", "''").replaceAll(";", "");
  }
}


