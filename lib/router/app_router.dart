import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:studywise/features/app_state_bloc.dart';
import 'package:studywise/features/groq/ui/summarize_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final protectedTabs = {'/source', '/summary', '/quiz'};

    if (session == null) return isAuthRoute ? null : '/auth';
    if (isAuthRoute) return '/';
    if (protectedTabs.contains(state.matchedLocation)) {
      final appState = context.read<AppStateCubit>().state;
      if (!appState.hasSelectedFolder) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
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
                final appState = context.watch<AppStateCubit>().state;

                if (!appState.hasSelectedFolder) {
                  return const Scaffold(body: SizedBox.shrink());
                }

                return SourceScreen(
                  key: ValueKey(appState.folderName),
                  folderName: appState.folderName!,
                  userId: appState.userId!,
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
                final appState = context.watch<AppStateCubit>().state;

                if (!appState.hasSelectedFolder) {
                  return const Scaffold(body: SizedBox.shrink());
                }

                return SummaryTab(
                  key: ValueKey(appState.folderName),
                  folderName: appState.folderName!,
                  userId: appState.userId!,
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
                final appState = context.watch<AppStateCubit>().state;

                if (!appState.hasSelectedFolder) {
                  return const Scaffold(body: SizedBox.shrink());
                }

                return QuizTab(
                  key: ValueKey(appState.folderName),
                  folderName: appState.folderName!,
                  userId: appState.userId!,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
