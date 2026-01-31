import 'package:flutter/material.dart';
import 'package:togoschool/core/theme/app_theme.dart';
import 'package:togoschool/components/dash_header.dart';
import 'package:togoschool/pages/admin/page_ajout_matiere.dart';
import 'package:togoschool/services/service_api.dart';

class AdminMatiere extends StatefulWidget {
  const AdminMatiere({super.key});

  @override
  State<AdminMatiere> createState() => _AdminMatiereState();
}

class _AdminMatiereState extends State<AdminMatiere> {
  final api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  final List<Color> matiereColors = [
    AppTheme.primaryColor, // Indigo
    AppTheme.successColor, // Emerald
    AppTheme.warningColor, // Amber
    const Color(0xFF8B5CF6), // Purple
    AppTheme.errorColor, // Red
    const Color(0xFF3B82F6), // Blue
  ];

  bool isLoading = true;
  List<dynamic> matieres = [];
  List<dynamic> filteredMatieres = [];

  @override
  void initState() {
    super.initState();
    getMatieres();
    _searchController.addListener(_filterMatieres);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMatieres() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredMatieres = matieres;
      } else {
        filteredMatieres = matieres.where((m) {
          final nom = (m['nom'] ?? '').toLowerCase();
          final desc = (m['description'] ?? '').toLowerCase();
          final prof = (m['user_name'] ?? '').toLowerCase();
          final classe = (m['classe'] ?? '').toLowerCase();
          return nom.contains(query) ||
              desc.contains(query) ||
              prof.contains(query) ||
              classe.contains(query);
        }).toList();
      }
    });
  }

  Future<void> getMatieres() async {
    try {
      final response = await api.read("/admin/matieres");
      if (mounted) {
        setState(() {
          matieres = response?.data ?? [];
          filteredMatieres = matieres;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteMatiere(int id) async {
    try {
      await api.delete("/admin/matieres/$id");
      setState(() {
        matieres.removeWhere((m) => m['id'] == id);
        _filterMatieres();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Échec de la suppression"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> updateMatiere(dynamic matiere) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMatierePage(matiere: matiere)),
    );
    if (result == true) getMatieres();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          DashHeader(
            color1: AppTheme.primaryColor,
            color2: AppTheme.primaryColor.withOpacity(0.8),
            title: "GESTION MATIÈRES",
            subtitle: "Organisez les disciplines et les effectifs",
            title1: matieres.length.toString(),
            subtitle1: "Matières",
            title2: "",
            subtitle2: "",
            title3: "",
            subtitle3: "",
            onBack: () => Navigator.pop(context),
          ),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: getMatieres,
              color: AppTheme.primaryColor,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : filteredMatieres.isEmpty
                  ? _buildEmptyState()
                  : _buildMatiereList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMatierePage()),
          );
          if (result == true) getMatieres();
        },
        backgroundColor: AppTheme.successColor,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          "NOUVELLE MATIÈRE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher une matière...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: theme.textTheme.bodySmall?.color,
                      size: 18,
                    ),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatiereList() {
    final theme = Theme.of(context);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: filteredMatieres.length,
      itemBuilder: (context, index) {
        final matiere = filteredMatieres[index];
        final color = matiereColors[index % matiereColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.library_books_rounded,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matiere['nom'] ?? 'Sans nom',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            matiere['description'] ?? 'Pas de description',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildMatiereActions(matiere),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoBadge(
                      icon: Icons.person_outline_rounded,
                      label: "Prof: ${matiere['user_name'] ?? 'Non attribué'}",
                      color: matiere['user_name'] != null
                          ? color
                          : theme.disabledColor,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoBadge(
                      icon: Icons.school_outlined,
                      label: "Classe: ${matiere['classe'] ?? 'N/A'}",
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereActions(dynamic matiere) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'edit') {
          updateMatiere(matiere);
        } else if (value == 'delete') {
          _showDeleteConfirmation(matiere);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text("Modifier", style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 12),
              Text(
                "Supprimer",
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(dynamic matiere) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Supprimer ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Voulez-vous vraiment supprimer la matière ${matiere['nom']} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "ANNULER",
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteMatiere(matiere['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("SUPPRIMER"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.library_books_rounded,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? "Aucun résultat trouvé"
                : "Aucune matière trouvée",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? "Essayez une autre recherche."
                : "Commencez par ajouter votre première matière.",
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
