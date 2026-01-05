import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TeacherEleves extends StatefulWidget {
  final VoidCallback? onBack;
  const TeacherEleves({super.key, this.onBack});

  @override
  State<TeacherEleves> createState() => _TeacherElevesState();
}

class _TeacherElevesState extends State<TeacherEleves> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Color> cardColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF59E0B), // Amber
  ];

  @override
  void initState() {
    super.initState();
    fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);
    try {
      // Fetch students for the current teacher
      // Using /professeur/eleves as per the project's API pattern
      final response = await api.read("/professeur/eleves");
      if (response != null && response.statusCode == 200) {
        setState(() {
          students = response.data;
          filteredStudents = students;
          isLoading = false;
        });
      } else {
        setState(() {
          students = [];
          filteredStudents = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des élèves: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
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
          final classe = (student['classe'] ?? '').toLowerCase();
          return name.contains(query) ||
              surname.contains(query) ||
              email.contains(query) ||
              classe.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = students
        .where((s) => s['is_online'] == true || s['is_online'] == 1)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          DashHeader(
            color1: const Color(0xFF6366F1),
            color2: const Color(0xFF4F46E5),
            title: "MES ÉLÈVES",
            subtitle: "Suivez l'activité et le statut de vos étudiants",
            title1: students.length.toString(),
            subtitle1: "Total",
            title2: onlineCount.toString(),
            subtitle2: "En Ligne",
            title3: "",
            subtitle3: "",
            onBack: widget.onBack ?? () => Navigator.pop(context),
          ),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchStudents,
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
            hintText: 'Rechercher par nom, classe, email...',
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return _buildStudentCard(student, index);
      },
    );
  }

  Widget _buildStudentCard(dynamic student, int index) {
    final bool isOnline =
        student['is_online'] == true || student['is_online'] == 1;
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
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    FontAwesomeIcons.userGraduate,
                    color: color,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student['name'] ?? ''} ${student['surname'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student['classe'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF10B981).withOpacity(0.08)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnline ? "ACTIF" : "OFFLINE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isOnline
                      ? const Color(0xFF059669)
                      : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
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
              Icons.people_outline_rounded,
              size: 80,
              color: const Color(0xFF6366F1).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun élève trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Les élèves apparaîtront ici une fois qu'ils ont des cours avec vous.",
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
