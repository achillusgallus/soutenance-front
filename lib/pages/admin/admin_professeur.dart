import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/service/api_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          DashHeader(
            color1: const Color(0xFF6366F1),
            color2: const Color(0xFF4F46E5),
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
              color: const Color(0xFF6366F1),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTeacherPage()),
          );
          if (result == true) getData();
        },
        backgroundColor: const Color(0xFF10B981),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un professeur...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6366F1),
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
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final color = cardColors[index % cardColors.length];
        final assignedMatieres = getTeacherMatieres(teacher['id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                      child: Icon(Icons.person_rounded, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teacher['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.book_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "MATIÈRES AFFECTÉES",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
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
                            color: const Color(0xFF94A3B8),
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
        );
      },
    );
  }

  Widget _buildTeacherActions(dynamic teacher) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'edit') {
          updateTeacher(teacher);
        } else if (value == 'delete') {
          _showDeleteConfirmation(teacher);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 12),
              Text("Modifier", style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 12),
              Text(
                "Supprimer",
                style: TextStyle(
                  color: Color(0xFFEF4444),
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
            child: const Text(
              "ANNULER",
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteTeacher(teacher['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_rounded,
              size: 80,
              color: const Color(0xFF6366F1).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun enseignant trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Commencez par ajouter votre premier professeur.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
