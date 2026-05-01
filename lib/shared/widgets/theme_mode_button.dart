import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/app_state_bloc.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppStateCubit, AppState, bool>(
      selector: (state) => state.isDarkMode,
      builder: (context, isDarkMode) {
        return IconButton(
          tooltip: isDarkMode ? 'Use light mode' : 'Use dark mode',
          onPressed: context.read<AppStateCubit>().toggleThemeMode,
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
        );
      },
    );
  }
}
