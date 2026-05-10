import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/quiz/repo/quiz_repository.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class GetQuizLibraryUseCase {
  final QuizRepository repository;

  GetQuizLibraryUseCase(this.repository);

  Future<QuizLibraryData> call({
    required String folderName,
  }) {
    return repository.fetchLibrary(
      folderName: folderName,
    );
  }
}

class GenerateQuizUseCase {
  final QuizRepository repository;

  GenerateQuizUseCase(this.repository);

  Future<ActiveQuizData> call({
    required String folderName,
  }) {
    return repository.generateQuiz(
      folderName: folderName,
    );
  }
}

class GenerateFlashcardsUseCase {
  final QuizRepository repository;

  GenerateFlashcardsUseCase(this.repository);

  Future<FlashcardSetRecord> call({
    required String folderName,
  }) {
    return repository.generateFlashcards(
      folderName: folderName,
    );
  }
}

class GetSavedQuizSessionUseCase {
  final QuizRepository repository;

  GetSavedQuizSessionUseCase(this.repository);

  Future<QuizSession> call(
    String quizId,
  ) {
    return repository.fetchQuizSession(
      quizId,
    );
  }
}

class SaveQuizResultUseCase {
  final QuizRepository repository;

  SaveQuizResultUseCase(this.repository);

  Future<void> call({
    required String quizId,
    required int score,
  }) {
    return repository.saveQuizResult(
      quizId: quizId,
      score: score,
    );
  }
}

class GetQuizHistoryUseCase {
  final QuizRepository repository;

  GetQuizHistoryUseCase(this.repository);

  Future<List<QuizResultRecord>> call(
    String quizId,
  ) {
    return repository.fetchQuizHistory(
      quizId,
    );
  }
}