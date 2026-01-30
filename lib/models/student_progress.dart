class Forum {
  final int id;
  final String titre;
  final String matiereNom;

  Forum({required this.id, required this.titre, required this.matiereNom});

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      matiereNom: json['matiere_nom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'titre': titre, 'matiere_nom': matiereNom};
  }
}

class StudentProgress {
  final int courseId;
  final String courseName;
  final int progress; // 0-100
  final DateTime lastAccessed;
  final int timeSpent; // en secondes

  StudentProgress({
    required this.courseId,
    required this.courseName,
    required this.progress,
    required this.lastAccessed,
    required this.timeSpent,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      courseId: json['course_id'] ?? 0,
      courseName: json['course_name'] ?? '',
      progress: json['progress'] ?? 0,
      lastAccessed: DateTime.parse(
        json['last_accessed'] ?? DateTime.now().toIso8601String(),
      ),
      timeSpent: json['time_spent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_name': courseName,
      'progress': progress,
      'last_accessed': lastAccessed.toIso8601String(),
      'time_spent': timeSpent,
    };
  }
}

class StudentStats {
  final int totalCourses;
  final int completedCourses;
  final int totalQuizzes;
  final double averageScore;
  final int totalTimeSpent;
  final Map<String, int> weeklyActivity; // jour -> minutes

  StudentStats({
    required this.totalCourses,
    required this.completedCourses,
    required this.totalQuizzes,
    required this.averageScore,
    required this.totalTimeSpent,
    required this.weeklyActivity,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      totalCourses: json['total_courses'] ?? 0,
      completedCourses: json['completed_courses'] ?? 0,
      totalQuizzes: json['total_quizzes'] ?? 0,
      averageScore: (json['average_score'] ?? 0).toDouble(),
      totalTimeSpent: json['total_time_spent'] ?? 0,
      weeklyActivity: Map<String, int>.from(json['weekly_activity'] ?? {}),
    );
  }
}
