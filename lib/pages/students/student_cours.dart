import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/service/download_service.dart';
import 'package:togoschool/service/paygate_service.dart';
import 'package:togoschool/pages/students/payment_required_page.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

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
  int? _remainingDownloads;
  bool _hasPaid = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _loadDownloadInfo();
  }

  Future<void> _loadDownloadInfo() async {
    final paygateService = PaygateService();
    final hasPaid = await paygateService.hasPaid();
    final remaining = await DownloadService.getRemainingDownloads();

    if (mounted) {
      setState(() {
        _hasPaid = hasPaid;
        _remainingDownloads = remaining;
      });
    }
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
              color1: const Color(0xFF6366F1),
              color2: const Color(0xFF4F46E5),
              title: headerTitle,
              subtitle: widget.matiereId != null
                  ? 'Contenu de votre formation'
                  : 'Accédez à votre bibliothèque',
              title1: courses.length.toString(),
              subtitle1: 'Cours',
              title2: coursesBySubject.length.toString(),
              subtitle2: 'Matières',
              title3: _hasPaid ? '∞' : (_remainingDownloads?.toString() ?? '3'),
              subtitle3: _hasPaid ? 'Illimité' : 'Téléchargements',
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchCourses,
                color: const Color(0xFF6366F1),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FontAwesomeIcons.tag,
                  color: Color(0xFF6366F1),
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                matiereName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...subjectCourses.map((course) => _buildCourseCard(course)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final hasFile = course['fichier'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCourseDetail(course),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    hasFile
                        ? Icons.file_present_rounded
                        : Icons.article_rounded,
                    color: const Color(0xFF64748B),
                    size: 24,
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
                      Text(
                        course['professeur']?['name'] ?? 'Professeur',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFile)
                  const Icon(
                    Icons.attachment_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              widget.matiereId != null
                  ? "Aucun cours disponible pour cette matière"
                  : "Aucun cours disponible pour le moment",
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['titre'] ?? 'Sans titre',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course['professeur']?['name'] ?? 'Professeur',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['matiere']?['nom'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF1F5F9)),
              ),
              const Text(
                "Description du cours",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
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
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (course['fichier'] != null) _buildFileAction(course),
                      const SizedBox(height: 20),
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

  Future<void> _downloadAndOpenFile(String fileUrl, String fileName) async {
    // Vérifier si l'utilisateur peut télécharger gratuitement
    final paygateService = PaygateService();
    final canDownload = await DownloadService.canDownloadFree();
    final hasPaid = await paygateService.hasPaid();

    // Si limite atteinte et pas de paiement, demander le paiement
    if (!canDownload && !hasPaid) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentRequiredPage(reason: 'download'),
        ),
      );

      // Si paiement effectué, continuer le téléchargement
      if (result != true) {
        // L'utilisateur a annulé ou le paiement a échoué
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous devez payer pour télécharger plus de cours"),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Re-vérifier après paiement
      final canDownloadNow = await DownloadService.canDownloadFree();
      final hasPaidNow = await paygateService.hasPaid();
      if (!canDownloadNow && !hasPaidNow) {
        return;
      }
    }

    final fullUrl = ApiService.resolveFileUrl(fileUrl);
    if (fullUrl == null) return;

    try {
      if (kIsWeb) {
        final Uri uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Impossible d\'ouvrir le lien : $fullUrl';
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFF6366F1),
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "Préparation de $fileName...",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );

      bool openedLocally = false;
      try {
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/$fileName";

        // Download file with a specific timeout to handle unstable connections
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ).download(fullUrl, filePath);

        // Try to open the local file
        final result = await OpenFilex.open(filePath);
        if (result.type == ResultType.done) {
          openedLocally = true;
          // Incrémenter le compteur de téléchargements seulement si le fichier a été ouvert avec succès
          final paygateService = PaygateService();
          final hasPaid = await paygateService.hasPaid();
          if (!hasPaid) {
            await DownloadService.incrementDownloadCount();
          }
        } else {
          print("DEBUG - OpenFilex error: ${result.message}");
        }
      } catch (downloadError) {
        print(
          "DEBUG - Download failed, attempting browser fallback: $downloadError",
        );
      }

      // Fallback: If local opening failed or download errored, try browser
      if (!openedLocally) {
        final Uri uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          // Incrémenter aussi pour les téléchargements via navigateur
          final paygateService = PaygateService();
          final hasPaid = await paygateService.hasPaid();
          if (!hasPaid) {
            await DownloadService.incrementDownloadCount();
            await _loadDownloadInfo(); // Recharger les infos
          }
        } else {
          throw 'Échec du téléchargement et impossible d\'ouvrir dans le navigateur.';
        }
      } else {
        // Recharger les infos après téléchargement réussi
        await _loadDownloadInfo();
      }
    } catch (e) {
      if (mounted) {
        print("DEBUG - File error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'ouverture : $e"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildFileAction(dynamic course) {
    if (course['fichier'] == null) return const SizedBox.shrink();

    final fileName = course['fichier']?.split('/').last ?? 'Fichier';
    final fileType = course['fichier_type'] ?? '';
    final isVideo = fileType.contains('video');
    final String fileUrl = course['fichier'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.play_circle_fill : Icons.picture_as_pdf_rounded,
              color: isVideo
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFEF4444),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  isVideo ? 'Vidéo de cours' : 'Support PDF',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _downloadAndOpenFile(fileUrl, fileName),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isVideo ? 'Lire' : 'Ouvrir'),
          ),
        ],
      ),
    );
  }
}
