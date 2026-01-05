import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
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
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  Future<void> _deleteCourse(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce cours ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await api.delete("/professeur/cours/$id");
        _loadData(); // Refresh list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec de la suppression: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          FormHeader(
            title: widget.filterSubjectName != null
                ? "Cours - ${widget.filterSubjectName}"
                : "Gestion des Cours",
            onBack: Navigator.canPop(context)
                ? () => Navigator.pop(context)
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
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
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau Cours"),
      ),
    );
  }

  Widget _buildGroupedCourseList() {
    // Filter subjects if a filter ID is provided
    final displaySubjects = widget.filterSubjectId != null
        ? subjects.where((s) => s['id'] == widget.filterSubjectId).toList()
        : subjects;

    if (displaySubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              widget.filterSubjectId != null
                  ? "Cette matière n'a pas été trouvée"
                  : "Aucune matière affectée",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: displaySubjects.length,
      itemBuilder: (context, index) {
        final subject = displaySubjects[index];
        final subjectCourses = courses.where((c) {
          // Verify both int and string IDs just in case
          return c['matiere_id'].toString() == subject['id'].toString();
        }).toList();

        return _buildSubjectCard(subject, subjectCourses);
      },
    );
  }

  Widget _buildSubjectCard(dynamic subject, List<dynamic> subjectCourses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.book, color: Colors.blueAccent),
          ),
          title: Text(
            subject['nom'] ?? 'Sans nom',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          subtitle: Text(
            "${subjectCourses.length} cours publié(s)",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          children: [
            const Divider(height: 1),
            if (subjectCourses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    "Aucun cours pour cette matière",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...subjectCourses.map((c) => _buildCourseItem(c)).toList(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(dynamic course) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        course['titre'] ?? 'Sans titre',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          course['contenu'] ?? course['description'] ?? 'Pas de contenu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ),
      trailing: PopupMenuButton<String>(
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
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text("Modifier"),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text("Supprimer", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        // Optional: show detail page
      },
    );
  }
}
