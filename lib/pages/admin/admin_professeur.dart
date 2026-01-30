import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/services/impersonation_service.dart';
import 'package:togoschool/pages/dashbord/teacher_dashboard_page.dart';

class AdminProfesseur extends StatefulWidget {
  const AdminProfesseur({super.key});

  @override
  State<AdminProfesseur> createState() => _AdminProfesseurState();
}

class _AdminProfesseurState extends State<AdminProfesseur> {
  final api = ApiService();
  final List<Color> cardColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.redAccent,
    Colors.teal,
  ];

  bool isLoading = true;
  List<dynamic> teachers = [];
  List<dynamic> matieres = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      final results = await Future.wait([
        api.read("/admin/users"),
        api.read("/admin/matieres"),
      ]);

      if (!mounted) return;

      setState(() {
        final List<dynamic> allUsers = results[0]?.data ?? [];
        teachers = allUsers.where((user) => user['role_id'] == 2).toList();
        matieres = results[1]?.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteTeacher(int id) async {
    try {
      await api.delete("/admin/users/$id");
      setState(() {
        teachers.removeWhere((teacher) => teacher['id'] == id);
      });
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> updateTeacher(dynamic teacher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTeacherPage(teacher: teacher)),
    );

    if (result == true) {
      getData();
    }
  }

  List<dynamic> getTeacherMatieres(int teacherId) {
    return matieres.where((m) => m['user_id'] == teacherId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          DashHeader(
            color1: AppTheme.primaryColor,
            color2: AppTheme.primaryColor.withOpacity(0.8),
            title: "GESTION ENSEIGNANTS",
            subtitle: "Administrez le corps professoral de l'établissement",
            title1: teachers.length.toString(),
            subtitle1: "Enseignants",
            title2: matieres.length.toString(),
            subtitle2: "Matières",
            title3: "",
            subtitle3: "",
            onBack: () => Navigator.pop(context),
          ),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: getData,
              color: AppTheme.primaryColor,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : teachers.isEmpty
                  ? _buildEmptyState()
                  : _buildTeacherList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "add_teacher_btn",
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTeacherPage()),
          );
          if (result == true) getData();
        },
        backgroundColor: AppTheme.successColor,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          "NOUVEAU PROFESSEUR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un professeur...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            // Local search logic can be added here if needed
          },
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    final theme = Theme.of(context);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final color = cardColors[index % cardColors.length];
        final assignedMatieres = getTeacherMatieres(teacher['id']);

        return GestureDetector(
          onTap: () {
            ImpersonationService.startImpersonation(teacher);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDashboardPage(
                  isAdminViewing: true,
                  teacherData: teacher,
                ),
              ),
            ).then((_) {
              ImpersonationService.stopImpersonation();
              getData(); // Refresh data
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              teacher['email'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTeacherActions(teacher),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "MATIÈRES AFFECTÉES",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.bodyMedium?.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (assignedMatieres.isEmpty)
                          Text(
                            "Aucune matière affectée",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: assignedMatieres
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      m['nom'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherActions(dynamic teacher) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.textTheme.bodySmall?.color,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'edit') {
          updateTeacher(teacher);
        } else if (value == 'delete') {
          _showDeleteConfirmation(teacher);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                "Modifier",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 12),
              Text(
                "Supprimer",
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(dynamic teacher) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Supprimer ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Voulez-vous vraiment supprimer le professeur ${teacher['name']} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "ANNULER",
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteTeacher(teacher['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("SUPPRIMER"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_rounded,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucun enseignant trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez par ajouter votre premier professeur.",
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
