import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashCart extends StatelessWidget {

  final String text;
  final int number;
  final double value;
  final int max;

  const DashCart({
    super.key,
    required this.text,
    required this.number,
    required this.value,
    this.max = 100
    });

  @override
  Widget build(BuildContext context) {
    double ratio =value/max;
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white
      ),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          color: Colors.indigo,
          child: Icon(FontAwesomeIcons.bookmark),
        ),
        Text(
          text,
          style: TextStyle(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold
          ), 
        ),
        Text(
          '$number cours'
        ),
        Row(
          children: [
            LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text('${(value).toInt()}%')
          ],
        )
      ],
    )
    );
  }
}