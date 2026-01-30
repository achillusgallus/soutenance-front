import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/students/student_cours.dart';
import 'package:togoschool/pages/students/student_profil.dart';
import 'package:togoschool/services/api_service.dart';
import 'package:togoschool/services/progress_service.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/models/advertisement.dart';
import 'package:togoschool/services/advertisement_service.dart';
import 'package:togoschool/services/student_feature_service.dart';

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
  int quizCount = 0;
  int forumCount = 0;
  int favoriteCount = 0;
  List<Advertisement> advertisements = [];
  int _currentAdIndex = 0;
  final AdvertisementService _adService = AdvertisementService();
  final StudentFeatureService _featureService = StudentFeatureService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? discoveryResource;
  List<dynamic> leaderboard = [];
  List<dynamic> eduNews = [];

  @override
  void initState() {
    super.initState();
    studentMatieres();
    _loadFavorites();
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
            forumCount = forumsRes.length;
          } else if (forumsRes is Map && forumsRes.containsKey('data')) {
            forumCount = (forumsRes['data'] as List).length;
          }

          isLoading = false;
        });
      }

      // 3. New Features (non-blocking)
      _loadAds();
      _loadExtraFeatures();
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
                          _buildAdsSection(),
                          const SizedBox(height: 24),
                          _buildDiscoveryCard(),
                          const SizedBox(height: 32),
                          _buildLeaderboard(),
                          const SizedBox(height: 32),
                          _buildSearchBar(),
                          const SizedBox(height: 32),
                          _buildSectionHeader(
                            "Mes Matières",
                            filteredMatieres.length,
                          ),
                          const SizedBox(height: 16),
                          _buildMatieresList(),
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
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bienvenue sur togoschool,",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (studentClasse.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Classe : $studentClasse",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
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
        const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.circular(24),
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
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return _buildMatiereCard(filteredMatieres[index], index);
      },
    );
  }

  Widget _buildMatiereCard(dynamic matiere, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.05 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FontAwesomeIcons.bookOpen,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  matiere['nom'] ?? '...',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : color.withOpacity(0.9),
                  ),
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
}
