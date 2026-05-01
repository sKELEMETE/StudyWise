import 'package:flutter_bloc/flutter_bloc.dart';

class AppState {
  final String? userId;
  final String? folderName;

  const AppState({
    this.userId,
    this.folderName,
  });

  AppState copyWith({
    String? userId,
    String? folderName,
  }) {
    return AppState(
      userId: userId ?? this.userId,
      folderName: folderName ?? this.folderName,
    );
  }
}

class AppStateCubit extends Cubit<AppState> {
  AppStateCubit() : super(const AppState());

  void setUser(String userId) {
    emit(state.copyWith(userId: userId));
  }

  void setFolder(String folderName) {
    emit(state.copyWith(folderName: folderName));
  }

  void clear() {
    emit(const AppState());
  }
}