import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/models/student_progress.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  final api = ApiService();
  late Future<List<Forum>> _forumsFuture;

  @override
  void initState() {
    super.initState();
    _forumsFuture = _fetchForums();
  }

  Future<List<Forum>> _fetchForums() async {
    try {
      final response = await api.read('/admin/forums');

      if (response?.statusCode == 200) {
        final List<dynamic> data = response?.data ?? [];
        return data.map((json) => Forum.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des forums');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur de connexion');
    }
  }

  void _refreshForums() {
    setState(() {
      _forumsFuture = _fetchForums();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Liste des Forums',
              onBack: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 0,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: FutureBuilder<List<Forum>>(
                  future: _forumsFuture,
                  builder: (context, snapshot) {
                    // Loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    // Error state
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.triangleExclamation,
                              size: 60,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: ${snapshot.error}',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshForums,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Empty state
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.comments,
                              size: 60,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun forum disponible',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.disabledColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créez votre premier forum',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Success state with data
                    final forums = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshForums();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: forums.length,
                        itemBuilder: (context, index) {
                          final forum = forums[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            color: theme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.message,
                                  color: AppTheme.warningColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                forum.titre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              subtitle: Text(
                                'Matière: ${forum.matiereNom}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.dividerColor,
                              ),
                              onTap: () {
                                // TODO: Navigate to forum details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Ouvrir le forum: ${forum.titre}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
