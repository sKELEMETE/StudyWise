import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/app_state_bloc.dart';

class MainNavScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateCubit>().state;

    if (!appState.hasSelectedFolder) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Source',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Topics',
        onPressed: () {
          context.go('/');
        },
        child: const Icon(Icons.home),
      ),
    );
  }
}
