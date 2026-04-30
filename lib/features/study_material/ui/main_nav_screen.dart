import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Source'),
          BottomNavigationBarItem(icon: Icon(Icons.summarize), label: 'Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
        ],
      ),

      // BACK TO HOME BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/');
        },
        child: const Icon(Icons.home),
      ),

    );
  }
}