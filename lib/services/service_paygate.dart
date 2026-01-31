import 'package:flutter_paygateglobal/flutter_paygateglobal.dart';
import 'package:togoschool/services/service_api.dart';

class PaygateService {
  final ApiService api = ApiService();

  Future<bool> pay({
    required String method,
    required String phoneNumber,
    int amount = 2000,
  }) async {
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
      final identifier = "txn_${DateTime.now().millisecondsSinceEpoch}";

      final result = await Paygate.payV2(
        amount: amount.toDouble(),
        description: "Accès illimité aux cours et forums",
        identifier: identifier,
        phoneNumber: phoneNumber,
        provider: provider,
      );

      if (result.ok && result.identifier != null) {
        try {
          await api.create("/student/validate-payment", {
            "transaction_id": result.identifier,
            "tx_reference": result.txReference,
            "method": methodName,
            "amount": amount,
          });
          return true;
        } catch (e) {
          print("Erreur lors de la notification au backend: $e");
          return true;
        }
      } else {
        print("Échec du paiement: ${result.status}");
        return false;
      }
    } catch (e) {
      print("Erreur lors du paiement: $e");
      rethrow;
    }
  }

  Future<bool> hasPaid() async {
    try {
      final response = await api.read("/student/check-access");
      if (response != null && response.data is Map) {
        return response.data['hasPaid'] == true ||
            response.data['has_paid'] == true;
      }
      return false;
    } catch (e) {
      print("Erreur lors de la vérification du paiement: $e");
      return false;
    }
  }

  Future<int> getTotalPaid() async {
    try {
      final response = await api.read("/student/total-paid");
      if (response != null &&
          response.data is Map &&
          response.data['total_paid'] != null) {
        final totalPaid = response.data['total_paid'];
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
      print("Erreur lors de la récupération du total payé: $e");
      return 0;
    }
  }

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
