import 'package:studywise/features/quiz/datasource/quiz_remote_data_source.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/study_material/datasource/study_content_remote_data_source.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class QuizRepository {
  final QuizRemoteDataSource remoteDataSource;
  final StudyContentRemoteDataSource contentDataSource;

  QuizRepository(
    this.remoteDataSource,
    this.contentDataSource,
  );

  Future<QuizLibraryData> fetchLibrary({
    required String folderName,
  }) async {
    final materials =
        await contentDataSource.fetchMaterialsByFolder(
      folderName: folderName,
    );

    final materialIds =
        materials.map((e) => e.id).toList();

    final flashcardSets =
        await contentDataSource.fetchFlashcardsByMaterial(
      materialIds: materialIds,
    );

    final quizzes =
        await contentDataSource.fetchQuizzesByMaterial(
      materialIds: materialIds,
    );

    return QuizLibraryData(
      materials: materials,
      flashcardSets: flashcardSets,
      quizzes: quizzes,
    );
  }

  Future<FlashcardSetRecord> generateFlashcards({
    required String folderName,
  }) async {
    final materials =
        await _materialsWithText(folderName);

    final session =
        await remoteDataSource.generateQuiz(
      rawText: _combineText(materials),
      mode: QuizMode.flashcard,
    );

    return await contentDataSource.saveFlashcards(
      materialId: materials.first.id,
      flashcards: session.flashcards,
    );
  }

  Future<ActiveQuizData> generateQuiz({
    required String folderName,
  }) async {
    final materials =
        await _materialsWithText(folderName);

    final session =
        await remoteDataSource.generateQuiz(
      rawText: _combineText(materials),
      mode: QuizMode.multipleChoice,
    );

    final quiz =
        await contentDataSource.saveQuiz(
      materialId: materials.first.id,
      questions: session.questions,
    );

    return ActiveQuizData(
      quizId: quiz.id,
      session: session,
    );
  }

  Future<QuizSession> fetchQuizSession(
    String quizId,
  ) {
    return contentDataSource.fetchQuizSession(
      quizId: quizId,
    );
  }

  Future<void> saveQuizResult({
    required String quizId,
    required int score,
  }) {
    return contentDataSource.saveQuizResult(
      quizId: quizId,
      score: score,
    );
  }

  Future<List<QuizResultRecord>>
      fetchQuizHistory(String quizId) {
    return contentDataSource.fetchQuizHistory(
      quizId: quizId,
    );
  }

  Future<List<StudyMaterialRecord>>
      _materialsWithText(
    String folderName,
  ) async {
    final materials =
        await contentDataSource.fetchMaterialsByFolder(
      folderName: folderName,
    );

    if (materials.isEmpty) {
      throw Exception(
        'No study materials found.',
      );
    }

    if (_combineText(materials).isEmpty) {
      throw Exception(
        'No readable text was found in this folder.',
      );
    }

    return materials;
  }

  String _combineText(
    List<StudyMaterialRecord> materials,
  ) {
    return materials
        .map((e) => e.rawText.trim())
        .where((e) => e.isNotEmpty)
        .join('\n\n');
  }
}