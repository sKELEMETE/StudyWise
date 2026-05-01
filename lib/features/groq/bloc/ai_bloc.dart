import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/core/error/friendly_error.dart';
import 'package:studywise/features/groq/usecase/groq_usecase.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final SummarizeStudyMaterialsUseCase summarizeUseCase;
  int _requestToken = 0;

  AiBloc({required this.summarizeUseCase}) : super(AiInitial()) {
    on<AiSummarizeRequested>(_onSummarize);
  }

  Future<void> _onSummarize(
    AiSummarizeRequested event,
    Emitter<AiState> emit,
  ) async {
    final requestToken = ++_requestToken;
    emit(AiLoading());

    try {
      final result = await summarizeUseCase(
        userId: event.userId,
        folderName: event.folderName,
      );

      if (requestToken != _requestToken) return;
      emit(AiSuccess(result));
    } catch (e) {
      if (requestToken != _requestToken) return;
      emit(AiError(friendlyErrorMessage(e)));
    }
  }
}

abstract class AiEvent {}

class AiSummarizeRequested extends AiEvent {
  final String userId;
  final String folderName;

  AiSummarizeRequested({
    required this.userId,
    required this.folderName,
  });
}

abstract class AiState {}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiSuccess extends AiState {
  final String result;
  AiSuccess(this.result);
}

class AiError extends AiState {
  final String message;
  AiError(this.message);
}
