import 'package:flutter/material.dart';
import 'package:togoschool/components/form_header.dart';
import 'package:togoschool/pages/admin/add_student.dart';
import 'package:togoschool/pages/admin/add_teacher.dart';
import 'package:togoschool/service/api_service.dart';

class AdminStudentPage extends StatefulWidget {
  const AdminStudentPage({super.key});

  @override
  State<AdminStudentPage> createState() => _AdminStudentPageState();
}

class _AdminStudentPageState extends State<AdminStudentPage> {
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
  List<dynamic> students = [];

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
        students = allUsers.where((user) => user['role_id'] == 3).toList();
        isLoading = false;
      });
      return students;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      return [];
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await api.delete("/admin/users/$id");
      setState(() {
        students.removeWhere((student) => student['id'] == id);
      });
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> updateStudent(dynamic student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddStudent(Student: student)),
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
              title: 'les élèves',
              onBack: () {
                Navigator.pop(context);
              },
            ),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (students.isEmpty)
              const Center(child: Text("Aucun enseignant trouvé"))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var student = students[index];
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
                        "${student['name'] ?? ''} ${student['surname'] ?? ''}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email: ${student['email'] ?? ''}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            "Password: ${student['password'] ?? ''}",
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
                              updateStudent(student);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              deleteStudent(student['id']);
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
