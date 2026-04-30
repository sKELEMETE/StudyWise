import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:studywise/features/groq/ui/summarize_ui.dart';
import 'package:studywise/router/app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/service_locator.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/ui/auth_screen.dart';
import '../features/study_material/ui/home_screen.dart';
import '../features/study_material/ui/source_screen.dart';
import '../features/study_material/ui/main_nav_screen.dart';
import '../features/study_material/ui/quiz_screen.dart';
import 'go_router_refresh_stream.dart';

final GoRouter router = GoRouter(
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (session == null) return isAuthRoute ? null : '/auth';
    if (isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/auth',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AuthBloc>(),
        child: const AuthScreen(),
      ),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavScreen(navigationShell: navigationShell);
      },
      branches: [
        // SOURCE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/source',
              builder: (context, state) {
                return SourceScreen(
                  folderName: AppSession.folderName!,
                );
              },
            ),
          ],
        ),

        // SUMMARY
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/summary',
              builder: (context, state) {
                return SummaryTab(
                  folderName: AppSession.folderName!,
                  userId: AppSession.userId!,
                );
              },
            ),
          ],
        ),

        // QUIZ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quiz',
              builder: (context, state) {
                return QuizTab(
                  folderName: AppSession.folderName!,
                  userId: AppSession.userId!,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);