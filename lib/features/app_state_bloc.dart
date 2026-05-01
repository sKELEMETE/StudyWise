import 'package:flutter_bloc/flutter_bloc.dart';

class AppState {
  final String? userId;
  final String? folderName;
  final bool isDarkMode;

  const AppState({
    this.userId,
    this.folderName,
    this.isDarkMode = false,
  });

  bool get hasSelectedFolder => userId != null && folderName != null;

  AppState copyWith({
    String? userId,
    String? folderName,
    bool? isDarkMode,
    bool clearUser = false,
    bool clearFolder = false,
  }) {
    return AppState(
      userId: clearUser ? null : userId ?? this.userId,
      folderName: clearFolder ? null : folderName ?? this.folderName,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class AppStateCubit extends Cubit<AppState> {
  AppStateCubit() : super(const AppState());

  void selectFolder({
    required String userId,
    required String folderName,
  }) {
    emit(state.copyWith(userId: userId, folderName: folderName));
  }

  void toggleThemeMode() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void clearSelection() {
    emit(state.copyWith(clearUser: true, clearFolder: true));
  }

  void clear() {
    clearSelection();
  }
}
