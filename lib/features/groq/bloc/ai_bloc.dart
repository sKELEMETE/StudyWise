import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/core/error/friendly_error.dart';
import 'package:studywise/features/groq/usecase/groq_usecase.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final GetSummariesUseCase getSummariesUseCase;
  final SummarizeStudyMaterialsUseCase summarizeUseCase;
  int _requestToken = 0;

  AiBloc({required this.getSummariesUseCase, required this.summarizeUseCase})
    : super(AiInitial()) {
    on<AiSummariesRequested>(_onSummariesRequested);
    on<AiSummarizeRequested>(_onSummarize);
  }

  Future<void> _onSummariesRequested(
    AiSummariesRequested event,
    Emitter<AiState> emit,
  ) async {
    final requestToken = ++_requestToken;
    emit(AiLoading());

    try {
      final summaries = await getSummariesUseCase(
        folderName: event.folderName,
      );

      if (requestToken != _requestToken) return;
      emit(AiLoaded(summaries));
    } catch (e) {
      if (requestToken != _requestToken) return;
      emit(AiError(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onSummarize(
    AiSummarizeRequested event,
    Emitter<AiState> emit,
  ) async {
    final requestToken = ++_requestToken;
    emit(AiGenerating(state is AiLoaded ? (state as AiLoaded).summaries : []));

    try {
      await summarizeUseCase(
        folderName: event.folderName,
      );

      final summaries = await getSummariesUseCase(
        folderName: event.folderName,
      );

      if (requestToken != _requestToken) return;
      emit(AiLoaded(summaries));
    } catch (e) {
      if (requestToken != _requestToken) return;
      emit(AiError(friendlyErrorMessage(e)));
    }
  }
}

abstract class AiEvent {}

class AiSummariesRequested extends AiEvent {
  final String userId;
  final String folderName;

  AiSummariesRequested({required this.userId, required this.folderName});
}

class AiSummarizeRequested extends AiEvent {
  final String userId;
  final String folderName;

  AiSummarizeRequested({required this.userId, required this.folderName});
}

abstract class AiState {}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiGenerating extends AiState {
  final List<SummaryRecord> summaries;

  AiGenerating(this.summaries);
}

class AiLoaded extends AiState {
  final List<SummaryRecord> summaries;

  AiLoaded(this.summaries);
}

class AiError extends AiState {
  final String message;

  AiError(this.message);
}
