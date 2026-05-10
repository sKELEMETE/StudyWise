import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/core/error/friendly_error.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/quiz/usecase/generate_quiz_usecase.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

enum QuizStatus {
  initial,
  loading,
  library,
  generating,
  multipleChoice,
  flashcard,
  result,
  failure,
}

abstract class QuizEvent {}

class QuizLibraryRequested extends QuizEvent {
  final String userId;
  final String folderName;

  QuizLibraryRequested({required this.userId, required this.folderName});
}

class QuizGenerateRequested extends QuizEvent {
  final String userId;
  final String folderName;

  QuizGenerateRequested({required this.userId, required this.folderName});
}

class FlashcardsGenerateRequested extends QuizEvent {
  final String userId;
  final String folderName;

  FlashcardsGenerateRequested({required this.userId, required this.folderName});
}

class SavedQuizOpened extends QuizEvent {
  final String quizId;

  SavedQuizOpened(this.quizId);
}

class SavedFlashcardSetOpened extends QuizEvent {
  final FlashcardSetRecord set;

  SavedFlashcardSetOpened(this.set);
}

class QuizAnswerSelected extends QuizEvent {
  final int selectedIndex;

  QuizAnswerSelected(this.selectedIndex);
}

class QuizNextRequested extends QuizEvent {}

class QuizHintToggled extends QuizEvent {}

class QuizFlashcardFlipped extends QuizEvent {}

class QuizFlashcardNextRequested extends QuizEvent {}

class QuizBackToLibraryRequested extends QuizEvent {}

class QuizState {
  final QuizStatus status;
  final QuizLibraryData? library;
  final QuizSession? session;
  final String? activeQuizId;
  final List<QuizResultRecord> quizHistory;
  final int currentIndex;
  final int score;
  final int? selectedAnswerIndex;
  final bool showHint;
  final bool showBack;
  final bool resultSaved;
  final String? message;

  const QuizState({
    required this.status,
    this.library,
    this.session,
    this.activeQuizId,
    this.quizHistory = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.selectedAnswerIndex,
    this.showHint = false,
    this.showBack = false,
    this.resultSaved = false,
    this.message,
  });

  const QuizState.initial() : this(status: QuizStatus.initial);

  int get totalItems => session?.itemCount ?? 0;

  bool get isLastItem => currentIndex >= totalItems - 1;

  bool get isInSession {
    return status == QuizStatus.multipleChoice ||
        status == QuizStatus.flashcard ||
        status == QuizStatus.result;
  }

  QuizState copyWith({
    QuizStatus? status,
    QuizLibraryData? library,
    QuizSession? session,
    String? activeQuizId,
    List<QuizResultRecord>? quizHistory,
    int? currentIndex,
    int? score,
    int? selectedAnswerIndex,
    bool clearSelectedAnswer = false,
    bool? showHint,
    bool? showBack,
    bool? resultSaved,
    String? message,
  }) {
    return QuizState(
      status: status ?? this.status,
      library: library ?? this.library,
      session: session ?? this.session,
      activeQuizId: activeQuizId ?? this.activeQuizId,
      quizHistory: quizHistory ?? this.quizHistory,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswerIndex: clearSelectedAnswer
          ? null
          : selectedAnswerIndex ?? this.selectedAnswerIndex,
      showHint: showHint ?? this.showHint,
      showBack: showBack ?? this.showBack,
      resultSaved: resultSaved ?? this.resultSaved,
      message: message,
    );
  }
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final GetQuizLibraryUseCase getQuizLibraryUseCase;
  final GenerateQuizUseCase generateQuizUseCase;
  final GenerateFlashcardsUseCase generateFlashcardsUseCase;
  final GetSavedQuizSessionUseCase getSavedQuizSessionUseCase;
  final SaveQuizResultUseCase saveQuizResultUseCase;
  final GetQuizHistoryUseCase getQuizHistoryUseCase;

  int _generationToken = 0;
  String? _userId;

  QuizBloc({
    required this.getQuizLibraryUseCase,
    required this.generateQuizUseCase,
    required this.generateFlashcardsUseCase,
    required this.getSavedQuizSessionUseCase,
    required this.saveQuizResultUseCase,
    required this.getQuizHistoryUseCase,
  }) : super(const QuizState.initial()) {
    on<QuizLibraryRequested>(_onLibraryRequested);
    on<QuizGenerateRequested>(_onQuizGenerateRequested);
    on<FlashcardsGenerateRequested>(_onFlashcardsGenerateRequested);
    on<SavedQuizOpened>(_onSavedQuizOpened);
    on<SavedFlashcardSetOpened>(_onSavedFlashcardSetOpened);
    on<QuizAnswerSelected>(_onAnswerSelected);
    on<QuizNextRequested>(_onNextRequested);
    on<QuizHintToggled>(_onHintToggled);
    on<QuizFlashcardFlipped>(_onFlashcardFlipped);
    on<QuizFlashcardNextRequested>(_onFlashcardNextRequested);
    on<QuizBackToLibraryRequested>(_onBackToLibraryRequested);
  }

