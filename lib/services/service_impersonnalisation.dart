class ImpersonationService {
  static bool _isImpersonating = false;
  static Map<String, dynamic>? _impersonatedTeacher;
  static String? _returnRoute;

  static bool get isImpersonating => _isImpersonating;
  static Map<String, dynamic>? get impersonatedTeacher => _impersonatedTeacher;

  static void startImpersonation(
    Map<String, dynamic> teacherData, {
    String? returnRoute,
  }) {
    _isImpersonating = true;
    _impersonatedTeacher = teacherData;
    _returnRoute = returnRoute ?? '/admin';
  }

  static String stopImpersonation() {
    _isImpersonating = false;
    _impersonatedTeacher = null;
    final route = _returnRoute ?? '/admin';
    _returnRoute = null;
    return route;
  }

  static int? get teacherId => _impersonatedTeacher?['id'];

  static String get teacherName {
    if (_impersonatedTeacher == null) return '';
    return '${_impersonatedTeacher!['name'] ?? ''} ${_impersonatedTeacher!['surname'] ?? ''}'
        .trim();
  }
}


