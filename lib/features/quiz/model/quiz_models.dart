import 'package:studywise/features/study_material/model/study_content_models.dart';

enum QuizMode { multipleChoice, flashcard }

class MultipleChoiceQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String hint;

  const MultipleChoiceQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.hint,
  });
}

class Flashcard {
  final String front;
  final String back;

  const Flashcard({required this.front, required this.back});
}

class QuizSession {
  final QuizMode mode;
  final List<MultipleChoiceQuestion> questions;
  final List<Flashcard> flashcards;

  const QuizSession({
    required this.mode,
    this.questions = const [],
    this.flashcards = const [],
  });

  int get itemCount {
    switch (mode) {
      case QuizMode.multipleChoice:
        return questions.length;
      case QuizMode.flashcard:
        return flashcards.length;
    }
  }
}

class QuizLibraryData {
  final List<StudyMaterialRecord> materials;
  final List<FlashcardSetRecord> flashcardSets;
  final List<SavedQuizRecord> quizzes;

  const QuizLibraryData({
    required this.materials,
    required this.flashcardSets,
    required this.quizzes,
  });

  bool get hasMaterials => materials.isNotEmpty;
}

class ActiveQuizData {
  final String quizId;
  final QuizSession session;

  const ActiveQuizData({required this.quizId, required this.session});
}
