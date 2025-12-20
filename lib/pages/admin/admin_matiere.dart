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
      setState(() {
        isLoading = false;
      });
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
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(title: 'Matières', onBack: () => Navigator.pop(context)),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : matieres.isEmpty
                  ? const Center(child: Text("Aucune matière trouvée"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: matieres.length,
                      itemBuilder: (context, index) {
                        var matiere = matieres[index];
                        var color = matiereColors[index % matiereColors.length];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.book, color: color),
                            ),
                            title: Text(
                              "${matiere['nom'] ?? 'Sans nom'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${matiere['description'] ?? 'Pas de description'}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (matiere['user_name'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "Prof: ${matiere['user_name']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  color: Colors.blue,
                                  onPressed: () => updateMatiere(matiere),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red[300],
                                  onPressed: () => deleteMatiere(matiere['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
