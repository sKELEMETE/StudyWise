import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studywise/core/error/friendly_error.dart';
import '../usecase/get_topics_usecase.dart';
import '../usecase/process_and_upload_material_usecase.dart';

abstract class TopicEvent {}

class LoadTopicsRequested extends TopicEvent {
  final String userId;
  LoadTopicsRequested(this.userId);
}

class CreateTopicRequested extends TopicEvent {
  final String userId;
  final String folderName;
  final String fileName;
  final String fileType;
  final Uint8List fileBytes;

  CreateTopicRequested({
    required this.userId,
    required this.folderName,
    required this.fileName,
    required this.fileType,
    required this.fileBytes,
  });
}

abstract class TopicState {}

class TopicInitial extends TopicState {}

class TopicLoading extends TopicState {}

class TopicLoaded extends TopicState {
  final List<FileObject> topics;
  TopicLoaded(this.topics);
}

class TopicError extends TopicState {
  final String message;
  TopicError(this.message);
}

class TopicActionSuccess extends TopicState {
  final String message;
  TopicActionSuccess(this.message);
}

class TopicBloc extends Bloc<TopicEvent, TopicState> {
  final GetTopicsUseCase getTopicsUseCase;
  final ProcessAndUploadMaterialUseCase processUseCase;

  TopicBloc({
    required this.getTopicsUseCase,
    required this.processUseCase,
  }) : super(TopicInitial()) {
    on<LoadTopicsRequested>(_onLoadTopics);
    on<CreateTopicRequested>(_onCreateTopic);
  }

  Future<void> _onLoadTopics(
    LoadTopicsRequested event,
    Emitter<TopicState> emit,
  ) async {
    emit(TopicLoading());
    try {
      final topics = await getTopicsUseCase.execute(event.userId);
      emit(TopicLoaded(topics));
    } catch (e) {
      emit(TopicError(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onCreateTopic(
    CreateTopicRequested event,
    Emitter<TopicState> emit,
  ) async {
    emit(TopicLoading());
    try {
      await processUseCase.execute(
        folderName: event.folderName,
        fileName: event.fileName,
        fileType: event.fileType,
        fileBytes: event.fileBytes,
      );
      emit(TopicActionSuccess('Topic created.'));
      add(LoadTopicsRequested(event.userId));
    } catch (e) {
      emit(TopicError(friendlyErrorMessage(e)));
      add(LoadTopicsRequested(event.userId));
    }
  }
}
