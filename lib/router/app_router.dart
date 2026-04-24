import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:studywise/core/bloc/auth/auth.dart';
import 'package:studywise/service/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// screens
import '../core/ui/auth/auth_screen.dart';
import '../core/ui/home/home_screen.dart';
import '../core/ui/source/source_screen.dart';

// refresh helper
import 'go_router_refresh_stream.dart';

final GoRouter router = GoRouter(
  //  auth state listener 
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  //  AUTH GUARD
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

  // ROUTES
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
        return SourceScreen(folderName: folderName);
      },
    ),

  ],
);