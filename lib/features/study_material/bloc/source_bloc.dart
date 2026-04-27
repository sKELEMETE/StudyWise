import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../usecase/get_topic_files_usecase.dart';
import '../usecase/process_and_upload_material_usecase.dart';

abstract class SourceEvent {}

class LoadSourceRequested extends SourceEvent {
  final String userId;
  final String folderName;
  LoadSourceRequested({required this.userId, required this.folderName});
}

class UploadFileRequested extends SourceEvent {
  final String userId;
  final String folderName;
  final String fileName;
  final String fileType;
  final Uint8List fileBytes;

  UploadFileRequested({
    required this.userId,
    required this.folderName,
    required this.fileName,
    required this.fileType,
    required this.fileBytes,
  });
}

abstract class SourceState {}
class SourceInitial extends SourceState {}
class SourceLoading extends SourceState {}
class SourceLoaded extends SourceState {
  final List<FileObject> files;
  SourceLoaded(this.files);
}
class SourceError extends SourceState {
  final String message;
  SourceError(this.message);
}
class SourceActionSuccess extends SourceState {
  final String message;
  SourceActionSuccess(this.message);
}

class SourceBloc extends Bloc<SourceEvent, SourceState> {
  final GetTopicFilesUseCase getTopicFilesUseCase;
  final ProcessAndUploadMaterialUseCase processUseCase;

  SourceBloc({required this.getTopicFilesUseCase, required this.processUseCase}) : super(SourceInitial()) {
    on<LoadSourceRequested>(_onLoadSource);
    on<UploadFileRequested>(_onUploadFile);
  }

  Future<void> _onLoadSource(LoadSourceRequested event, Emitter<SourceState> emit) async {
    emit(SourceLoading());
    try {
      final files = await getTopicFilesUseCase.execute(event.userId, event.folderName);
      emit(SourceLoaded(files));
    } catch (e) {
      emit(SourceError(e.toString()));
    }
  }

  Future<void> _onUploadFile(UploadFileRequested event, Emitter<SourceState> emit) async {
    emit(SourceLoading());
    try {
      await processUseCase.execute(
        folderName: event.folderName,
        fileName: event.fileName,
        fileType: event.fileType,
        fileBytes: event.fileBytes,
      );
      emit(SourceActionSuccess('File uploaded successfully'));
      add(LoadSourceRequested(userId: event.userId, folderName: event.folderName));
    } catch (e) {
      emit(SourceError('Upload failed: $e'));
      add(LoadSourceRequested(userId: event.userId, folderName: event.folderName));
    }
  }
}