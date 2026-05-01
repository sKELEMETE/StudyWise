import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/core/error/friendly_error.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/features/quiz/usecase/generate_quiz_usecase.dart';

enum QuizStatus {
  initial,
  loading,
  multipleChoice,
  flashcard,
  result,
  failure,
}

abstract class QuizEvent {}

class QuizGenerateRequested extends QuizEvent {
  final String userId;
  final String folderName;
  final QuizMode mode;

  QuizGenerateRequested({
    required this.userId,
    required this.folderName,
    required this.mode,
  });
}

class QuizAnswerSelected extends QuizEvent {
  final int selectedIndex;

  QuizAnswerSelected(this.selectedIndex);
}

class QuizNextRequested extends QuizEvent {}

class QuizHintToggled extends QuizEvent {}

class QuizFlashcardFlipped extends QuizEvent {}

class QuizFlashcardNextRequested extends QuizEvent {}

class QuizResetRequested extends QuizEvent {}

class QuizState {
  final QuizStatus status;
  final QuizMode? mode;
  final QuizSession? session;
  final int currentIndex;
  final int score;
  final int? selectedAnswerIndex;
  final bool showHint;
  final bool showBack;
  final String? message;

  const QuizState({
    required this.status,
    this.mode,
    this.session,
    this.currentIndex = 0,
    this.score = 0,
    this.selectedAnswerIndex,
    this.showHint = false,
    this.showBack = false,
    this.message,
  });

  const QuizState.initial() : this(status: QuizStatus.initial);

  int get totalItems => session?.itemCount ?? 0;

  bool get isLastItem => currentIndex >= totalItems - 1;

  QuizState copyWith({
    QuizStatus? status,
    QuizMode? mode,
    QuizSession? session,
    int? currentIndex,
    int? score,
    int? selectedAnswerIndex,
    bool clearSelectedAnswer = false,
    bool? showHint,
    bool? showBack,
    String? message,
  }) {
    return QuizState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswerIndex: clearSelectedAnswer
          ? null
          : selectedAnswerIndex ?? this.selectedAnswerIndex,
      showHint: showHint ?? this.showHint,
      showBack: showBack ?? this.showBack,
      message: message,
    );
  }
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final GenerateQuizUseCase generateQuizUseCase;
  int _generationToken = 0;

  QuizBloc({required this.generateQuizUseCase})
      : super(const QuizState.initial()) {
    on<QuizGenerateRequested>(_onGenerateRequested);
    on<QuizAnswerSelected>(_onAnswerSelected);
    on<QuizNextRequested>(_onNextRequested);
    on<QuizHintToggled>(_onHintToggled);
    on<QuizFlashcardFlipped>(_onFlashcardFlipped);
    on<QuizFlashcardNextRequested>(_onFlashcardNextRequested);
    on<QuizResetRequested>(_onResetRequested);
  }

  Future<void> _onGenerateRequested(
    QuizGenerateRequested event,
    Emitter<QuizState> emit,
  ) async {
    final generationToken = ++_generationToken;
    emit(QuizState(status: QuizStatus.loading, mode: event.mode));

    try {
      final session = await generateQuizUseCase(
        userId: event.userId,
        folderName: event.folderName,
        mode: event.mode,
      );

      if (generationToken != _generationToken) return;
      emit(
        QuizState(
          status: event.mode == QuizMode.multipleChoice
              ? QuizStatus.multipleChoice
              : QuizStatus.flashcard,
          mode: event.mode,
          session: session,
        ),
      );
    } catch (error) {
      if (generationToken != _generationToken) return;
      emit(
        QuizState(
          status: QuizStatus.failure,
          mode: event.mode,
          message: friendlyErrorMessage(error),
        ),
      );
    }
  }

  void _onAnswerSelected(
    QuizAnswerSelected event,
    Emitter<QuizState> emit,
  ) {
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

  void _onNextRequested(
    QuizNextRequested event,
    Emitter<QuizState> emit,
  ) {
    if (state.status != QuizStatus.multipleChoice ||
        state.selectedAnswerIndex == null) {
      return;
    }

    if (state.isLastItem) {
      emit(state.copyWith(status: QuizStatus.result));
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

  void _onHintToggled(
    QuizHintToggled event,
    Emitter<QuizState> emit,
  ) {
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

  void _onResetRequested(
    QuizResetRequested event,
    Emitter<QuizState> emit,
  ) {
    _generationToken++;
    emit(const QuizState.initial());
  }
}
