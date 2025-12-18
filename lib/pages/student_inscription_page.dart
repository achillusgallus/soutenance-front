import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/pages/student_connexion_page.dart';

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
                    text: 's\'inscrire',
                    onPressed: () {
                      if(_formkey.currentState!.validate()){
                        final String nom = nomController.text.trim();
                        final String prenom = prenomController.text.trim();
                        final String email = emailController.text.trim();
                        final String password = passwordController.text.trim();
                        //snackbar de confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("connexion en cours.....\n Email: $email"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                         ),
                        );
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
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      TextButton(
                        onPressed: (){
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const StudentConnexionPage())
                          );
                        },
                        child: Text(
                          "se connecter",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 17),
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
              subtitle: 'suivez votre évaluation et améliorez vos performances',
            )
          ],
        ),
      ),
    );
  }
}
