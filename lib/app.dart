import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/auth/bloc/auth_bloc.dart';

import 'router/app_router.dart';
import 'service/service_locator.dart';

import 'features/study_material/bloc/topic_bloc.dart';
import 'features/study_material/bloc/source_bloc.dart';
import 'features/groq/bloc/ai_bloc.dart';
import 'features/app_state_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AppStateCubit>()),
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<TopicBloc>()),
        BlocProvider(create: (_) => sl<SourceBloc>()),
        BlocProvider(create: (_) => sl<AiBloc>()),
      ],
      child: MaterialApp.router(
        title: 'StudyWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        routerConfig: router,
      ),
    );
  }
}