class StudyMaterialRecord {
  final String id;
  final String studentId;
  final String fileType;
  final String filePath;
  final String rawText;
  final DateTime? createdAt;

  const StudyMaterialRecord({
    required this.id,
    required this.studentId,
    required this.fileType,
    required this.filePath,
    required this.rawText,
    this.createdAt,
  });

  factory StudyMaterialRecord.fromMap(Map<String, dynamic> map) {
    return StudyMaterialRecord(
      id: map['id'].toString(),
      studentId: map['student_id']?.toString() ?? '',
      fileType: map['file_type']?.toString() ?? '',
      filePath: map['file_path']?.toString() ?? '',
      rawText: map['raw_text']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class SummaryRecord {
  final String id;
  final String materialId;
  final String summaryText;
  final DateTime? createdAt;

  const SummaryRecord({
    required this.id,
    required this.materialId,
    required this.summaryText,
    this.createdAt,
  });

  factory SummaryRecord.fromMap(Map<String, dynamic> map) {
    return SummaryRecord(
      id: map['id'].toString(),
      materialId: map['material_id']?.toString() ?? '',
      summaryText: map['summary_text']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class FlashcardRecord {
  final String id;
  final String materialId;
  final String front;
  final String back;
  final DateTime? createdAt;

  const FlashcardRecord({
    required this.id,
    required this.materialId,
    required this.front,
    required this.back,
    this.createdAt,
  });

  factory FlashcardRecord.fromMap(Map<String, dynamic> map) {
    return FlashcardRecord(
      id: map['id'].toString(),
      materialId: map['material_id']?.toString() ?? '',
      front: map['front']?.toString() ?? '',
      back: map['back']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class FlashcardSetRecord {
  final String id;
  final String materialId;
  final DateTime? createdAt;
  final List<FlashcardRecord> cards;

  const FlashcardSetRecord({
    required this.id,
    required this.materialId,
    required this.cards,
    this.createdAt,
  });
}

class SavedQuizRecord {
  final String id;
  final String materialId;
  final String title;
  final DateTime? createdAt;

  const SavedQuizRecord({
    required this.id,
    required this.materialId,
    required this.title,
    this.createdAt,
  });

  factory SavedQuizRecord.fromMap(Map<String, dynamic> map) {
    return SavedQuizRecord(
      id: map['id'].toString(),
      materialId: map['material_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Quiz',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class QuestionRecord {
  final String id;
  final String quizId;
  final String questionText;

  const QuestionRecord({
    required this.id,
    required this.quizId,
    required this.questionText,
  });

  factory QuestionRecord.fromMap(Map<String, dynamic> map) {
    return QuestionRecord(
      id: map['id'].toString(),
      quizId: map['quiz_id']?.toString() ?? '',
      questionText: map['question_text']?.toString() ?? '',
    );
  }
}

class ChoiceRecord {
  final String id;
  final String questionId;
  final String choiceText;
  final bool isCorrect;

  const ChoiceRecord({
    required this.id,
    required this.questionId,
    required this.choiceText,
    required this.isCorrect,
  });

  factory ChoiceRecord.fromMap(Map<String, dynamic> map) {
    return ChoiceRecord(
      id: map['id'].toString(),
      questionId: map['question_id']?.toString() ?? '',
      choiceText: map['choice_text']?.toString() ?? '',
      isCorrect: map['is_correct'] == true,
    );
  }
}

class QuizResultRecord {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final DateTime? takenAt;

  const QuizResultRecord({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    this.takenAt,
  });

  factory QuizResultRecord.fromMap(Map<String, dynamic> map) {
    return QuizResultRecord(
      id: map['id'].toString(),
      quizId: map['quiz_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      score: int.tryParse(map['score']?.toString() ?? '') ?? 0,
      takenAt: DateTime.tryParse(map['taken_at']?.toString() ?? ''),
    );
  }
}
