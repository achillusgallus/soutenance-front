import 'package:flutter/material.dart';
import 'package:togoschool/components/button_card.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/admin/ajout_forum.dart';
import 'package:togoschool/pages/admin/page_ajout_matiere.dart';
import 'package:togoschool/pages/admin/ajout_professeur.dart';
import 'package:togoschool/pages/admin/page_forum_admin.dart';
import 'package:togoschool/pages/admin/parametres_admin.dart';
import 'package:togoschool/pages/admin/professeurs_admin.dart';
import 'package:togoschool/pages/admin/matiere_admin.dart';
import 'package:togoschool/pages/admin/page_eleves_admin.dart';
import 'package:togoschool/pages/admin/manage_advertisements.dart';
import 'package:togoschool/pages/admin/manage_student_features.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/services/service_impersonnalisation.dart';
import 'package:togoschool/pages/tableau_de_bord/teacher_dashboard_page.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/pages/common/page_notifications.dart';
import 'package:togoschool/pages/forum/forum_topic_list_page.dart';

class AdminAcceuil extends StatefulWidget {
  const AdminAcceuil({super.key});

  @override
  State<AdminAcceuil> createState() => _AdminAcceuilState();
}

class _AdminAcceuilState extends State<AdminAcceuil> {
  final api = ApiService();
  final List<Color> cardColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.redAccent,
    Colors.teal,
  ];

  final List<Color> MatiereColors = [
    const Color.fromARGB(255, 206, 88, 14),
    const Color.fromARGB(255, 53, 4, 252),
    const Color.fromARGB(255, 143, 221, 156),
    const Color.fromARGB(255, 176, 39, 39),
    const Color.fromARGB(255, 223, 82, 255),
    const Color.fromARGB(255, 186, 210, 7),
  ];

  bool isLoading = true;
  List<dynamic> teachers = [];
  List<dynamic> students = [];
  List<dynamic> matieres = [];
  List<dynamic> forums = [];
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    getTeachers();
    _fetchUnreadCount();
  }

  Future<void> getTeachers() async {
    try {
      final results = await Future.wait([
        api.read("/admin/users"),
        api.read("/admin/matieres"),
      ]);

      if (!mounted) return;

      setState(() {
        final List<dynamic> allUsers = results[0]?.data ?? [];
        teachers = allUsers
            .where((user) => user['role_id']?.toString() == "2")
            .toList();
        students = allUsers
            .where((user) => user['role_id']?.toString() == "3")
            .toList();
        matieres = results[1]?.data ?? [];
      });

      final forumRes = await api.read("/admin/forums");
      if (mounted) {
        setState(() {
          forums = forumRes?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await api.read("/notifications");
      if (mounted && res?.data != null) {
        final data = res!.data;
        List<dynamic> notifs = [];
        if (data is Map && data.containsKey('data')) {
          notifs = data['data'];
        } else if (data is List) {
          notifs = data;
        }
        setState(() {
          unreadNotifications = notifs.where((n) {
            final isRead = n['read'] == true || n['read'] == 1;
            return !isRead;
          }).length;
        });
      }
    } catch (e) {
      debugPrint("Error loading admin notifs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getTeachers,
          color: theme.primaryColor,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              DashHeader(
                color1: theme.primaryColor,
                color2: theme.primaryColorDark,
                title: 'Bonjour Administrateur',
                subtitle: 'Supervision du système TogoSchool',
                title1: matieres.length.toString(),
                subtitle1: 'Matières',
                title2: teachers.length.toString(),
                subtitle2: 'Enseignants',
                title3: students.length.toString(),
                subtitle3: 'Elèves',
                notificationCount: unreadNotifications,
                onNotificationTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  _fetchUnreadCount();
                },
              ),
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('ACTIONS RAPIDES', theme),
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 24,
                            color: theme.unselectedWidgetColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminParameter(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ButtonCard(
                          icon: FontAwesomeIcons.book,
                          title: 'Matière',
                          color: AppTheme.primaryColor,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddMatierePage(),
                              ),
                            );
                            getTeachers();
                          },
                        ),
                        ButtonCard(
                          icon: FontAwesomeIcons.userPlus,
                          title: 'Enseignant',
                          color: AppTheme.successColor,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddTeacherPage(),
                              ),
                            );
                            getTeachers();
                          },
                        ),
                        ButtonCard(
                          icon: FontAwesomeIcons.userGraduate,
                          title: 'Étudiants',
                          color: AppTheme.warningColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminStudentPage(),
                              ),
                            );
                          },
                        ),
                        ButtonCard(
                          icon: FontAwesomeIcons.bullhorn,
                          title: 'Publicité',
                          color: Colors.deepOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageAdvertisements(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ButtonCard(
                          icon: FontAwesomeIcons.comments,
                          title: 'Forum',
                          color: AppTheme.accentColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddForumPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ButtonCard(
                          icon: FontAwesomeIcons.lightbulb,
                          title: 'Contenus',
                          color: Colors.amber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageStudentFeatures(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Teachers Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle("ENSEIGNANTS RÉCENTS", theme),
                    if (teachers.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminProfesseur(),
                            ),
                          );
                          getTeachers();
                        },
                        child: Text(
                          "Voir tout",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (teachers.isEmpty)
                _buildEmptyState(
                  Icons.person_off_outlined,
                  "Aucun enseignant trouvé",
                  theme,
                )
              else
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: teachers.length > 5 ? 5 : teachers.length,
                    itemBuilder: (context, index) {
                      var teacher = teachers[index];
                      return GestureDetector(
                        onTap: () async {
                          try {
                            // Sauvegarder le token admin avant impersonation
                            final adminToken = await TokenStorage.getToken();
                            if (adminToken != null) {
                              await TokenStorage.saveAdminToken(adminToken);
                            }

                            // Appel au backend pour générer un token du prof
                            final response = await api.create(
                              "/admin/impersonate/${teacher['id']}",
                              {},
                            );
                            if (response != null &&
                                response.statusCode == 200) {
                              final data = response.data;
                              final token = data['impersonation_token'];

                              // Sauvegarder le token du prof
                              await TokenStorage.saveToken(token);

                              // Démarrer l’impersonation côté front
                              ImpersonationService.startImpersonation(
                                data['teacher'],
                              );

                              // Ouvrir le dashboard enseignant
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherDashboardPage(
                                    isAdminViewing: true,
                                    teacherData: data['teacher'],
                                  ),
                                ),
                              );

                              // Restaurer le token admin AVANT d’appeler /stop
                              final adminTokenRestored =
                                  await TokenStorage.getAdminToken();
                              if (adminTokenRestored != null) {
                                await TokenStorage.saveToken(
                                  adminTokenRestored,
                                );
                              }

                              // Maintenant appeler le backend pour signaler la fin d’impersonation
                              await api.create("/admin/impersonate/stop", {});
                              ImpersonationService.stopImpersonation();

                              // Rafraîchir les données admin
                              getTeachers();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erreur impersonation: $e"),
                              ),
                            );
                          }
                        },
                        child: _buildRecentCard(
                          "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                          teacher['email'] ?? '',
                          index,
                          theme,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 40),

              // Matieres Section
              if (!isLoading && matieres.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("MATIÈRES", theme),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminMatiere(),
                                ),
                              );
                              getTeachers();
                            },
                            child: Text(
                              "Voir tout",
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: matieres.length > 5 ? 5 : matieres.length,
                        itemBuilder: (context, index) {
                          var matiere = matieres[index];
                          String profName =
                              matiere['user_name'] ?? 'Non attribué';
                          return _buildMatiereCard(
                            matiere['nom'] ?? '',
                            profName,
                            index,
                            theme,
                          );
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              // Recent Forums Section
              if (!isLoading && forums.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("FORUMS RÉCENTS", theme),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminForumPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Voir tout",
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: forums.length > 5 ? 5 : forums.length,
                        itemBuilder: (context, index) {
                          final forum = forums[index];
                          return _buildForumCard(forum, index, theme);
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.bodySmall?.color,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: theme.disabledColor)),
        ],
      ),
    );
  }

  Widget _buildRecentCard(String name, String sub, int index, ThemeData theme) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.accentColor,
    ];
    final color = colors[index % colors.length];

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereCard(
    String title,
    String prof,
    int index,
    ThemeData theme,
  ) {
    final color = MatiereColors[index % MatiereColors.length];
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(FontAwesomeIcons.book, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    prof.isNotEmpty ? prof[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prof,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForumCard(dynamic forum, int index, ThemeData theme) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF43F5E), // Rose
    ];
    final color = colors[index % colors.length];

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForumTopicListPage(
                  forumId: forum['id'],
                  forumTitle: forum['titre'] ?? 'Forum',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.forum_rounded, color: color, size: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  forum['titre'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      forum['matiere_nom'] ?? 'Général',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward, size: 12, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
