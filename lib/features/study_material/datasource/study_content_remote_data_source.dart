import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class StudyContentRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<dynamic> _call(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final response = await _supabase.functions.invoke(
      'study-content',
      body: {
        'action': action,
        ...payload,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data.toString());
    }

    return response.data;
  }

  Future<void> ensureStudent() async {
    await _call(
      'ensureStudent',
      {},
    );
  }

  Future<List<StudyMaterialRecord>> fetchMaterialsByFolder({
    required String folderName,
  }) async {
    final data = await _call(
      'fetchMaterialsByFolder',
      {
        'folderName': folderName,
      },
    );

    return (data as List)
        .map(
          (item) => StudyMaterialRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<StudyMaterialRecord> insertStudyMaterial({
    required String fileType,
    required String filePath,
    required String rawText,
  }) async {
    final data = await _call(
      'insertStudyMaterial',
      {
        'fileType': fileType,
        'filePath': filePath,
        'rawText': rawText,
      },
    );

    return StudyMaterialRecord.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<void> saveProcessedText({
    required String materialId,
    required String processedText,
  }) async {
    await _call(
      'saveProcessedText',
      {
        'materialId': materialId,
        'processedText': processedText,
      },
    );
  }

  Future<SummaryRecord> saveSummary({
    required String materialId,
    required String summaryText,
  }) async {
    final data = await _call(
      'saveSummary',
      {
        'materialId': materialId,
        'summaryText': summaryText,
      },
    );

    return SummaryRecord.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<SummaryRecord>> fetchSummariesByMaterial({
    required List<String> materialIds,
  }) async {
    final response = await _supabase
        .from('summaries')
        .select()
        .inFilter('material_id', materialIds)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => SummaryRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<FlashcardSetRecord> saveFlashcards({
    required String materialId,
    required List<Flashcard> flashcards,
  }) async {
    final data = await _call(
      'saveFlashcards',
      {
        'materialId': materialId,
        'flashcards': flashcards
            .map(
              (e) => {
                'front': e.front,
                'back': e.back,
              },
            )
            .toList(),
      },  
    );

    final set = Map<String, dynamic>.from(data['set']);

    final cards = (data['cards'] as List)
        .map(
          (item) => FlashcardRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return FlashcardSetRecord(
      id: set['id'],
      materialId: materialId,
      createdAt: DateTime.parse(set['created_at']),
      cards: cards,
    );
  }

  Future<SavedQuizRecord> saveQuiz({
    required String materialId,
    required List<MultipleChoiceQuestion> questions,
  }) async {
    final data = await _call(
      'saveQuiz',
      {
        'materialId': materialId,
        'questions': questions
            .map(
              (q) => {
                'question': q.question,
                'options': q.options,
                'correctIndex': q.correctIndex,
              },
            )
            .toList(),
      },
    );

    return SavedQuizRecord.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<SavedQuizRecord>> fetchQuizzesByMaterial({
    required List<String> materialIds,
  }) async {
    final response = await _supabase
        .from('quizzes')
        .select()
        .inFilter('material_id', materialIds)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => SavedQuizRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<FlashcardSetRecord>> fetchFlashcardsByMaterial({
    required List<String> materialIds,
  }) async {
    final response = await _supabase
        .from('flashcard_sets')
        .select('*, flashcards(*)')
        .inFilter('material_id', materialIds)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      final map = Map<String, dynamic>.from(item);

      final cards = (map['flashcards'] as List).map((card) {
      final c = Map<String, dynamic>.from(card);

      return FlashcardRecord(
        id: c['id'] ?? '',
        materialId: c['material_id'] ?? '',

        front: c['question'] ?? '',
        back: c['answer'] ?? '',
      );
    }).toList();

      return FlashcardSetRecord(
        id: map['id'],
        materialId: map['material_id'],
        createdAt: DateTime.parse(map['created_at']),
        cards: cards,
      );
    }).toList();
  }

  Future<QuizSession> fetchQuizSession({
    required String quizId,
  }) async {
    final questionsResponse = await _supabase
        .from('questions')
        .select('*, choices(*)')
        .eq('quiz_id', quizId)
        .order('created_at', ascending: true);

    final questions = (questionsResponse as List)
        .map((item) {
          final map = Map<String, dynamic>.from(item);

          final choices = (map['choices'] as List)
              .map(
                (choice) => ChoiceRecord.fromMap(
                  Map<String, dynamic>.from(choice),
                ),
              )
              .toList();

          return MultipleChoiceQuestion(
            question: map['question_text'],
            options: choices.map((e) => e.choiceText).toList(),
            correctIndex: choices.indexWhere((e) => e.isCorrect),
            hint: '',
          );
        })
        .toList();

    return QuizSession(
      mode: QuizMode.multipleChoice,
      questions: questions,
    );
  }

  Future<void> saveQuizResult({
    required String quizId,
    required int score,
  }) async {
    await _call(
      'saveQuizResult',
      {
        'quizId': quizId,
        'score': score,
      },
    );
  }

  Future<List<QuizResultRecord>> fetchQuizHistory({
    required String quizId,
  }) async {
    final response = await _supabase
        .from('quiz_results')
        .select()
        .eq('quiz_id', quizId)
        .order('taken_at', ascending: false);

    return (response as List)
        .map(
          (item) => QuizResultRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}