import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/groq/bloc/ai_bloc.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';
import 'package:studywise/shared/widgets/app_back_button.dart';
import 'package:studywise/shared/widgets/empty_state_widget.dart';
import 'package:studywise/shared/widgets/skeleton_loaders.dart';
import 'package:studywise/shared/widgets/theme_mode_button.dart';

class SummaryTab extends StatefulWidget {
  final String folderName;
  final String userId;

  const SummaryTab({super.key, required this.folderName, required this.userId});

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  @override
  void didUpdateWidget(covariant SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      _loadSummaries();
    }
  }

  void _loadSummaries() {
    context.read<AiBloc>().add(
      AiSummariesRequested(
        folderName: widget.folderName,
        userId: widget.userId,
      ),
    );
  }

  void _generateSummary() {
    context.read<AiBloc>().add(
      AiSummarizeRequested(
        folderName: widget.folderName,
        userId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('Summary: ${widget.folderName}'),
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: BlocBuilder<AiBloc, AiState>(
          builder: (context, state) {
            if (state is AiLoading) {
              return const SummarySkeleton();
            }

            if (state is AiGenerating) {
              return _SummaryList(
                summaries: state.summaries,
                isGenerating: true,
                onGenerate: null,
              );
            }

            if (state is AiLoaded) {
              return _SummaryList(
                summaries: state.summaries,
                isGenerating: false,
                onGenerate: _generateSummary,
              );
            }

            if (state is AiError) {
              return _SummaryError(
                message: state.message,
                onRetry: _loadSummaries,
              );
            }

            return _SummaryList(
              summaries: const [],
              isGenerating: false,
              onGenerate: _generateSummary,
            );
          },
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  final List<SummaryRecord> summaries;
  final bool isGenerating;
  final VoidCallback? onGenerate;

  const _SummaryList({
    required this.summaries,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(isGenerating ? 'Generating...' : 'Generate Summary'),
          ),
        ),
        if (isGenerating)
          const Expanded(child: SummarySkeleton())
        else if (summaries.isEmpty)
          const Expanded(
            child: EmptyStateWidget(
              icon: Icons.summarize,
              message: 'No saved summaries yet.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: summaries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return Card(
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text('Summary ${summaries.length - index}'),
                    subtitle: Text(_dateLabel(summary.createdAt)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(summary.summaryText),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _dateLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Saved summary';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SummaryError({required this.message, required this.onRetry});

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
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
