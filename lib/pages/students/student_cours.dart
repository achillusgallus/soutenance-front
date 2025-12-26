import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';

class StudentCours extends StatefulWidget {
  final int? matiereId; // Optional: filter by specific subject
  final String? matiereName; // Optional: show subject name in header

  const StudentCours({super.key, this.matiereId, this.matiereName});

  @override
  State<StudentCours> createState() => _StudentCoursState();
}

class _StudentCoursState extends State<StudentCours> {
  final api = ApiService();
  bool isLoading = true;
  List<dynamic> courses = [];
  Map<String, List<dynamic>> coursesBySubject = {};

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => isLoading = true);
    try {
      // Build the endpoint with optional matiere_id parameter
      String endpoint = "/cours";
      if (widget.matiereId != null) {
        endpoint = "/cours?matiere_id=${widget.matiereId}";
      }

      final res = await api.read(endpoint);
      if (mounted) {
        List<dynamic> fetchedCourses = res?.data ?? [];

        print("DEBUG - Courses fetched: ${fetchedCourses.length}");
        if (widget.matiereId != null) {
          print("DEBUG - Filtered by matiere_id: ${widget.matiereId}");
        }

        // Group courses by subject
        Map<String, List<dynamic>> grouped = {};
        for (var course in fetchedCourses) {
          final matiere = course['matiere'];
          final matiereName = matiere?['nom'] ?? 'Sans matière';

          if (!grouped.containsKey(matiereName)) {
            grouped[matiereName] = [];
          }
          grouped[matiereName]!.add(course);
        }

        setState(() {
          courses = fetchedCourses;
          coursesBySubject = grouped;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        print("DEBUG - Error fetching courses: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.matiereName ?? "Mes Cours";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: const Color(0xFF3B82F6),
              color2: const Color(0xFF2563EB),
              title: headerTitle,
              subtitle: widget.matiereId != null
                  ? 'Cours de cette matière'
                  : 'Accédez à vos supports de cours',
              title1: courses.length.toString(),
              subtitle1: 'Cours',
              title2: coursesBySubject.length.toString(),
              subtitle2: 'Matières',
              title3: '',
              subtitle3: '',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchCourses,
                color: const Color(0xFF3B82F6),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : courses.isEmpty
                    ? _buildEmptyState()
                    : _buildCoursesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: coursesBySubject.length,
      itemBuilder: (context, index) {
        final matiereName = coursesBySubject.keys.elementAt(index);
        final subjectCourses = coursesBySubject[matiereName]!;

        return _buildSubjectSection(matiereName, subjectCourses);
      },
    );
  }

  Widget _buildSubjectSection(
    String matiereName,
    List<dynamic> subjectCourses,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.book,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    matiereName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${subjectCourses.length}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Courses list
          ...subjectCourses.map((course) => _buildCourseCard(course)).toList(),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final hasFile = course['fichier'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCourseDetail(course),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasFile ? Icons.description : Icons.description_outlined,
                    color: Colors.blueAccent,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course['professeur']?['name'] ?? 'Professeur',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasFile)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            widget.matiereId != null
                ? "Aucun cours disponible pour cette matière"
                : "Aucun cours disponible pour le moment",
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCourseDetail(dynamic course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                course['titre'] ?? 'Sans titre',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['matiere']?['nom'] ?? '',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    course['professeur']?['name'] ?? 'Professeur',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Contenu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['contenu'] ?? 'Pas de description.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (course['fichier'] != null) _buildFileAction(course),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAction(dynamic course) {
    final fileName = course['fichier']?.split('/').last ?? 'Fichier';
    final fileType = course['fichier_type'] ?? '';
    final isVideo = fileType.contains('video');
    final isPdf = fileType.contains('pdf');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isVideo
                          ? 'Vidéo'
                          : isPdf
                          ? 'Document PDF'
                          : 'Fichier',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement file viewing/download
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Fonctionnalité de visualisation à venir"),
                    ),
                  );
                },
                icon: Icon(
                  isVideo ? Icons.play_arrow : Icons.visibility,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
