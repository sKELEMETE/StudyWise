import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/groq/bloc/ai_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    _summarize();
  }

  @override
  void didUpdateWidget(covariant SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      _summarize();
    }
  }

  void _summarize() {
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
        title: Text('Summary: ${widget.folderName}'),
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: BlocBuilder<AiBloc, AiState>(
          builder: (context, state) {
            if (state is AiLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Summarizing...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is AiSuccess) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _summarize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate Summary'),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Card(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            state.result,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is AiError) {
              return _SummaryError(
                message: state.message,
                onRetry: _summarize,
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: _summarize,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Summary'),
                ),
              ),
            );
          },
        ),
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
