import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/admin/add_student.dart';
import 'package:togoschool/service/api_service.dart';

class AdminStudentPage extends StatefulWidget {
  const AdminStudentPage({super.key});

  @override
  State<AdminStudentPage> createState() => _AdminStudentPageState();
}

class _AdminStudentPageState extends State<AdminStudentPage> {
  final api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  final List<Color> cardColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
  ];

  bool isLoading = true;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    getTeachers();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students.where((student) {
          final name = (student['name'] ?? '').toLowerCase();
          final surname = (student['surname'] ?? '').toLowerCase();
          final email = (student['email'] ?? '').toLowerCase();
          return name.contains(query) ||
              surname.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await api.read("/admin/users");
      setState(() {
        final List<dynamic> allUsers = response?.data ?? [];
        students = allUsers.where((user) => user['role_id'] == 3).toList();
        filteredStudents = students;
        isLoading = false;
      });
      return students;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      return [];
    }
  }

  Future<void> _confirmDelete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirmation'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'élève "$name" ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteStudent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Élève supprimé avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await api.delete("/admin/users/$id");
      setState(() {
        students.removeWhere((student) => student['id'] == id);
        _filterStudents();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Erreur lors de la suppression'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> updateStudent(dynamic student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddStudent(Student: student)),
    );

    if (result == true) {
      getTeachers();
    }
  }

  Future<void> _addNewStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddStudent()),
    );

    if (result == true) {
      getTeachers();
    }
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
            title: "GESTION ÉLÈVES",
            subtitle: "Supervisez et gérez l'ensemble des étudiants",
            title1: students.length.toString(),
            subtitle1: "Élèves",
            title2: "",
            subtitle2: "",
            title3: "",
            subtitle3: "",
            onBack: () => Navigator.pop(context),
          ),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: getTeachers,
              color: const Color(0xFF6366F1),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : filteredStudents.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStudent,
        backgroundColor: const Color(0xFF10B981),
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          "NOUVEL ÉLÈVE",
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un élève...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6366F1),
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final color = cardColors[index % cardColors.length];

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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.school_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${student['name'] ?? ''} ${student['surname'] ?? ''}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              student['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStudentActions(student),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentActions(dynamic student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => updateStudent(student),
          icon: const Icon(
            Icons.edit_rounded,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _confirmDelete(
            student['id'],
            "${student['name']} ${student['surname']}",
          ),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
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
              _searchController.text.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.person_off_rounded,
              size: 80,
              color: const Color(0xFF6366F1).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? "Aucun résultat trouvé"
                : "Aucun élève trouvé",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? "Essayez une autre recherche."
                : "Commencez par ajouter votre premier élève.",
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
