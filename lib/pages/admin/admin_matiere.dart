import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/pages/admin/add_matiere_page.dart';
import 'package:togoschool/service/api_service.dart';

class AdminMatiere extends StatefulWidget {
  const AdminMatiere({super.key});

  @override
  State<AdminMatiere> createState() => _AdminMatiereState();
}

class _AdminMatiereState extends State<AdminMatiere> {
  final api = ApiService();
  final List<Color> matiereColors = [
    const Color.fromARGB(255, 206, 88, 14),
    const Color.fromARGB(255, 53, 4, 252),
    const Color.fromARGB(255, 143, 221, 156),
    const Color.fromARGB(255, 176, 39, 39),
    const Color.fromARGB(255, 223, 82, 255),
    const Color.fromARGB(255, 186, 210, 7),
  ];

  bool isLoading = true;
  List<dynamic> matieres = [];

  @override
  void initState() {
    super.initState();
    getMatieres();
  }

  Future<void> getMatieres() async {
    try {
      final response = await api.read("/admin/matieres");
      setState(() {
        matieres = response?.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteMatiere(int id) async {
    try {
      await api.delete("/admin/matieres/$id");
      setState(() {
        matieres.removeWhere((matiere) => matiere['id'] == id);
      });
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> updateMatiere(dynamic matiere) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMatierePage(matiere: matiere)),
    );

    if (result == true) {
      getMatieres();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(title: 'Matières', onBack: () => Navigator.pop(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: getMatieres,
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            icon: Icon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            hintText: "Rechercher une matière...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            // TODO: Implement local search
                          },
                        ),
                      ),
                    ),

                    // List
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : matieres.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Aucune matière trouvée",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: matieres.length,
                              itemBuilder: (context, index) {
                                var matiere = matieres[index];
                                var color =
                                    matiereColors[index % matiereColors.length];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: null, // Optional: Detail view
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.book,
                                                color: color,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${matiere['nom'] ?? 'Sans nom'}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${matiere['description'] ?? 'Pas de description'}",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                      height: 1.4,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 6.0,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person_outline,
                                                          size: 14,
                                                          color:
                                                              matiere['user_name'] !=
                                                                  null
                                                              ? color
                                                              : Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          "Prof: ${matiere['user_name'] ?? 'Non attribué'}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                matiere['user_name'] !=
                                                                    null
                                                                ? color
                                                                : Colors.grey,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Icon(
                                                          Icons.school_outlined,
                                                          size: 14,
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          matiere['classe'] ??
                                                              'N/A',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 20,
                                                  ),
                                                  color: Colors.blue,
                                                  tooltip: "Modifier",
                                                  onPressed: () =>
                                                      updateMatiere(matiere),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  color: Colors.red[300],
                                                  tooltip: "Supprimer",
                                                  onPressed: () =>
                                                      deleteMatiere(
                                                        matiere['id'],
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
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
