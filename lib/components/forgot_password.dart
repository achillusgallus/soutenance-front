import 'package:flutter/material.dart';
import 'package:togoschool/pages/forgot_password_page.dart';

class ForgotPassword extends StatelessWidget {

  final BuildContext? contextFromParam;
  const ForgotPassword({super.key, this.contextFromParam});

  @override
  Widget build(BuildContext context) {
    return TextButton(
          onPressed: (){
          Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const ForgotPasswordPage())
            );
          },
           child: const Text(
          "mot de passe oublié",
         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 17),
      ),
    );
  }
}