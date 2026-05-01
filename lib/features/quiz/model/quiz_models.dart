enum QuizMode {
  multipleChoice,
  flashcard,
}

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

  const Flashcard({
    required this.front,
    required this.back,
  });
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
