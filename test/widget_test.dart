import 'package:flutter_test/flutter_test.dart';
import 'package:togoschool/main.dart';
import 'package:togoschool/pages/tableau_de_bord/admin_dashboard_page.dart';
import 'package:togoschool/pages/tableau_de_bord/student_dashboard_page.dart';
import 'package:togoschool/pages/tableau_de_bord/teacher_dashboard_page.dart';
import 'package:togoschool/pages/auth/page_connexion.dart';

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
