import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/service_locator.dart';

// features
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/ui/auth_screen.dart';
import '../features/study_material/bloc/topic_bloc.dart';
import '../features/study_material/bloc/source_bloc.dart';
import '../features/study_material/ui/home_screen.dart';
import '../features/study_material/ui/source_screen.dart';

// refresh helper
import 'go_router_refresh_stream.dart';

final GoRouter router = GoRouter(
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  redirect: (context, state) {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (session == null) {
      return isAuthRoute ? null : '/auth';
    }
    if (isAuthRoute) {
      return '/';
    }
    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<TopicBloc>(),
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<AuthBloc>(),
        child: const AuthScreen(),
      ),
    ),
    GoRoute(
      path: '/source/:folderName',
      builder: (context, state) {
        final folderName = state.pathParameters['folderName']!;
        return BlocProvider(
          create: (context) => sl<SourceBloc>(),
          child: SourceScreen(folderName: folderName),
        );
      },
    ),
  ],
);