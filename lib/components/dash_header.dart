import 'package:flutter/material.dart';

class DashHeader extends StatelessWidget {

  final Color color1;
  final Color color2;
  final String title;
  final String title1;
  final String title2;
  final String title3;
  final String subtitle;
  final String subtitle1;
  final String subtitle2;
  final String subtitle3;

  const DashHeader({
    super.key,
    required this.color1,
    required this.color2,
    required this.title,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.subtitle,
    required this.subtitle1,
    required this.subtitle2,
    required this.subtitle3,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
       gradient: LinearGradient(
        colors: [
          color1,
          color2
        ]
        )
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
              ),
              Text(subtitle,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15
              ),
              )
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.3)
                ),
                child: Column(
                  children: [
                    Text(
                      title1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.3)
                ),
                child: Column(
                  children: [
                    Text(
                      title2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues()
                ),
                child: Column(
                  children: [
                    Text(
                      title3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      subtitle3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}