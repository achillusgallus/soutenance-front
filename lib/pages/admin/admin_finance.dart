import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminFinance extends StatefulWidget {
  const AdminFinance({super.key});

  @override
  State<AdminFinance> createState() => _AdminFinanceState();
}

class _AdminFinanceState extends State<AdminFinance> {
  final api = ApiService();
  bool isLoading = true;
  int totalRevenue = 0;
  int pendingCount = 0;
  int completedCount = 0;
  List<dynamic> payments = [];
  List<dynamic> chartData = []; // Date, Amount

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => isLoading = true);
    try {
      final res = await api.read("/admin/payments");
      final reportRes = await api.read(
        "/admin/payments/report",
      ); // Assuming this endpoint exists for chart

      if (mounted) {
        setState(() {
          if (res?.data != null) {
            final stats = res!.data['stats'] ?? {};
            totalRevenue = stats['total_revenue'] ?? 0;
            pendingCount = stats['pending_count'] ?? 0;
            completedCount = stats['completed_count'] ?? 0;

            final payData = res.data['payments'];
            if (payData is Map && payData.containsKey('data')) {
              payments = payData['data'];
            } else if (payData is List) {
              payments = payData;
            }
          }

          if (reportRes?.data != null && reportRes!.data['success'] == true) {
            chartData = reportRes.data['report_data'] ?? [];
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      // Handle error gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : RefreshIndicator(
              onRefresh: _loadFinanceData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DashHeader(
                      color1: const Color(0xFF6366F1),
                      color2: const Color(0xFF4F46E5),
                      title: "GESTION FINANCIÈRE",
                      subtitle: "Suivez les revenus et paiements",
                      title1: "$totalRevenue F",
                      subtitle1: "CA Total",
                      title2: "$pendingCount",
                      subtitle2: "En Attente",
                      title3: "$completedCount",
                      subtitle3: "Payés",
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "RAPPORT DES REVENUS (30 Jours)",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChartContainer(),
                          const SizedBox(height: 32),
                          const Text(
                            "DERNIÈRES TRANSACTIONS",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionsList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartContainer() {
    // Ideally use a chart library here. For now, visual placeholder or simple bar builder.
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: chartData.isEmpty
          ? const Center(child: Text("Pas assez de données pour le graphique"))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: chartData.map((d) {
                // Normalize height
                // Assuming max height 150
                int val = int.tryParse(d['total'].toString()) ?? 0;
                // Simple normalization logic for mockup
                double h = (val / (totalRevenue + 1)) * 1000;
                if (h > 150) h = 150;
                if (h < 10 && val > 0) h = 10;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: h.toDouble(),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['date'].toString().split('-').last, // Day
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTransactionsList() {
    if (payments.isEmpty) {
      return const Center(child: Text("Aucune transaction trouvée"));
    }
    return Column(
      children: payments.map((p) => _buildTransactionCard(p)).toList(),
    );
  }

  Widget _buildTransactionCard(dynamic p) {
    final status = p['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? FontAwesomeIcons.check : FontAwesomeIcons.clock,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['user'] != null
                      ? "${p['user']['name']} ${p['user']['surname']}"
                      : "Utilisateur inconnu",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "${p['method']} • ${p['created_at'].toString().substring(0, 16)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${p['amount']} FCFA",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                isCompleted ? "Payé" : "En attente",
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
