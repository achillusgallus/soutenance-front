class ImpersonationService {
  static bool _isImpersonating = false;
  static Map<String, dynamic>? _impersonatedTeacher;
  static String? _returnRoute;

  /// Check if admin is currently impersonating a teacher
  static bool get isImpersonating => _isImpersonating;

  /// Get the impersonated teacher data
  static Map<String, dynamic>? get impersonatedTeacher => _impersonatedTeacher;

  /// Start impersonating a teacher
  static void startImpersonation(
    Map<String, dynamic> teacherData, {
    String? returnRoute,
  }) {
    _isImpersonating = true;
    _impersonatedTeacher = teacherData;
    _returnRoute = returnRoute ?? '/admin';
  }

  /// Stop impersonating and return route
  static String stopImpersonation() {
    _isImpersonating = false;
    _impersonatedTeacher = null;
    final route = _returnRoute ?? '/admin';
    _returnRoute = null;
    return route;
  }

  /// Get teacher ID being impersonated
  static int? get teacherId => _impersonatedTeacher?['id'];

  /// Get teacher name being impersonated
  static String get teacherName {
    if (_impersonatedTeacher == null) return '';
    return '${_impersonatedTeacher!['name'] ?? ''} ${_impersonatedTeacher!['surname'] ?? ''}'
        .trim();
  }
}
