import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: "Mes Élèves",
              onBack:
                  widget.onBack ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            ),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchStudents,
                color: const Color(0xFF6366F1),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un élève...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final color = cardColors[index % cardColors.length];
        return _buildStudentCard(student, color);
      },
    );
  }

  Widget _buildStudentCard(dynamic student, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FontAwesomeIcons.userGraduate,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${student['name'] ?? ''} ${student['surname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      _buildOnlineIndicator(student['is_online'] ?? false),
                    ],
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
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          student['classe'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          student['email'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? "En ligne" : "Hors ligne",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOnline
                  ? const Color(0xFF166534)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Aucun élève trouvé",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Les élèves apparaîtront ici une fois qu'ils ont des cours avec vous.",
                style: TextStyle(color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
