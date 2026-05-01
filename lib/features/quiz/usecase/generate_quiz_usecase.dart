import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/quiz/repo/quiz_repository.dart';

class GenerateQuizUseCase {
  final QuizRepository repository;

  GenerateQuizUseCase(this.repository);

  Future<QuizSession> call({
    required String userId,
    required String folderName,
    required QuizMode mode,
  }) {
    return repository.generateQuiz(
      userId: userId,
      folderName: folderName,
      mode: mode,
    );
  }
}
