import 'package:flutter_test/flutter_test.dart';
import 'package:togoschool/main.dart';
import 'package:togoschool/pages/dashbord/admin_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/student_dashboard_page.dart';
import 'package:togoschool/pages/dashbord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/auth/login_page.dart';

void main() {
  testWidgets('Connexion page is shown when not logged in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(isLoggedIn: false, roleId: null));
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Admin dashboard is shown when roleId = 1', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(isLoggedIn: true, roleId: 1));
    expect(find.byType(AdminDashboardPage), findsOneWidget);
  });

  testWidgets('Teacher dashboard is shown when roleId = 2', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(isLoggedIn: true, roleId: 2));
    expect(find.byType(TeacherDashboardPage), findsOneWidget);
  });

  testWidgets('Student dashboard is shown when roleId = 3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(isLoggedIn: true, roleId: 3));
    expect(find.byType(StudentDashboardPage), findsOneWidget);
  });
}
