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

  const SummaryTab({
    super.key,
    required this.folderName,
    required this.userId,
  });

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  bool _requestedGeneration = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummaries();
    });
  }

  @override
  void didUpdateWidget(covariant SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      _requestedGeneration = false;
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
        title: Text(widget.folderName),
        actions: const [
          ThemeModeButton(),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<AiBloc, AiState>(
          listener: (context, state) {
            // Auto-generate if no summary exists
            if (state is AiLoaded) {
              if (state.summaries.isEmpty && !_requestedGeneration) {
                _requestedGeneration = true;
                _generateSummary();
              }
            }
          },
          builder: (context, state) {
            if (state is AiLoading || state is AiGenerating) {
              return const SummarySkeleton();
            }

            if (state is AiLoaded) {
              if (state.summaries.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.summarize,
                  message: 'Generating summary...',
                );
              }

              return _SummaryContent(
                summary: state.summaries.first,
                onResummarize: _generateSummary,
              );
            }

            if (state is AiError) {
              return _SummaryError(
                message: state.message,
                onRetry: () {
                  _requestedGeneration = false;
                  _loadSummaries();
                },
              );
            }

            return const SummarySkeleton();
          },
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final SummaryRecord summary;
  final VoidCallback onResummarize;

  const _SummaryContent({
    required this.summary,
    required this.onResummarize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onResummarize,
              icon: const Icon(
                Icons.auto_awesome,
                size: 18,
              ),
              label: const Text(
                'Re-Summarize',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                summary.summaryText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SummaryError({
    required this.message,
    required this.onRetry,
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