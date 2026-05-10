import 'package:get_it/get_it.dart';
import 'package:studywise/features/app_state_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/datasource/auth_remote_data_source.dart';
import '../features/auth/repo/auth_repository.dart';
import '../features/auth/usecase/sign_in_usecase.dart';
import '../features/auth/usecase/sign_up_usecase.dart';
import '../features/auth/bloc/auth_bloc.dart';

import '../features/study_material/datasource/storage_remote_data_source.dart';
import '../features/study_material/datasource/upload_remote_data_source.dart';
import '../features/study_material/datasource/image_local_text_extraction_data_source.dart';
import '../features/study_material/datasource/pdf_local_extraction_data_source.dart';
import '../features/study_material/datasource/study_content_remote_data_source.dart';
import '../features/study_material/repo/study_material_repository.dart';
import '../features/study_material/repo/extraction_repository.dart';
import '../features/study_material/usecase/get_topics_usecase.dart';
import '../features/study_material/usecase/get_topic_files_usecase.dart';
import '../features/study_material/usecase/process_and_upload_material_usecase.dart';
import '../features/study_material/bloc/topic_bloc.dart';
import '../features/study_material/bloc/source_bloc.dart';

import '../features/groq/usecase/groq_usecase.dart';
import '../features/groq/bloc/ai_bloc.dart';
import '../features/groq/datasource/groq_data_source.dart';
import '../features/groq/repo/groq_and_raw_text_repo.dart';

import '../features/quiz/bloc/quiz_bloc.dart';
import '../features/quiz/datasource/quiz_remote_data_source.dart';
import '../features/quiz/repo/quiz_repository.dart';
import '../features/quiz/usecase/generate_quiz_usecase.dart';

final sl = GetIt.instance;

void initDependencies() {
  // === AUTHENTICATION ===
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(Supabase.instance.client),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerFactory(() => AuthBloc(signInUseCase: sl(), signUpUseCase: sl()));

  // === STUDY MATERIALS ===
  // DataSources
  sl.registerLazySingleton(() => StorageRemoteDataSource());
  sl.registerLazySingleton(() => UploadRemoteDataSource());
  sl.registerLazySingleton(() => ImageLocalDataSource());
  sl.registerLazySingleton(() => PdfLocalDataSource());
  sl.registerLazySingleton(() => StudyContentRemoteDataSource());

  // Repositories
  sl.registerLazySingleton(() => StudyMaterialRepository(sl(), sl(), sl()));
  sl.registerLazySingleton(() => ExtractionRepository(sl(), sl()));

  // UseCases
  sl.registerLazySingleton(() => GetTopicsUseCase(sl()));
  sl.registerLazySingleton(() => GetTopicFilesUseCase(sl()));
  sl.registerLazySingleton(() => ProcessAndUploadMaterialUseCase(sl(), sl()));

  // Blocs
  sl.registerFactory(
    () => TopicBloc(getTopicsUseCase: sl(), processUseCase: sl()),
  );
  sl.registerFactory(
    () => SourceBloc(getTopicFilesUseCase: sl(), processUseCase: sl()),
  );

  sl.registerFactory(() => AppStateCubit());

  // === GROQ ===
  sl.registerLazySingleton<GroqDataSource>(() => GroqDataSource());

  // Repo
  sl.registerLazySingleton<AiTextRepo>(
    () => AiTextRepo(contentDataSource: sl(), groqDataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => GetSummariesUseCase(sl()));
  sl.registerLazySingleton(() => SummarizeStudyMaterialsUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => AiBloc(getSummariesUseCase: sl(), summarizeUseCase: sl()),
  );

  // === QUIZ ===
  sl.registerLazySingleton(() => QuizRemoteDataSource(groqDataSource: sl()));
  sl.registerLazySingleton(() => QuizRepository(sl(), sl()));
  sl.registerLazySingleton(() => GetQuizLibraryUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQuizUseCase(sl()));
  sl.registerLazySingleton(() => GenerateFlashcardsUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedQuizSessionUseCase(sl()));
  sl.registerLazySingleton(() => SaveQuizResultUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizHistoryUseCase(sl()));
  sl.registerFactory(
    () => QuizBloc(
      getQuizLibraryUseCase: sl(),
      generateQuizUseCase: sl(),
      generateFlashcardsUseCase: sl(),
      getSavedQuizSessionUseCase: sl(),
      saveQuizResultUseCase: sl(),
      getQuizHistoryUseCase: sl(),
    ),
  );
}
