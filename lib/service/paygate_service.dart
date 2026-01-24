import 'package:flutter_paygateglobal/flutter_paygateglobal.dart';
import 'package:togoschool/service/api_service.dart';

class PaygateService {
  final ApiService api = ApiService();

  /// Paiement combiné : TMoney ou Flooz
  ///
  /// [method] doit être "TMY" pour TMoney ou "FLZ" pour Flooz/Moov Money
  /// [phoneNumber] le numéro de téléphone associé au compte mobile money de l'élève
  ///   Format: 8 chiffres (ex: "90123456" pour TMoney ou Flooz au Togo)
  ///   Ce numéro doit correspondre au numéro du compte mobile money qui effectuera le paiement
  /// [amount] le montant en FCFA (par défaut 2000)
  ///
  /// Note: PayGate est initialisé automatiquement au démarrage de l'application dans main.dart
  Future<bool> pay({
    required String method,
    required String phoneNumber,
    int amount = 2000, // Montant par défaut en FCFA
  }) async {
    // Convertir la méthode en PaygateProvider
    PaygateProvider? provider;
    String methodName;

    if (method == "TMY" || method == "TMONEY") {
      provider = PaygateProvider.tmoney;
      methodName = "TMoney";
    } else if (method == "FLZ" || method == "FLOOZ") {
      provider = PaygateProvider.moovMoney;
      methodName = "Flooz";
    } else {
      throw Exception(
        "Méthode de paiement invalide : $method. Utilisez 'TMY' ou 'FLZ'",
      );
    }

    try {
      // Créer un identifiant unique pour la transaction
      final identifier = "txn_${DateTime.now().millisecondsSinceEpoch}";

      // Effectuer le paiement via PayGate
      final result = await Paygate.payV2(
        amount: amount.toDouble(),
        description: "Accès illimité aux cours et forums",
        identifier: identifier,
        phoneNumber: phoneNumber,
        provider: provider,
      );

      if (result.ok && result.identifier != null) {
        // ✅ notifier le backend que le paiement est validé
        try {
          await api.create("/student/validate-payment", {
            "transaction_id": result.identifier,
            "tx_reference": result.txReference,
            "method": methodName,
            "amount": amount,
          });
          return true;
        } catch (e) {
          // Si la notification au backend échoue, on retourne quand même true
          // car le paiement a été initié côté PayGate
          // TODO: Log l'erreur pour investigation ultérieure
          print("Erreur lors de la notification au backend: $e");
          return true;
        }
      } else {
        // Le paiement n'a pas pu être lancé
        print("Échec du paiement: ${result.status}");
        return false;
      }
    } catch (e) {
      // Gestion des erreurs de paiement
      print("Erreur lors du paiement: $e");
      rethrow; // Propager l'erreur pour que l'appelant puisse la gérer
    }
  }

  /// Vérifier si l'élève a payé
  Future<bool> hasPaid() async {
    try {
      final response = await api.read("/student/check-access");
      if (response != null && response.data is Map) {
        // Le backend retourne 'hasPaid' dans FileController.php
        return response.data['hasPaid'] == true ||
            response.data['has_paid'] == true;
      }
      return false;
    } catch (e) {
      // En cas d'erreur, on considère que l'élève n'a pas payé
      print("Erreur lors de la vérification du paiement: $e");
      return false;
    }
  }

  /// Récupérer le total payé par l'élève
  Future<int> getTotalPaid() async {
    try {
      final response = await api.read("/student/total-paid");
      if (response != null &&
          response.data is Map &&
          response.data['total_paid'] != null) {
        final totalPaid = response.data['total_paid'];
        // Conversion sécurisée en int
        if (totalPaid is int) {
          return totalPaid;
        } else if (totalPaid is double) {
          return totalPaid.toInt();
        } else if (totalPaid is String) {
          return int.tryParse(totalPaid) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      // En cas d'erreur, on retourne 0
      print("Erreur lors de la récupération du total payé: $e");
      return 0;
    }
  }

  /// Récupérer le statut d'accès complet (paiement + téléchargements)
  Future<Map<String, dynamic>?> getAccessStatus() async {
    try {
      final response = await api.read("/student/check-access");
      if (response != null && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération du statut d'accès: $e");
      return null;
    }
  }
}
