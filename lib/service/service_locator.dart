import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import  '../core/datasource/auth/auth.dart';
import  '../core/repo/auth/auth.dart';
import  '../core/bloc/auth/auth.dart';


final sl = GetIt.instance;

void initDependencies() {
  // Datasource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(Supabase.instance.client),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // BLoC
  sl.registerFactory(() => AuthBloc(sl()));
}