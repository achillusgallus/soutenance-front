import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/components/custom_text_form_field.dart';
import 'package:togoschool/components/header.dart';
import 'package:togoschool/components/info_card.dart';
import 'package:togoschool/components/primary_button.dart';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final _formkey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final newpasswordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    newpasswordController.dispose();
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'ancien mot de passe',
                    hint: 'entrer votre ancien mot de passe',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: passwordController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  CustomTextFormField(
                    label: 'nouveau mot de passe',
                    hint: 'entrer votre nouveau mot de passe',
                    obscureText: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "tu dois remplir le champ";
                      }
                      return null;
                    },
                    controller: newpasswordController,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  PrimaryButton(
                    text: 'modifier le mot de passe',
                    onPressed: () {
                      if(_formkey.currentState!.validate()){
                        final String newpassword = newpasswordController.text.trim();
                        final String password = passwordController.text.trim();
                        //snackbar de confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("connexion en cours....."),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                         ),
                        );
                      }
                    },
                  ),
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