import 'package:flutter/material.dart';
import 'package:togoschool/pages/forum/forum_list_page.dart';
import 'package:togoschool/services/paygate_service.dart';
import 'package:togoschool/pages/students/payment_required_page.dart';

class StudentForum extends StatefulWidget {
  const StudentForum({super.key});

  @override
  State<StudentForum> createState() => _StudentForumState();
}

class _StudentForumState extends State<StudentForum> {
  final _paygateService = PaygateService();
  bool _isChecking = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkPayment();
  }

  Future<void> _checkPayment() async {
    try {
      final hasPaid = await _paygateService.hasPaid();
      if (mounted) {
        setState(() {
          _hasAccess = hasPaid;
          _isChecking = false;
        });

        // Si l'utilisateur n'a pas payé, afficher la page de paiement
        if (!hasPaid) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentRequiredPage(reason: 'forum'),
            ),
          );

          // Si le paiement a été effectué, re-vérifier l'accès
          if (result == true && mounted) {
            await _checkPayment();
          } else if (mounted && !hasPaid) {
            // Si pas de paiement, retourner en arrière
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      );
    }

    if (!_hasAccess) {
      return const SizedBox.shrink(); // La page de paiement est déjà affichée
    }

    return const ForumListPage();
  }
}
