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

  @override
  void initState() {
    super.initState();
    getTeachers();
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await api.read("/admin/users");
      setState(() {
        final List<dynamic> allUsers = response?.data ?? [];
        teachers = allUsers.where((user) => user['role_id'] == 2).toList();
        isLoading = false;
      });
      return teachers;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      return [];
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
      getTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            FormHeader(
              title: 'Professeurs',
              onBack: () {
                Navigator.pop(context);
              },
            ),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (teachers.isEmpty)
              const Center(child: Text("Aucun enseignant trouvé"))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  var teacher = teachers[index];
                  var color = cardColors[index % cardColors.length];
                  return Card(
                    color: color.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        "${teacher['name'] ?? ''} ${teacher['surname'] ?? ''}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email: ${teacher['email'] ?? ''}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            "Password: ${teacher['password'] ?? ''}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: () {
                              updateTeacher(teacher);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              deleteTeacher(teacher['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
