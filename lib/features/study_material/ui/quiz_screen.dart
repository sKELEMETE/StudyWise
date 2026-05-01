import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/quiz/bloc/quiz_bloc.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/shared/widgets/theme_mode_button.dart';

class QuizTab extends StatefulWidget {
  final String folderName;
  final String userId;

  const QuizTab({
    super.key,
    required this.folderName,
    required this.userId,
  });

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  @override
  void initState() {
    super.initState();
    context.read<QuizBloc>().add(QuizResetRequested());
  }

  @override
  void didUpdateWidget(covariant QuizTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      context.read<QuizBloc>().add(QuizResetRequested());
    }
  }

  void _startQuiz(QuizMode mode) {
    context.read<QuizBloc>().add(
          QuizGenerateRequested(
            userId: widget.userId,
            folderName: widget.folderName,
            mode: mode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.folderName}'),
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            switch (state.status) {
              case QuizStatus.initial:
                return _ModeSelection(onSelected: _startQuiz);
              case QuizStatus.loading:
                return _LoadingQuiz(mode: state.mode);
              case QuizStatus.multipleChoice:
                return _MultipleChoiceQuiz(state: state);
              case QuizStatus.flashcard:
                return _FlashcardQuiz(state: state);
              case QuizStatus.result:
                return _QuizResult(
                  state: state,
                  onRetry: () => _startQuiz(state.mode!),
                  onChangeMode: () {
                    context.read<QuizBloc>().add(QuizResetRequested());
                  },
                );
              case QuizStatus.failure:
                return _QuizError(
                  message: state.message ?? 'Could not start quiz.',
                  onRetry: state.mode == null
                      ? null
                      : () => _startQuiz(state.mode!),
                  onChangeMode: () {
                    context.read<QuizBloc>().add(QuizResetRequested());
                  },
                );
            }
          },
        ),
      ),
    );
  }
}

class _ModeSelection extends StatelessWidget {
  final ValueChanged<QuizMode> onSelected;

  const _ModeSelection({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Choose how to study',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        _ModeTile(
          icon: Icons.checklist,
          title: 'Multiple choice quiz',
          onTap: () => onSelected(QuizMode.multipleChoice),
        ),
        const SizedBox(height: 12),
        _ModeTile(
          icon: Icons.style,
          title: 'Flashcard mode',
          onTap: () => onSelected(QuizMode.flashcard),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingQuiz extends StatelessWidget {
  final QuizMode? mode;

  const _LoadingQuiz({this.mode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              mode == QuizMode.flashcard
                  ? 'Creating flashcards...'
                  : 'Creating quiz...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultipleChoiceQuiz extends StatelessWidget {
  final QuizState state;

  const _MultipleChoiceQuiz({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizBloc>();
    final question = state.session!.questions[state.currentIndex];
    final selectedAnswer = state.selectedAnswerIndex;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProgressHeader(
          current: state.currentIndex + 1,
          total: state.totalItems,
          label: 'Question',
        ),
        const SizedBox(height: 16),
        Text(
          question.question,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => bloc.add(QuizHintToggled()),
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(state.showHint ? 'Hide hint' : 'Show hint'),
        ),
        if (state.showHint) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(question.hint),
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) ...[
          _AnswerButton(
            label: question.options[i],
            isSelected: selectedAnswer == i,
            isCorrect: selectedAnswer != null && question.correctIndex == i,
            isIncorrect: selectedAnswer == i && question.correctIndex != i,
            onPressed: selectedAnswer == null
                ? () => bloc.add(QuizAnswerSelected(i))
                : null,
          ),
          const SizedBox(height: 10),
        ],
        if (selectedAnswer != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => bloc.add(QuizNextRequested()),
            child: Text(state.isLastItem ? 'Show score' : 'Next question'),
          ),
        ],
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final VoidCallback? onPressed;

  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.isIncorrect,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color? backgroundColor;
    final Color? foregroundColor;
    final IconData? icon;

    if (isCorrect) {
      backgroundColor = Colors.green.withValues(alpha: 0.14);
      foregroundColor = colorScheme.onSurface;
      icon = Icons.check_circle;
    } else if (isIncorrect) {
      backgroundColor = colorScheme.errorContainer;
      foregroundColor = colorScheme.onErrorContainer;
      icon = Icons.cancel;
    } else if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
      foregroundColor = colorScheme.onPrimaryContainer;
      icon = Icons.radio_button_checked;
    } else {
      backgroundColor = null;
      foregroundColor = null;
      icon = null;
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledForegroundColor: foregroundColor ?? colorScheme.onSurface,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ],
      ),
    );
  }
}

class _FlashcardQuiz extends StatelessWidget {
  final QuizState state;

  const _FlashcardQuiz({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizBloc>();
    final card = state.session!.flashcards[state.currentIndex];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProgressHeader(
          current: state.currentIndex + 1,
          total: state.totalItems,
          label: 'Card',
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => bloc.add(QuizFlashcardFlipped()),
          borderRadius: BorderRadius.circular(8),
          child: Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    state.showBack ? card.back : card.front,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => bloc.add(QuizFlashcardFlipped()),
          icon: Icon(state.showBack ? Icons.visibility_off : Icons.visibility),
          label: Text(state.showBack ? 'Show front' : 'Show back'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => bloc.add(QuizFlashcardNextRequested()),
          child: Text(state.isLastItem ? 'Finish review' : 'Next card'),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final String label;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label $current of $total'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: clampedProgress),
      ],
    );
  }
}

class _QuizResult extends StatelessWidget {
  final QuizState state;
  final VoidCallback onRetry;
  final VoidCallback onChangeMode;

  const _QuizResult({
    required this.state,
    required this.onRetry,
    required this.onChangeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isFlashcard = state.mode == QuizMode.flashcard;
    final title = isFlashcard ? 'Review complete' : 'Quiz complete';
    final scoreLabel = isFlashcard ? 'Reviewed' : 'Score';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$scoreLabel: ${state.score} / ${state.totalItems}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry quiz'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onChangeMode,
            child: const Text('Change mode'),
          ),
        ],
      ),
    );
  }
}

class _QuizError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onChangeMode;

  const _QuizError({
    required this.message,
    required this.onRetry,
    required this.onChangeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          if (onRetry != null) ...[
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: onChangeMode,
            child: const Text('Choose mode'),
          ),
        ],
      ),
    );
  }
}
