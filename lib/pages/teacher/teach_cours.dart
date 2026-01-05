import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/teacher/add_course_page.dart';
import 'package:togoschool/service/api_service.dart';

class TeachCours extends StatefulWidget {
  final int? filterSubjectId;
  final String? filterSubjectName;

  const TeachCours({super.key, this.filterSubjectId, this.filterSubjectName});

  @override
  State<TeachCours> createState() => _TeachCoursState();
}

class _TeachCoursState extends State<TeachCours> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> courses = [];
  List<dynamic> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        api.read("/professeur/matieres"),
        api.read("/professeur/cours"),
      ]);

      if (mounted) {
        setState(() {
          subjects = results[0]?.data ?? [];
          courses = results[1]?.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  Future<void> _deleteCourse(int id) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm == true) {
      try {
        await api.delete("/professeur/cours/$id");
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Échec: $e")));
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Supprimer le cours ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "ANNULER",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
            title: (widget.filterSubjectName ?? "GESTION DES COURS")
                .toUpperCase(),
            subtitle: 'Organisez et publiez vos supports pédagogiques',
            title1: courses.length.toString(),
            subtitle1: 'Cours',
            title2: subjects.length.toString(),
            subtitle2: 'Matières',
            title3: "",
            subtitle3: "",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF6366F1),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : _buildGroupedCourseList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCoursePage(
                subjects: subjects,
                initialSubjectId: widget.filterSubjectId,
              ),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "NOUVEAU COURS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildGroupedCourseList() {
    final displaySubjects = widget.filterSubjectId != null
        ? subjects.where((s) => s['id'] == widget.filterSubjectId).toList()
        : subjects;

    if (displaySubjects.isEmpty) {
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
                Icons.school_outlined,
                size: 80,
                color: const Color(0xFF6366F1).withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.filterSubjectId != null
                  ? "Matière non trouvée"
                  : "Aucune matière affectée",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: displaySubjects.length,
      itemBuilder: (context, index) {
        final subject = displaySubjects[index];
        final subjectCourses = courses
            .where(
              (c) => c['matiere_id'].toString() == subject['id'].toString(),
            )
            .toList();
        return _buildSubjectCard(subject, subjectCourses);
      },
    );
  }

  Widget _buildSubjectCard(dynamic subject, List<dynamic> subjectCourses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            iconColor: const Color(0xFF6366F1),
            collapsedIconColor: const Color(0xFF94A3B8),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.book_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            title: Text(
              subject['nom'] ?? 'Sans nom',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              "${subjectCourses.length} cours publié(s)",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            children: [
              Container(
                height: 1,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              if (subjectCourses.isEmpty)
                padding_placeholder()
              else
                ...subjectCourses.map((c) => _buildCourseItem(c)).toList(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget padding_placeholder() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        "Aucun cours disponible",
        style: TextStyle(
          color: Colors.grey[400],
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCourseItem(dynamic course) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['titre'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course['contenu'] ??
                          course['description'] ??
                          'Pas de contenu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCourseActions(course),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseActions(dynamic course) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Color(0xFFCBD5E1),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) async {
        if (val == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddCoursePage(course: course, subjects: subjects),
            ),
          );
          if (result == true) _loadData();
        } else if (val == 'delete') {
          _deleteCourse(course['id']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 12),
              Text("Modifier"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text("Supprimer", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
