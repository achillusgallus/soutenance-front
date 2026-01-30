import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/core/theme/app_theme.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadFinanceData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DashHeader(
                      color1: theme.primaryColor,
                      color2: theme.primaryColorDark,
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
                          Text(
                            "RAPPORT DES REVENUS (30 Jours)",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChartContainer(),
                          const SizedBox(height: 32),
                          Text(
                            "DERNIÈRES TRANSACTIONS",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
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
    final theme = Theme.of(context);
    // Ideally use a chart library here. For now, visual placeholder or simple bar builder.
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
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
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['date'].toString().split('-').last, // Day
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
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
    final theme = Theme.of(context);
    final status = p['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final color = isCompleted ? AppTheme.successColor : AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  "${p['method']} • ${p['created_at'].toString().substring(0, 16)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${p['amount']} FCFA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
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
