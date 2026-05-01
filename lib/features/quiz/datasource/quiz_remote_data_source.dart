import 'dart:convert';

import 'package:studywise/features/groq/datasource/groq_data_source.dart';
import 'package:studywise/features/groq/datasource/study_material_raw_text_grab_data_source.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';

class QuizRemoteDataSource {
  final GrabRawText rawTextDataSource;
  final GroqDataSource groqDataSource;

  QuizRemoteDataSource({
    required this.rawTextDataSource,
    required this.groqDataSource,
  });

  Future<QuizSession> generateQuiz({
    required String userId,
    required String folderName,
    required QuizMode mode,
  }) async {
    final rawTexts = await rawTextDataSource.getRawTexts(
      userId: userId,
      folderName: folderName,
    );

    final combinedText = rawTexts
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');

    if (combinedText.isEmpty) {
      throw Exception('No readable text was found in this folder.');
    }

    final response = await groqDataSource.generateQuizJson(
      rawText: combinedText,
      mode: mode == QuizMode.multipleChoice ? 'multiple_choice' : 'flashcard',
      count: mode == QuizMode.multipleChoice ? 8 : 10,
    );

    return _parseQuizResponse(response, mode);
  }

  QuizSession _parseQuizResponse(String response, QuizMode mode) {
    final decoded = jsonDecode(_extractJsonObject(response));

    if (decoded is! Map<String, dynamic>) {
      throw Exception('AI could not create a quiz from this folder.');
    }

    switch (mode) {
      case QuizMode.multipleChoice:
        final questions = _parseMultipleChoiceQuestions(decoded['questions']);
        if (questions.isEmpty) {
          throw Exception('AI could not create a quiz from this folder.');
        }
        return QuizSession(mode: mode, questions: questions);
      case QuizMode.flashcard:
        final cards = _parseFlashcards(decoded['cards']);
        if (cards.isEmpty) {
          throw Exception('AI could not create flashcards from this folder.');
        }
        return QuizSession(mode: mode, flashcards: cards);
    }
  }

  List<MultipleChoiceQuestion> _parseMultipleChoiceQuestions(dynamic value) {
    if (value is! List) return [];

    final questions = <MultipleChoiceQuestion>[];

    for (final item in value) {
      if (item is! Map) continue;

      final question = item['question']?.toString().trim() ?? '';
      final hint = item['hint']?.toString().trim() ?? '';
      final options = item['options'];
      final correctIndex = _parseCorrectIndex(item['correctIndex']);

      if (question.isEmpty ||
          hint.isEmpty ||
          options is! List ||
          options.length != 4 ||
          correctIndex < 0 ||
          correctIndex > 3) {
        continue;
      }

      final cleanOptions = options
          .map((option) => option.toString().trim())
          .where((option) => option.isNotEmpty)
          .toList(growable: false);

      if (cleanOptions.length != 4) continue;

      questions.add(
        MultipleChoiceQuestion(
          question: question,
          options: cleanOptions,
          correctIndex: correctIndex,
          hint: hint,
        ),
      );
    }

    return questions;
  }

  List<Flashcard> _parseFlashcards(dynamic value) {
    if (value is! List) return [];

    final cards = <Flashcard>[];

    for (final item in value) {
      if (item is! Map) continue;

      final front = item['front']?.toString().trim() ?? '';
      final back = item['back']?.toString().trim() ?? '';

      if (front.isEmpty || back.isEmpty) continue;
      cards.add(Flashcard(front: front, back: back));
    }

    return cards;
  }

  int _parseCorrectIndex(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  String _extractJsonObject(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) return trimmed;

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');

    if (start == -1 || end == -1 || end <= start) {
      throw Exception('AI returned an invalid quiz format.');
    }

    return trimmed.substring(start, end + 1);
  }
}
