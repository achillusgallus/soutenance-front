import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/student_connexion_page.dart';
import 'package:dio/dio.dart';
import 'package:togoschool/pages/services/api_service.dart';

import '../components/header.dart';
import '../components/role_toggle.dart';
import '../components/custom_text_form_field.dart';
import '../components/class_dropdown.dart';
import '../components/primary_button.dart';
import '../components/info_card.dart';

class StudentInscriptionPage extends StatefulWidget {
  const StudentInscriptionPage({super.key});

  @override
  State<StudentInscriptionPage> createState() => _StudentInscriptionPageState();
}

class _StudentInscriptionPageState extends State<StudentInscriptionPage> {
  String? selectedvalue = 'tle_D';
  final _formkey = GlobalKey<FormState>();
  final nomController = TextEditingController();
  final ApiService _apiservice = ApiService();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    nomController.dispose();
    prenomController.dispose();
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
              // height: size.height * 0.68,
              decoration: BoxDecoration(
                color: (Colors.white),
                borderRadius: BorderRadius.circular(30),
              ),
              //début du formulaire
              child: Form(
                key: _formkey,
                child:Column(
                children: [
                  const RoleToggle(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'Nom',
                    hint: 'entrer votre nom',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: nomController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'Prenom',
                    hint: 'entrer votre Prenom',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: prenomController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ClassDropdown(
                    value: selectedvalue,
                    onChanged: (value) {
                      setState(() {
                        selectedvalue = value!;
                      });
                    },
                  ),
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
                    text: 'S\'inscrire',
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        try {
                          final user = await _apiservice.registerStudent(
                            nom: nomController.text,
                            prenom: prenomController.text,
                            classe:  selectedvalue!,
                            email: emailController.text,
                            password: passwordController.text,
                          );

                          // Affiche les données de l'utilisateur
                          print("Utilisateur inscrit : $user");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Inscription réussie, bienvenue ${user.nom} !")),
                          );

                          // Naviguez vers une autre page si nécessaire
                          if (mounted) {
                            Navigator.pushReplacement(
                            context,
                              MaterialPageRoute(builder: (context) => const StudentConnexionPage()),
                          );
                          }
                        } catch (e) {
                          if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur lors de l'inscription: ${e.toString()}")),
                          );
                          }
                        }
                      }
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    children: [
                      Text(
                        "j'ai déjà un compte",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                      TextButton(
                        onPressed: (){
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const StudentConnexionPage())
                          );
                        },
                        child: Text(
                          "se connecter",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                        ),
                      )
                    ],
                  )
                ],
              ),),
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
              subtitle: 'suivez votre évaluation et vos résultats par programme',
            )
          ],
        ),
      ),
    );
  }
}
