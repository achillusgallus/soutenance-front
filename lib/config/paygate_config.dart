/// Configuration pour PayGate Global
class PaygateConfig {
  /// Clé API PayGate pour la production
  static const String apiKey = 'cf109128-d93f-4d71-b77d-6d7a7d7dfae8';

  /// Clé API PayGate pour le mode debug/développement (optionnelle)
  /// Si non fournie, utilise la clé de production
  static const String? apiKeyDebug = null;

  /// Longueur de l'identifiant de transaction (par défaut 20)
  static const int identifierLength = 20;
}


