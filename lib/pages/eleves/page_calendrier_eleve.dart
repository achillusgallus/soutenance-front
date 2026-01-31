import 'package:flutter/material.dart';
import 'package:togoschool/widgets/student_calendar_widget.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class StudentCalendarPage extends StatelessWidget {
  const StudentCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon Calendrier',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: StudentCalendarWidget(),
      ),
    );
  }
}


