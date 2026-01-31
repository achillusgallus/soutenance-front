import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/services/service_telechargement.dart';
import 'package:togoschool/services/service_paygate.dart';
import 'package:togoschool/services/service_progres.dart';
import 'package:togoschool/pages/eleves/page_paiement_requis.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:togoschool/pages/common/video_player_page.dart';
import 'package:togoschool/pages/common/pdf_viewer_page.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class StudentCours extends StatefulWidget {
  final int? matiereId; // Optional: filter by specific subject
  final String? matiereName; // Optional: show subject name in header

  const StudentCours({super.key, this.matiereId, this.matiereName});

  @override
  State<StudentCours> createState() => _StudentCoursState();
}

class _StudentCoursState extends State<StudentCours> {
  final api = ApiService();
  final ProgressService _progressService = ProgressService();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  List<dynamic> courses = [];
  Map<String, List<dynamic>> coursesBySubject = {};
  Set<int> _favoriteCourseIds = {};
  int? _remainingDownloads;
  bool _hasPaid = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _loadDownloadInfo();
    _loadFavorites();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        !isLoading &&
        currentPage < lastPage) {
      _loadMoreCourses();
    }
  }

  Future<void> _loadMoreCourses() async {
    if (mounted) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
      await _fetchCourses();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _progressService.getFavorites();
      if (mounted) {
        setState(() {
          _favoriteCourseIds = favorites
              .map<int>((fav) => fav['id'] ?? 0)
              .toSet();
        });
      }
    } catch (e) {
      // En cas d'erreur, on continue avec une liste vide
    }
  }

  Future<void> _loadDownloadInfo() async {
    final paygateService = PaygateService();
    final status = await paygateService.getAccessStatus();

    if (mounted) {
      setState(() {
        if (status != null) {
          _hasPaid = status['hasPaid'] ?? false;
          _remainingDownloads = status['remainingDownloads'] ?? 0;
        } else {
          // Fallback local si serveur injoignable
          _loadDownloadInfoLocal();
        }
      });
    }
  }

  Future<void> _loadDownloadInfoLocal() async {
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
    if (courses.isEmpty) {
      setState(() => isLoading = true);
    }
    try {
      String endpoint = "/cours?page=$currentPage";
      if (widget.matiereId != null) {
        endpoint += "&matiere_id=${widget.matiereId}";
      }

      final res = await api.read(endpoint);
      if (mounted) {
        final data = res?.data;
        List<dynamic> fetchedCourses = [];

        if (data is Map && data.containsKey('data')) {
          final rawData = data['data'];
          if (rawData is List) {
            fetchedCourses = rawData;
          } else if (rawData is Map) {
            // Laravel peut parfois retourner un objet associatif au lieu d'un tableau
            fetchedCourses = rawData.values.toList();
          }
          lastPage = data['last_page'] ?? 1;
        } else if (data is List) {
          fetchedCourses = data;
        } else if (data is Map) {
          fetchedCourses = data.values.toList();
        }

        print("DEBUG - Courses fetched count: ${fetchedCourses.length}");
        if (widget.matiereId != null) {
          print("DEBUG - Filtered by matiere_id: ${widget.matiereId}");
        }

        List<dynamic> paramCourses;
        if (currentPage == 1) {
          paramCourses = List.from(fetchedCourses);
        } else {
          paramCourses = [...courses, ...fetchedCourses];
        }

        // Group courses by subject
        Map<String, List<dynamic>> grouped = {};
        for (var item in paramCourses) {
          if (item is! Map) continue;

          final Map course = item;
          final matiere = course['matiere'];
          String matiereName = 'Sans matière';

          if (matiere is Map && matiere.containsKey('nom')) {
            matiereName = matiere['nom']?.toString() ?? 'Sans matière';
          }

          if (!grouped.containsKey(matiereName)) {
            grouped[matiereName] = [];
          }
          grouped[matiereName]!.add(course);
        }

        setState(() {
          courses = paramCourses;
          coursesBySubject = grouped;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        print("DEBUG - Error in _fetchCourses: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.matiereName ?? "Mes Cours";
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DashHeader(
              color1: theme.primaryColor,
              color2: theme.primaryColorDark,
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
                onRefresh: () async {
                  setState(() {
                    currentPage = 1;
                    courses = [];
                  });
                  await _fetchCourses();
                },
                color: theme.primaryColor,
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: coursesBySubject.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == coursesBySubject.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.tag,
                  color: Theme.of(context).primaryColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                matiereName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
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
    final theme = Theme.of(context);
    final hasFile = course['fichier'] != null;
    final courseId = course['id'] ?? 0;
    final isFavorite = _favoriteCourseIds.contains(courseId);

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
          child: Stack(
            children: [
              Padding(
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
                      Icon(
                        Icons.attachment_rounded,
                        size: 18,
                        color: AppTheme.successColor,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.dividerColor,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () async {
                    final success = await _progressService.toggleFavorite(
                      courseId,
                    );
                    if (success && mounted) {
                      setState(() {
                        if (isFavorite) {
                          _favoriteCourseIds.remove(courseId);
                        } else {
                          _favoriteCourseIds.add(courseId);
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              widget.matiereId != null
                  ? "Aucun cours disponible pour cette matière"
                  : "Aucun cours disponible pour le moment",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDetail(dynamic course) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: theme.dividerColor,
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
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course['professeur']?['name'] ?? 'Professeur',
                              style: theme.textTheme.bodySmall?.copyWith(
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
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['matiere']?['nom'] ?? '',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: theme.dividerColor),
              ),
              Text(
                "Description du cours",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.6,
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

  Future<bool?> _requestPayment(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentRequiredPage(reason: 'download'),
      ),
    );

    if (result != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Vous devez payer pour télécharger plus de cours",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _downloadAndOpenFile(
    String fileUrl,
    String fileName,
    int courseId,
  ) async {
    try {
      // 1. Vérifier si l'utilisateur peut télécharger (Priorité serveur)
      final paygateService = PaygateService();
      final status = await paygateService.getAccessStatus();

      bool canDownload =
          status?['canDownloadFree'] ?? await DownloadService.canDownloadFree();
      bool hasPaid = status?['hasPaid'] ?? await paygateService.hasPaid();

      // Si limite atteinte et pas de paiement, demander le paiement
      if (!canDownload && !hasPaid) {
        final result = await _requestPayment(context);
        if (result != true) return;
        await _loadDownloadInfo();
      }

      // 2. URL complète récupérée
      String? fullUrl;
      try {
        // Extraire uniquement le chemin relatif si c'est une URL complète (ex: via storage/...)
        String relativePath = fileUrl;
        if (fileUrl.contains('/storage/')) {
          relativePath = fileUrl.split('/storage/').last;
        } else if (fileUrl.startsWith('http')) {
          // Si c'est une URL complète mais sans /storage/, on essaie de prendre la fin
          relativePath = fileUrl.split('/').last;
        }

        print("DEBUG - Initial fileUrl: $fileUrl");
        print("DEBUG - Normalized relativePath: $relativePath");

        fullUrl = await api.getFileUrl(relativePath);
        if (fullUrl != null) {
          fullUrl = fullUrl.replaceFirst('http://', 'https://');
        }
        print("DEBUG - Received fullUrl from API: $fullUrl");
      } catch (e) {
        // Si le serveur renvoie 403 alors qu'on pensait avoir accès (ex: décalage cache)
        if (e.toString().contains("403")) {
          final result = await _requestPayment(context);
          if (result == true) {
            await _loadDownloadInfo();
            fullUrl = await api.getFileUrl(fileUrl);
          } else {
            return;
          }
        } else {
          rethrow;
        }
      }

      if (fullUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lien invalide"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Synchroniser les infos de téléchargement
      await _loadDownloadInfo();

      // --- LOGIQUE D'OUVERTURE ---

      // 1. Vidéos
      if (fileName.toLowerCase().endsWith('.mp4') ||
          fileName.toLowerCase().endsWith('.mov')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerPage(
              videoUrl: fullUrl!,
              title: fileName,
              courseId: courseId,
            ),
          ),
        );
        return;
      }

      // 2. PDFs
      if (fileName.toLowerCase().endsWith('.pdf')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(
              pdfUrl: fullUrl!,
              title: fileName,
              courseId: courseId,
            ),
          ),
        );
        return;
      }

      // 3. Autres (Open externally)
      final Uri uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impossible d'ouvrir le fichier")),
          );
        }
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
            onPressed: () =>
                _downloadAndOpenFile(fileUrl, fileName, course['id'] ?? 0),
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
