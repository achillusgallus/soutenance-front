import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  const InfoCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(right: 30, bottom: 30, left: 30),
      height: MediaQuery.of(context).size.height * 0.08,
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.16,
            height: MediaQuery.of(context).size.height * 0.1,
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, color: Colors.black87, size: 35),
          ),
          Container(
            margin: EdgeInsets.all(2),
            height: MediaQuery.of(context).size.height * 0.06,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
