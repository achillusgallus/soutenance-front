import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/forgot_password.dart';
import 'package:togoschool/components/header.dart';
import 'package:togoschool/components/info_card.dart';
import 'package:togoschool/components/primary_button.dart';
import 'package:togoschool/components/role_toggle.dart';
import 'package:togoschool/pages/dashbord/student_dashboard_page.dart';
import 'package:togoschool/pages/student_inscription_page.dart';
import 'package:togoschool/service/api_service.dart';
import 'package:togoschool/service/token_storage.dart';

class StudentConnexionPage extends StatefulWidget {
  const StudentConnexionPage({super.key});

  @override
  State<StudentConnexionPage> createState() => _StudentConnexionPageState();
}

class _StudentConnexionPageState extends State<StudentConnexionPage> {

  final _formkey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();

  Future<Map<String, dynamic>?> createUser(String email, String password) async {
    try {
      final response = await api.create("/login", {
        "email": email,
        "password": password,
      });

      if (response?.statusCode == 200) {
        await TokenStorage.saveToken(response?.data["token"]);
        // Connexion réussie
        return response?.data;
      } else {
        return null;
      }
    } catch (e) {
      print("Erreur: $e");
      return null;
    }
  }



  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.secondarySystemBackground,
      body: SafeArea(
      child: ListView(
        children: [
          const TopHeader(),
          Container(
              margin: EdgeInsets.all(30),
              padding: EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: (Colors.white),
                borderRadius: BorderRadius.circular(30),
              ),
              child:Form(
                key: _formkey,
                child: Column(
                children: [
                  const RoleToggle(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'Email',
                    hint: 'entrer votre email',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: emailController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'Mot de passe',
                    hint: 'entrer votre mot de passe',
                    obscureText: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: passwordController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  PrimaryButton(
                    text: 'se connecter',
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        final String email = emailController.text.trim();
                        final String password = passwordController.text.trim();
                        // Appel API login
                        final userData = await createUser(email, password);

                        if (userData != null && userData["user"]["role_id"] == 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Connexion réussie !"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Redirection vers la page d'accueil
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => StudentDashboardPage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Échec de la connexion"),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    children: [
                      Text(
                        "je n'ai pas de compte",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                      TextButton(
                        onPressed: (){
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => StudentInscriptionPage())
                          );
                        },
                        child: Text(
                          "s'inscrire",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                        ),
                      )
                    ],
                  ),
                  
                  ForgotPassword()
                ],
              ),
             ),
            ),

            InfoCard(
              color: const Color.fromARGB(255, 132, 222, 135),
              icon: FontAwesomeIcons.bookOpen,
              title: 'Cours Complet',
              subtitle: 'Accédez à tous vos cours en PDF, audio, et vidéo',
            ),

            InfoCard(
              color: const Color.fromARGB(255, 117, 80, 219),
              icon: FontAwesomeIcons.question,
              title: 'Quiz interactif',
              subtitle: 'testez vos connaissances avec des exercices corrigés',
            ),

            InfoCard(
              color: const Color.fromARGB(255, 202, 109, 176),
              icon: FontAwesomeIcons.barsProgress,
              title: 'Suivi de progression',
              subtitle: 'votre évaluation et vos résultats par programme',
            )
        ],
      ),
      )
    );
  }
}