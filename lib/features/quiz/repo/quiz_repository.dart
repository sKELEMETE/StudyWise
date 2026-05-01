import 'package:studywise/features/quiz/datasource/quiz_remote_data_source.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';

class QuizRepository {
  final QuizRemoteDataSource remoteDataSource;

  QuizRepository(this.remoteDataSource);

  Future<QuizSession> generateQuiz({
    required String userId,
    required String folderName,
    required QuizMode mode,
  }) {
    return remoteDataSource.generateQuiz(
      userId: userId,
      folderName: folderName,
      mode: mode,
    );
  }
}
