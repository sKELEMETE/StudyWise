import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/auth/bloc/auth_bloc.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'service/service_locator.dart';

import 'features/study_material/bloc/topic_bloc.dart';
import 'features/study_material/bloc/source_bloc.dart';
import 'features/groq/bloc/ai_bloc.dart';
import 'features/app_state_bloc.dart';
import 'features/quiz/bloc/quiz_bloc.dart';

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
        BlocProvider(create: (_) => sl<QuizBloc>()),
      ],
      child: BlocBuilder<AppStateCubit, AppState>(
        buildWhen: (previous, current) =>
            previous.isDarkMode != current.isDarkMode,
        builder: (context, appState) {
          return MaterialApp.router(
            title: 'StudyWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
