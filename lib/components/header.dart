import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      width: size.width,
      // height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, CupertinoColors.activeGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(70),
            ),
            child: Icon(FontAwesomeIcons.graduationCap, color: Colors.green, size: 70),
          ),
          SizedBox(height: 10),
          Text(
            'Togoschool',
            style: TextStyle(
              fontSize: 30,
              color: const Color.fromARGB(255, 245, 244, 244),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Votre succès commence ici',
            style: TextStyle(
              fontSize: 20,
              color: const Color.fromARGB(255, 245, 244, 244),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
