import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/quiz/bloc/quiz_bloc.dart';
import 'package:studywise/features/quiz/model/quiz_models.dart';
import 'package:studywise/shared/widgets/app_back_button.dart';
import 'package:studywise/shared/widgets/skeleton_loaders.dart';
import 'package:studywise/shared/widgets/study_cards.dart';
import 'package:studywise/shared/widgets/theme_mode_button.dart';

class QuizTab extends StatefulWidget {
  final String folderName;
  final String userId;

  const QuizTab({super.key, required this.folderName, required this.userId});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void didUpdateWidget(covariant QuizTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      _loadLibrary();
    }
  }

  void _loadLibrary() {
    context.read<QuizBloc>().add(
      QuizLibraryRequested(
        userId: widget.userId,
        folderName: widget.folderName,
      ),
    );
  }

  void _generateQuiz() {
    context.read<QuizBloc>().add(
      QuizGenerateRequested(
        userId: widget.userId,
        folderName: widget.folderName,
      ),
    );
  }

  void _generateFlashcards() {
    context.read<QuizBloc>().add(
      FlashcardsGenerateRequested(
        userId: widget.userId,
        folderName: widget.folderName,
      ),
    );
  }

  void _backToLibrary() {
    context.read<QuizBloc>().add(QuizBackToLibraryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        final shouldStayInQuiz =
            state.isInSession || state.status == QuizStatus.generating;

        return PopScope(
          canPop: !shouldStayInQuiz,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && shouldStayInQuiz) {
              _backToLibrary();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading:
                  state.isInSession || state.status == QuizStatus.generating
                  ? AppBackButton(onPressed: _backToLibrary)
                  : const AppBackButton(),
              title: Text('${widget.folderName}'),
              actions: const [ThemeModeButton()],
            ),
            body: SafeArea(child: _buildBody(state)),
          ),
        );
      },
    );
  }

  Widget _buildBody(QuizState state) {
    switch (state.status) {
      case QuizStatus.initial:
      case QuizStatus.loading:
        return const QuizSkeleton();
      case QuizStatus.library:
        return _QuizLibrary(
          state: state,
          onGenerateQuiz: _generateQuiz,
          onGenerateFlashcards: _generateFlashcards,
        );
      case QuizStatus.generating:
        return const QuizSkeleton();
      case QuizStatus.multipleChoice:
        return _MultipleChoiceQuiz(state: state);
      case QuizStatus.flashcard:
        return _FlashcardQuiz(state: state);
      case QuizStatus.result:
        return _QuizResult(
          state: state,
          onRetake: () {
            final quizId = state.activeQuizId;
            if (quizId != null) {
              context.read<QuizBloc>().add(SavedQuizOpened(quizId));
            }
          },
          onBackToLibrary: _backToLibrary,
        );
      case QuizStatus.failure:
        return _QuizError(
          message: state.message ?? 'Could not load quiz data.',
          onRetry: _loadLibrary,
        );
    }
  }
}

class _QuizLibrary extends StatelessWidget {
  final QuizState state;
  final VoidCallback onGenerateQuiz;
  final VoidCallback onGenerateFlashcards;

  const _QuizLibrary({
    required this.state,
    required this.onGenerateQuiz,
    required this.onGenerateFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    final library = state.library;

    if (library == null) return const QuizSkeleton();

    final isCompletelyEmpty =
        library.flashcardSets.isEmpty && library.quizzes.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Generate new:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: library.hasMaterials ? onGenerateQuiz : null,
                icon: const Icon(Icons.quiz),
                label: const Text('Multiple Choice'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: library.hasMaterials ? onGenerateFlashcards : null,
                icon: const Icon(Icons.style),
                label: const Text('FlashCard'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (isCompletelyEmpty) ...[
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No quizzes or flashcards yet',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate your first set above',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[

          if (library.flashcardSets.isEmpty)
            const SizedBox()
          else
            for (var i = 0; i < library.flashcardSets.length; i++) ...[
              FlashcardCard(
                title: 'Flashcard Set ${library.flashcardSets.length - i}',
                subtitle: '${library.flashcardSets[i].cards.length} cards',
                onTap: () {
                  context.read<QuizBloc>().add(
                        SavedFlashcardSetOpened(
                            library.flashcardSets[i]),
                      );
                },
              ),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 24),

          if (library.quizzes.isEmpty)
            const SizedBox()
          else
            for (var i = 0; i < library.quizzes.length; i++) ...[
              QuizCard(
                title: 'Multiple Choice Set ${library.quizzes.length - i}',
                subtitle: _dateLabel(library.quizzes[i].createdAt),
                onTap: () {
                  context.read<QuizBloc>().add(
                        SavedQuizOpened(library.quizzes[i].id),
                      );
                },
              ),
              const SizedBox(height: 8),
            ],
        ],
      ],
    );
  }

  String _dateLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Saved quiz';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
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
  final VoidCallback onRetake;
  final VoidCallback onBackToLibrary;

  const _QuizResult({
    required this.state,
    required this.onRetake,
    required this.onBackToLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final isFlashcard = state.session?.mode == QuizMode.flashcard;
    final title = isFlashcard ? 'Review complete' : 'Quiz complete';
    final scoreLabel = isFlashcard ? 'Reviewed' : 'Score';

    return ListView(
      padding: const EdgeInsets.all(20),
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '$scoreLabel: ${state.score} / ${state.totalItems}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (!isFlashcard) ...[
          const SizedBox(height: 20),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final result in state.quizHistory) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text('Score ${result.score} / ${state.totalItems}'),
                subtitle: Text(_dateLabel(result.takenAt)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 24),
        if (!isFlashcard)
          FilledButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Quiz'),
          ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onBackToLibrary,
          child: const Text('Back to Quiz List'),
        ),
      ],
    );
  }

  String _dateLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Saved attempt';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}

class _QuizError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuizError({required this.message, required this.onRetry});

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
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
