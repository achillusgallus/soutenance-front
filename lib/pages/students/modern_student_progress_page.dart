import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:togoschool/widgets/modern_components.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/services/progress_service.dart';

// Simple data models for this page
class ProgressModel {
  final int completedCourses;
  final int totalCourses;
  final int totalQuizzes;
  final double averageScore;
  final int totalTimeSpent;
  final Map<String, int> weeklyActivity;

  ProgressModel({
    required this.completedCourses,
    required this.totalCourses,
    required this.totalQuizzes,
    required this.averageScore,
    required this.totalTimeSpent,
    required this.weeklyActivity,
  });

  double get completionPercentage =>
      totalCourses > 0 ? (completedCourses / totalCourses) * 100 : 0.0;

  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}

class CourseProgress {
  final int id;
  final String courseName;
  final int progress;
  final String? lastAccessed;
  final int timeSpent;

  CourseProgress({
    required this.id,
    required this.courseName,
    required this.progress,
    this.lastAccessed,
    required this.timeSpent,
  });

  String get formattedTimeSpent {
    final hours = timeSpent ~/ 3600;
    final minutes = (timeSpent % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  DateTime? get lastAccessedDateTime {
    if (lastAccessed == null) return null;
    try {
      return DateTime.parse(lastAccessed!);
    } catch (e) {
      return null;
    }
  }
}

class ModernStudentProgressPage extends StatefulWidget {
  const ModernStudentProgressPage({super.key});

  @override
  State<ModernStudentProgressPage> createState() =>
      _ModernStudentProgressPageState();
}

class _ModernStudentProgressPageState extends State<ModernStudentProgressPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  ProgressModel? _progressData;
  List<CourseProgress>? _recentCourses;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _loadData();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ProgressService progressService = ProgressService();

      // Charger les stats et la progression
      final results = await Future.wait([
        progressService.getStats(),
        progressService.getProgressFromServer(),
      ]);

      final statsData = results[0] as Map<String, dynamic>?;
      final progData = results[1] as List<dynamic>?;

      if (mounted) {
        setState(() {
          if (statsData != null) {
            // Mappage de l'activité hebdomadaire
            Map<String, int> mappedActivity = {
              'Lundi': 0,
              'Mardi': 0,
              'Mercredi': 0,
              'Jeudi': 0,
              'Vendredi': 0,
              'Samedi': 0,
              'Dimanche': 0,
            };

            final rawActivity =
                statsData['weekly_activity'] as Map<String, dynamic>? ?? {};
            final daysMap = {
              1: 'Lundi',
              2: 'Mardi',
              3: 'Mercredi',
              4: 'Jeudi',
              5: 'Vendredi',
              6: 'Samedi',
              7: 'Dimanche',
            };

            rawActivity.forEach((dateStr, minutes) {
              try {
                final date = DateTime.parse(dateStr);
                final dayName = daysMap[date.weekday];
                if (dayName != null) {
                  mappedActivity[dayName] =
                      (mappedActivity[dayName] ?? 0) + (minutes as num).toInt();
                }
              } catch (e) {
                print('Erreur mapping date: $e');
              }
            });

            _progressData = ProgressModel(
              completedCourses:
                  (statsData['completed_courses'] as num?)?.toInt() ?? 0,
              totalCourses: (statsData['total_courses'] as num?)?.toInt() ?? 0,
              totalQuizzes: (statsData['total_quizzes'] as num?)?.toInt() ?? 0,
              averageScore:
                  (statsData['average_score'] as num?)?.toDouble() ?? 0.0,
              totalTimeSpent:
                  (statsData['total_time_spent'] as num?)?.toInt() ?? 0,
              weeklyActivity: mappedActivity,
            );
          }

          if (progData != null) {
            _recentCourses = progData.map((item) {
              final Map<String, dynamic> courseItem =
                  item as Map<String, dynamic>;
              return CourseProgress(
                id: courseItem['course_id'] ?? 0,
                courseName: courseItem['course_name'] ?? 'Sans titre',
                progress: (courseItem['progress'] as num?)?.toInt() ?? 0,
                lastAccessed: courseItem['last_accessed'],
                timeSpent: (courseItem['time_spent'] as num?)?.toInt() ?? 0,
              );
            }).toList();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderStats(theme),
                _buildTabBar(theme),
                _buildTabContent(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualiser'),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6366F1),
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_headerAnimation),
                child: const Text(
                  'Ma Progression',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6).withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderStats(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      );
    }

    if (_progressData == null) {
      return const SizedBox.shrink();
    }

    final progress = _progressData!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedStatCard(
                  title: 'Cours complétés',
                  value:
                      '${progress.completedCourses}/${progress.totalCourses}',
                  icon: FontAwesomeIcons.graduationCap,
                  color: AppTheme.successColor,
                  subtitle:
                      '${progress.completionPercentage.toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatCard(
                  title: 'Score moyen',
                  value: '${progress.averageScore.toStringAsFixed(1)}%',
                  icon: FontAwesomeIcons.trophy,
                  color: AppTheme.warningColor,
                  subtitle: 'Top performer',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedStatCard(
                  title: 'Quiz passés',
                  value: progress.totalQuizzes.toString(),
                  icon: FontAwesomeIcons.vial,
                  color: AppTheme.primaryColor,
                  subtitle: 'Ce mois',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatCard(
                  title: 'Temps total',
                  value: progress.formattedTotalTime,
                  icon: FontAwesomeIcons.clock,
                  color: const Color(0xFFEC4899),
                  subtitle: 'Apprentissage',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor:
            theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            Colors.grey.shade600,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(icon: Icon(Icons.bar_chart), text: 'Activité'),
          Tab(icon: Icon(Icons.history), text: 'Récents'),
          Tab(icon: Icon(Icons.insights), text: 'Statistiques'),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    return SizedBox(
      height: 600,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildRecentCoursesTab(theme),
          _buildStatisticsTab(theme),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_isLoading || _progressData == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    final progress = _progressData!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: ModernCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Activité hebdomadaire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 120,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF6366F1),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = [
                          'Lun',
                          'Mar',
                          'Mer',
                          'Jeu',
                          'Ven',
                          'Sam',
                          'Dim',
                        ][group.x.toInt()];
                        final value =
                            progress.weeklyActivity.values.elementAtOrNull(
                              group.x.toInt(),
                            ) ??
                            0;
                        final hours = (value / 60).toStringAsFixed(1);
                        return BarTooltipItem(
                          '$day\n$hours h',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt() % 7],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(progress.weeklyActivity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> activity) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.primaryColor.withOpacity(0.8),
      const Color(0xFFEC4899),
      AppTheme.warningColor,
      AppTheme.successColor,
    ];

    return List.generate(7, (index) {
      final value = activity.values.elementAtOrNull(index) ?? 0;
      final color = colors[index % colors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (value / 60).toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color.withOpacity(0.7), color],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRecentCoursesTab(ThemeData theme) {
    if (_isLoading || _recentCourses == null) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_recentCourses!.isEmpty) {
      return const Center(child: Text('Aucun cours récent'));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentCourses!.length,
        itemBuilder: (context, index) {
          final course = _recentCourses![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              onTap: () {
                // Navigation vers le cours
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FontAwesomeIcons.book,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dernier accès: ${course.lastAccessedDateTime != null ? _formatDate(course.lastAccessedDateTime!) : 'Jamais'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProgressColor(
                            course.progress,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${course.progress}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getProgressColor(course.progress),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: course.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(course.progress),
                    ),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temps passé: ${course.formattedTimeSpent}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        course.progress == 100 ? 'Terminé' : 'En cours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: course.progress == 100
                              ? AppTheme.successColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme) {
    if (_isLoading || _progressData == null) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    final progress = _progressData!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé de la progression',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  'Taux de complétion',
                  '${progress.completionPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  theme,
                ),
                _buildStatRow(
                  'Score moyen',
                  '${progress.averageScore.toStringAsFixed(1)}%',
                  Icons.emoji_events,
                  theme,
                ),
                _buildStatRow(
                  'Temps total d\'apprentissage',
                  progress.formattedTotalTime,
                  Icons.schedule,
                  theme,
                ),
                _buildStatRow(
                  'Nombre de quiz',
                  '${progress.totalQuizzes}',
                  Icons.quiz,
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return AppTheme.successColor;
    if (progress >= 50) return AppTheme.primaryColor;
    if (progress >= 30) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
