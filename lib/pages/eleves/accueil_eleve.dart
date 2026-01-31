import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/eleves/cours_eleve.dart';
import 'package:togoschool/pages/eleves/profil_eleve.dart';
import 'package:togoschool/pages/common/page_notifications.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/services/service_progres.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/models/advertisement.dart';
import 'package:togoschool/services/advertisement_service.dart';
import 'package:togoschool/services/student_feature_service.dart';
import 'package:togoschool/pages/forum/forum_topic_list_page.dart';

class StudentAcceuil extends StatefulWidget {
  final VoidCallback? toggleTheme;
  const StudentAcceuil({super.key, this.toggleTheme});

  @override
  State<StudentAcceuil> createState() => _StudentAcceuilState();
}

class _StudentAcceuilState extends State<StudentAcceuil> {
  final api = ApiService();
  final ProgressService _progressService = ProgressService();
  bool isLoading = true;
  String studentName = "Étudiant";
  String studentClasse = "";
  List<dynamic> matieres = [];
  List<dynamic> filteredMatieres = [];
  List<dynamic> forums = [];
  int quizCount = 0;
  int favoriteCount = 0;
  List<Advertisement> advertisements = [];
  int _currentAdIndex = 0;
  final AdvertisementService _adService = AdvertisementService();
  final StudentFeatureService _featureService = StudentFeatureService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? discoveryResource;
  List<dynamic> leaderboard = [];
  List<dynamic> eduNews = [];
  int unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    studentMatieres();
    _loadFavorites();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMatieres(String query) {
    if (query.isEmpty) {
      setState(() => filteredMatieres = matieres);
      return;
    }
    final safeQuery = SecurityUtils.sanitizeInput(query).toLowerCase();
    setState(() {
      filteredMatieres = matieres.where((m) {
        final nom = (m['nom'] ?? '').toString().toLowerCase();
        final desc = (m['description'] ?? '').toString().toLowerCase();
        return nom.contains(safeQuery) || desc.contains(safeQuery);
      }).toList();
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _progressService.getFavorites();
      if (mounted) {
        setState(() {
          favoriteCount = favorites.length;
        });
      }
    } catch (e) {
      // En cas d'erreur, on garde 0
      if (mounted) {
        setState(() {
          favoriteCount = 0;
        });
      }
    }
  }

  Future<void> studentMatieres() async {
    setState(() => isLoading = true);
    try {
      // 1. Infos user
      final userResponse = await api.read("/me");
      if (userResponse?.data != null) {
        final userData = userResponse!.data is Map
            ? userResponse.data
            : userResponse.data['user'];
        // Adjust depending on API response structure
        setState(() {
          studentName = userData is Map
              ? (userData['name'] ?? "Étudiant")
              : "Étudiant";
          studentClasse = userData is Map ? (userData['classe'] ?? "") : "";
        });
      }

      // 2. Data
      final results = await Future.wait([
        api.read("/student/matieres"),
        api.read("/quiz"),
        api.read("/forums"),
      ]);

      if (mounted) {
        setState(() {
          // Matières
          final matieresRes = results[0]?.data;
          if (matieresRes is Map && matieresRes.containsKey('data')) {
            matieres = matieresRes['data'] ?? [];
          } else if (matieresRes is List) {
            matieres = matieresRes;
          }
          filteredMatieres = matieres;

          // Quiz
          final quizRes = results[1]?.data;
          // Handle potential pagination wrapper
          if (quizRes is Map && quizRes.containsKey('total')) {
            quizCount = quizRes['total'] ?? 0;
          } else if (quizRes is List) {
            quizCount = quizRes.length;
          } else if (quizRes is Map && quizRes.containsKey('data')) {
            quizCount = (quizRes['data'] as List).length;
          }

          // Forums
          final forumsRes = results[2]?.data;
          if (forumsRes is List) {
            forums = forumsRes;
          } else if (forumsRes is Map && forumsRes.containsKey('data')) {
            forums = forumsRes['data'] ?? [];
          }

          isLoading = false;
        });
      }

      // 3. New Features (non-blocking)
      _loadAds();
      _loadExtraFeatures();
      _loadUnreadNotifications();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Erreur Accueil: $e");
    }
  }

  Future<void> _loadExtraFeatures() async {
    try {
      final results = await Future.wait([
        _featureService.getDiscoveryResource(),
        _featureService.getLeaderboard(),
        _featureService.getEducationalNews(),
      ]);

      if (mounted) {
        setState(() {
          discoveryResource = results[0] as Map<String, dynamic>?;
          leaderboard = results[1] as List<dynamic>;
          eduNews = results[2] as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint("Erreur Extra Features: $e");
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final res = await api.read("/notifications");
      if (mounted && res?.data != null) {
        final data = res!.data;
        List<dynamic> notifs = [];
        if (data is Map && data.containsKey('data')) {
          notifs = data['data'];
        } else if (data is List) {
          notifs = data;
        }

        setState(() {
          unreadNotifCount = notifs
              .where(
                (n) =>
                    n['read'] == false || n['read'] == 0 || n['read'] == null,
              )
              .length;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifs: $e");
    }
  }

  Future<void> _loadAds() async {
    try {
      final ads = await _adService.getAdvertisements();
      if (mounted) {
        setState(() {
          advertisements = ads;
        });
      }
    } catch (e) {
      debugPrint("Erreur Ads: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              onRefresh: studentMatieres,
              color: theme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildAdsSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            "Mes Matières",
                            filteredMatieres.length,
                          ),
                          const SizedBox(height: 16),
                          _buildMatieresList(),
                          const SizedBox(height: 32),
                          if (forums.isNotEmpty) ...[
                            _buildSectionHeader(
                              "Forums de Discussion",
                              forums.length,
                            ),
                            const SizedBox(height: 16),
                            _buildForumsSection(),
                            const SizedBox(height: 32),
                          ],
                          _buildDiscoveryCard(),
                          const SizedBox(height: 32),
                          _buildLeaderboard(),
                          const SizedBox(height: 32),
                          _buildEduNewsFeed(),
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bonjour,",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildSearchBar(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
                _loadUnreadNotifications();
              },
            ),
            if (unreadNotifCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (widget.toggleTheme != null)
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: widget.toggleTheme,
          ),
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentProfil()),
          ),
        ),
      ],
    );
  }

  Widget _buildAdsSection() {
    if (advertisements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "À la une",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 80,
          child: PageView.builder(
            itemCount: advertisements.length,
            controller: PageController(viewportFraction: 0.9),
            onPageChanged: (index) => setState(() => _currentAdIndex = index),
            itemBuilder: (context, index) {
              final ad = advertisements[index];
              return AnimatedScale(
                scale: _currentAdIndex == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    image: DecorationImage(
                      image: NetworkImage(ad.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Annonce",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ad.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (ad.description != null)
                          Text(
                            ad.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            advertisements.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentAdIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentAdIndex == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMatieres,
        decoration: InputDecoration(
          hintText: "Rechercher une matière...",
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.iconTheme.color ?? theme.disabledColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$count",
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatieresList() {
    final theme = Theme.of(context);
    if (studentClasse.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              "Classe non définie",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Veuillez choisir votre classe dans votre profil pour voir vos matières et vos forums.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfil()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("COMPLÉTER MON PROFIL"),
            ),
          ],
        ),
      );
    }

    if (filteredMatieres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                FontAwesomeIcons.folderOpen,
                size: 48,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                "Aucune matière trouvée.",
                style: TextStyle(color: theme.hintColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredMatieres.length,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        return _buildMatiereCard(filteredMatieres[index], index);
      },
    );
  }

  Widget _buildMatiereCard(dynamic matiere, int index) {
    final theme = Theme.of(context);

    final List<Color> cardColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFF43F5E), // Rose
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFFEC4899), // Pink
    ];

    // Use ID if available for consistent coloring, else index
    final int colorId = matiere['id'] ?? index;
    final color = cardColors[colorId % cardColors.length];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentCours(
                  matiereId: matiere['id'],
                  matiereName: matiere['nom'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.bookOpen,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  matiere['nom'] ?? '...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        matiere['user_name'] ?? 'Non attribué',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryCard() {
    if (discoveryResource == null) return const SizedBox.shrink();

    final type = discoveryResource!['type'];
    final title = discoveryResource!['title'];
    final content = discoveryResource!['content'];

    IconData icon;
    Color color;
    switch (type) {
      case 'video':
        icon = FontAwesomeIcons.play;
        color = Colors.redAccent;
        break;
      case 'tip':
        icon = FontAwesomeIcons.lightbulb;
        color = Colors.amber;
        break;
      default:
        icon = FontAwesomeIcons.flask;
        color = Colors.blueAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SURPRISE DU JOUR",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (leaderboard.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Leaderboard de la semaine", leaderboard.length),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: List.generate(
              leaderboard.length > 3 ? 3 : leaderboard.length,
              (index) {
                final student = leaderboard[index];
                final pos = index + 1;
                Color rankColor;
                if (pos == 1)
                  rankColor = const Color(0xFFFFD700);
                else if (pos == 2)
                  rankColor = const Color(0xFFC0C0C0);
                else if (pos == 3)
                  rankColor = const Color(0xFFCD7F32);
                else
                  rankColor = theme.hintColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "#$pos",
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          student['name'][0],
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${student['name']} ${student['surname']}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${student['points']} pts",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEduNewsFeed() {
    if (eduNews.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Fil d'actualité éducatif",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: eduNews.length,
            itemBuilder: (context, index) {
              final news = eduNews[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: news['image_url'] != null
                          ? Image.network(
                              news['image_url'],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 100,
                              color: theme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.newspaper,
                                color: theme.primaryColor,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news['matiere_nom']?.toString().toUpperCase() ??
                                "GROS PLAN",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForumsSection() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forums.length,
        itemBuilder: (context, index) {
          final forum = forums[index];
          final color = [
            const Color(0xFF6366F1),
            const Color(0xFFF59E0B),
            const Color(0xFF10B981),
            const Color(0xFFF43F5E),
          ][index % 4];
          final msgCount = forum['messages_count'] ?? 0;

          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForumTopicListPage(
                        forumId: forum['id'],
                        forumTitle: forum['titre'] ?? 'Forum',
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.forum_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            forum['titre'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            forum['matiere']?['nom'] ?? 'Général',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (msgCount > 0)
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$msgCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
