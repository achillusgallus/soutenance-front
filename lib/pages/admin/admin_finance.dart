import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';

class AdminFinance extends StatefulWidget {
  const AdminFinance({super.key});

  @override
  State<AdminFinance> createState() => _AdminFinanceState();
}

class _AdminFinanceState extends State<AdminFinance> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          const DashHeader(
            color1: Color(0xFF6366F1),
            color2: Color(0xFF4F46E5),
            title: "GESTION FINANCIÈRE",
            subtitle: "Suivez les revenus et paiements",
            title1: "0 FCFA",
            subtitle1: "CA Total",
            title2: "0",
            subtitle2: "En Attente",
            title3: "0",
            subtitle3: "Payés",
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 64,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Gestion Financière",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Le module financier sera disponible prochainement.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "EN DÉVELOPPEMENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
