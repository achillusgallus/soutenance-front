import 'package:togoschool/models/flashcard.dart';
import 'package:togoschool/services/service_api.dart';

class FlashcardService {
  final ApiService _api = ApiService();

  Future<List<Flashcard>> getFlashcards(int courseId) async {
    try {
      final response = await _api.read(
        '/student/flashcards?course_id=$courseId',
      );
      if (response?.data is List) {
        return (response!.data as List)
            .map((json) => Flashcard.fromJson(json))
            .toList();
      }
      return _getMockFlashcards(courseId);
    } catch (e) {
      print('Erreur flashcards: $e');
      return _getMockFlashcards(courseId);
    }
  }

  List<Flashcard> _getMockFlashcards(int courseId) {
    return [
      Flashcard(
        id: 1,
        question: 'Quelle est la capitale du Togo ?',
        answer: 'Lomé',
        courseId: courseId,
        courseName: 'Géographie',
      ),
      Flashcard(
        id: 2,
        question: 'Qui est l\'auteur de "Une si longue lettre" ?',
        answer: 'Mariama Bâ',
        courseId: courseId,
        courseName: 'Littérature',
      ),
      Flashcard(
        id: 3,
        question: 'La formule chimique de l\'eau ?',
        answer: 'H2O',
        courseId: courseId,
        courseName: 'Science',
      ),
      Flashcard(
        id: 4,
        question: 'Quelle est la date de l\'indépendance du Togo ?',
        answer: '27 Avril 1960',
        courseId: courseId,
        courseName: 'Histoire',
      ),
    ];
  }
}