  Future<void> _onLibraryRequested(
    QuizLibraryRequested event,
    Emitter<QuizState> emit,
  ) async {
    _userId = event.userId;
    final generationToken = ++_generationToken;
    emit(QuizState(status: QuizStatus.loading, library: state.library));

    try {
      final library = await getQuizLibraryUseCase(
        folderName: event.folderName,
      );

      if (generationToken != _generationToken) return;
      emit(QuizState(status: QuizStatus.library, library: library));
    } catch (error) {
      if (generationToken != _generationToken) return;
      emit(
        QuizState(
          status: QuizStatus.failure,
          library: state.library,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onQuizGenerateRequested(
    QuizGenerateRequested event,
    Emitter<QuizState> emit,
  ) async {
    _userId = event.userId;
    final generationToken = ++_generationToken;
    emit(state.copyWith(status: QuizStatus.generating));

    try {
      final activeQuiz = await generateQuizUseCase(
        folderName: event.folderName,
      );
      final library = await getQuizLibraryUseCase(
        folderName: event.folderName,
      );
      final history = await getQuizHistoryUseCase(activeQuiz.quizId);

      if (generationToken != _generationToken) return;
      emit(
        QuizState(
          status: QuizStatus.multipleChoice,
          library: library,
          session: activeQuiz.session,
          activeQuizId: activeQuiz.quizId,
          quizHistory: history,
        ),
      );
    } catch (error) {
      if (generationToken != _generationToken) return;
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onFlashcardsGenerateRequested(
    FlashcardsGenerateRequested event,
    Emitter<QuizState> emit,
  ) async {
    _userId = event.userId;
    final generationToken = ++_generationToken;
    emit(state.copyWith(status: QuizStatus.generating));

    try {
      final set = await generateFlashcardsUseCase(
        folderName: event.folderName,
      );
      final library = await getQuizLibraryUseCase(
        folderName: event.folderName,
      );

      if (generationToken != _generationToken) return;
      emit(
        QuizState(
          status: QuizStatus.flashcard,
          library: library,
          session: QuizSession(
            mode: QuizMode.flashcard,
            flashcards: set.cards
                .map((card) => Flashcard(front: card.front, back: card.back))
                .toList(growable: false),
          ),
        ),
      );
    } catch (error) {
      if (generationToken != _generationToken) return;
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onSavedQuizOpened(
    SavedQuizOpened event,
    Emitter<QuizState> emit,
  ) async {
    emit(state.copyWith(status: QuizStatus.loading));

    try {
      final session = await getSavedQuizSessionUseCase(event.quizId);
      final history = await getQuizHistoryUseCase(event.quizId);

      emit(
        state.copyWith(
          status: QuizStatus.multipleChoice,
          session: session,
          activeQuizId: event.quizId,
          quizHistory: history,
          currentIndex: 0,
          score: 0,
          clearSelectedAnswer: true,
          showHint: false,
          resultSaved: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }

  void _onSavedFlashcardSetOpened(
    SavedFlashcardSetOpened event,
    Emitter<QuizState> emit,
  ) {
    emit(
      state.copyWith(
        status: QuizStatus.flashcard,
        session: QuizSession(
          mode: QuizMode.flashcard,
          flashcards: event.set.cards
              .map((card) => Flashcard(front: card.front, back: card.back))
              .toList(growable: false),
        ),
        currentIndex: 0,
        score: 0,
        showBack: false,
        resultSaved: true,
      ),
    );
  }

  void _onAnswerSelected(QuizAnswerSelected event, Emitter<QuizState> emit) {
    if (state.status != QuizStatus.multipleChoice ||
        state.selectedAnswerIndex != null ||
        state.session == null) {
      return;
    }

    final question = state.session!.questions[state.currentIndex];
    final isCorrect = event.selectedIndex == question.correctIndex;

    emit(
      state.copyWith(
        selectedAnswerIndex: event.selectedIndex,
        score: isCorrect ? state.score + 1 : state.score,
      ),
    );
  }

  Future<void> _onNextRequested(
    QuizNextRequested event,
    Emitter<QuizState> emit,
  ) async {
    if (state.status != QuizStatus.multipleChoice ||
        state.selectedAnswerIndex == null) {
      return;
    }

    if (state.isLastItem) {
      await _saveResultIfNeeded(emit);
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedAnswer: true,
        showHint: false,
      ),
    );
  }

  void _onHintToggled(QuizHintToggled event, Emitter<QuizState> emit) {
    if (state.status != QuizStatus.multipleChoice) return;
    emit(state.copyWith(showHint: !state.showHint));
  }

  void _onFlashcardFlipped(
    QuizFlashcardFlipped event,
    Emitter<QuizState> emit,
  ) {
    if (state.status != QuizStatus.flashcard) return;
    emit(state.copyWith(showBack: !state.showBack));
  }

  void _onFlashcardNextRequested(
    QuizFlashcardNextRequested event,
    Emitter<QuizState> emit,
  ) {
    if (state.status != QuizStatus.flashcard) return;

    if (state.isLastItem) {
      emit(
        state.copyWith(
          status: QuizStatus.result,
          score: state.totalItems,
          resultSaved: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        showBack: false,
        score: state.currentIndex + 1,
      ),
    );
  }

  void _onBackToLibraryRequested(
    QuizBackToLibraryRequested event,
    Emitter<QuizState> emit,
  ) {
    _generationToken++;
    emit(QuizState(status: QuizStatus.library, library: state.library));
  }

  Future<void> _saveResultIfNeeded(Emitter<QuizState> emit) async {
    if (state.resultSaved) {
      emit(state.copyWith(status: QuizStatus.result));
      return;
    }

    final quizId = state.activeQuizId;
    final studentId = _userId;

    if (quizId == null || studentId == null) {
      emit(state.copyWith(status: QuizStatus.result, resultSaved: true));
      return;
    }

    try {
      await saveQuizResultUseCase(
        quizId: quizId,
        score: state.score,
      );
      final history = await getQuizHistoryUseCase(quizId);
      emit(
        state.copyWith(
          status: QuizStatus.result,
          resultSaved: true,
          quizHistory: history,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuizStatus.failure,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }
}
