import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/service/api_service.dart';

class AdminProfesseur extends StatefulWidget {
  const AdminProfesseur({super.key});

  @override
  State<AdminProfesseur> createState() => _AdminProfesseurState();
}

class _AdminProfesseurState extends State<AdminProfesseur> {
  final api = ApiService();
  final List<Color> cardColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.redAccent,
    Colors.teal,
  ];

  bool isLoading = true;
  List<dynamic> teachers = [];
  List<dynamic> matieres = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      final results = await Future.wait([
        api.read("/admin/users"),
        api.read("/admin/matieres"),
      ]);

      if (!mounted) return;

      setState(() {
        final List<dynamic> allUsers = results[0]?.data ?? [];
        teachers = allUsers.where((user) => user['role_id'] == 2).toList();
        matieres = results[1]?.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteTeacher(int id) async {
    try {
      await api.delete("/admin/users/$id");
      setState(() {
        teachers.removeWhere((teacher) => teacher['id'] == id);
      });
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> updateTeacher(dynamic teacher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTeacherPage(teacher: teacher)),
    );

    if (result == true) {
      getData();
    }
  }

  List<dynamic> getTeacherMatieres(int teacherId) {
    return matieres.where((m) => m['user_id'] == teacherId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Professeurs',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: getData,
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
                            hintText: "Rechercher un professeur...",
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
                          : teachers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Aucun enseignant trouvé",
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
                              itemCount: teachers.length,
                              itemBuilder: (context, index) {
                                var teacher = teachers[index];
                                var color =
                                    cardColors[index % cardColors.length];
                                var assignedMatieres = getTeacherMatieres(
                                  teacher['id'],
                                );

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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: color
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.person,
                                                color: color,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${teacher['email'] ?? ''}",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 20,
                                                  ),
                                                  color: Colors.blue,
                                                  onPressed: () =>
                                                      updateTeacher(teacher),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  color: Colors.red[300],
                                                  onPressed: () =>
                                                      deleteTeacher(
                                                        teacher['id'],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9F9F9),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Matières affectées:",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (assignedMatieres.isEmpty)
                                                Text(
                                                  "Aucune matière affectée",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[500],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                )
                                              else
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: assignedMatieres
                                                      .map(
                                                        (m) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: color
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            m['nom'] ?? '',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                            ],
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
