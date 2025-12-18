import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashCart extends StatelessWidget {

  final String text;

  const DashCart({
    super.key,
    required this.text,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue, style: BorderStyle.solid, width: 4)
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(left: 20, top: 10, bottom: 10),
            padding: EdgeInsets.all(10),
            width: 60,
            decoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            borderRadius: BorderRadius.circular(10) 
            ),
            child: Icon(FontAwesomeIcons.book, color: Colors.white,),
          ),
          Container(
            padding: EdgeInsets.all(4),
            margin: EdgeInsets.only(left: 10),
            child: Column(
              children: [
                Text(
                  text,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'accéder à tous vos cours en pdf, audio et video',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}