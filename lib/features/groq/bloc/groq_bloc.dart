import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/groq/usecase/groq_usecase.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final SummarizeStudyMaterialsUseCase summarizeUseCase;

  // cache per folder
  final Map<String, String> _cache = {};

  AiBloc({required this.summarizeUseCase}) : super(AiInitial()) {
    on<AiSummarizeRequested>(_onSummarize);
  }

  Future<void> _onSummarize(
    AiSummarizeRequested event,
    Emitter<AiState> emit,
  ) async {
    final key = '${event.userId}_${event.folderName}';

    // return cached result
    if (_cache.containsKey(key)) {
      emit(AiSuccess(_cache[key]!));
      return;
    }

    emit(AiLoading());

    try {
      final result = await summarizeUseCase(
        userId: event.userId,
        folderName: event.folderName,
      );

      _cache[key] = result;

      emit(AiSuccess(result));
    } catch (e) {
      emit(AiError(e.toString()));
    }
  }
}

/// EVENTS
abstract class AiEvent {}

class AiSummarizeRequested extends AiEvent {
  final String userId;
  final String folderName;

  AiSummarizeRequested({
    required this.userId,
    required this.folderName,
  });
}

/// STATES
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