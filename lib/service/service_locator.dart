import 'package:get_it/get_it.dart';
import 'package:studywise/service/env_service.dart';
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
import '../features/study_material/repo/study_material_repository.dart';
import '../features/study_material/repo/extraction_repository.dart';
import '../features/study_material/usecase/get_topics_usecase.dart';
import '../features/study_material/usecase/get_topic_files_usecase.dart';
import '../features/study_material/usecase/process_and_upload_material_usecase.dart';
import '../features/study_material/bloc/topic_bloc.dart';
import '../features/study_material/bloc/source_bloc.dart';

import '../features/groq/usecase/groq_usecase.dart';
import '../features/groq/bloc/groq_bloc.dart';
import '../features/groq/datasource/groq_data_source.dart';
import 'package:studywise/features/groq/repo/groq_and_raw_text_repo.dart';
import 'package:studywise/features/groq/datasource/study_material_raw_text_grab_data_source.dart';


final sl = GetIt.instance;

void initDependencies() {
  // === AUTHENTICATION ===
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(Supabase.instance.client));
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

  // Repositories
  sl.registerLazySingleton(() => StudyMaterialRepository(sl(), sl()));
  sl.registerLazySingleton(() => ExtractionRepository(sl(), sl()));

  // UseCases
  sl.registerLazySingleton(() => GetTopicsUseCase(sl()));
  sl.registerLazySingleton(() => GetTopicFilesUseCase(sl()));
  sl.registerLazySingleton(() => ProcessAndUploadMaterialUseCase(sl(), sl()));

  // Blocs
  sl.registerFactory(() => TopicBloc(getTopicsUseCase: sl(), processUseCase: sl()));
  sl.registerFactory(() => SourceBloc(getTopicFilesUseCase: sl(), processUseCase: sl()));

  // === GROQ ===
  // DataSource
  sl.registerLazySingleton<GrabRawText>(
    () => GrabRawText(),
  );

  sl.registerLazySingleton<GroqDataSource>(
    () => GroqDataSource(apiKey: EnvService.groqApiKey),
  );

  //Repo
  sl.registerLazySingleton<AiTextRepo>(
  () => AiTextRepo(
    remoteDataSource: sl(),
    groqDataSource: sl(),
  ),
);

  //UseCases
  sl.registerLazySingleton(
  () => SummarizeStudyMaterialsUseCase(sl()),
);

  //Bloc
  sl.registerFactory(
  () => AiBloc(
    summarizeUseCase: sl(),
  ),
);
}