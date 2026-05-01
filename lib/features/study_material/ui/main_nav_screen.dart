import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/app_state_bloc.dart';
import 'package:studywise/features/groq/bloc/ai_bloc.dart';

class MainNavScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavScreen({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
  navigationShell.goBranch(index);

  if (index == 1) {
    final appState = context.read<AppStateCubit>().state;

    if (appState.userId == null || appState.folderName == null) return;

    context.read<AiBloc>().add(
          AiSummarizeRequested(
            userId: appState.userId!,
            folderName: appState.folderName!,
          ),
        );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Source',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/');
        },
        child: const Icon(Icons.home),
      ),
    );
  }
}