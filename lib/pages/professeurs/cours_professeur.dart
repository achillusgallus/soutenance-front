import 'package:flutter/material.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/professeurs/page_ajout_cours.dart';
import 'package:togoschool/services/service_api.dart';

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
    final theme = Theme.of(context);
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
            child: Text(
              "ANNULER",
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "SUPPRIMER",
              style: TextStyle(
                color: theme.colorScheme.error,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          DashHeader(
            color1: theme.primaryColor,
            color2: theme.primaryColorDark,
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
              color: theme.primaryColor,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    )
                  : _buildGroupedCourseList(theme),
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
        backgroundColor: theme.primaryColor,
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

  Widget _buildGroupedCourseList(ThemeData theme) {
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
                color: theme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 80,
                color: theme.primaryColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.filterSubjectId != null
                  ? "Matière non trouvée"
                  : "Aucune matière affectée",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
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
        return _buildSubjectCard(subject, subjectCourses, theme);
      },
    );
  }

  Widget _buildSubjectCard(
    dynamic subject,
    List<dynamic> subjectCourses,
    ThemeData theme,
  ) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: theme.cardColor,
            collapsedBackgroundColor: theme.cardColor,
            iconColor: theme.primaryColor,
            collapsedIconColor: theme.unselectedWidgetColor,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.book_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              subject['nom'] ?? 'Sans nom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              "${subjectCourses.length} cours publié(s)",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
            children: [
              Container(
                height: 1,
                color: theme.dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              if (subjectCourses.isEmpty)
                padding_placeholder(theme)
              else
                ...subjectCourses
                    .map((c) => _buildCourseItem(c, theme))
                    .toList(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget padding_placeholder(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        "Aucun cours disponible",
        style: TextStyle(
          color: theme.disabledColor,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCourseItem(dynamic course, ThemeData theme) {
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
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: theme.iconTheme.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['titre'] ?? 'Sans titre',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course['contenu'] ??
                          course['description'] ??
                          'Pas de contenu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCourseActions(course, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseActions(dynamic course, ThemeData theme) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: theme.disabledColor, size: 20),
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
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 12),
              Text(
                "Supprimer",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
