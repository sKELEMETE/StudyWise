import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/groq/bloc/ai_bloc.dart';

class SummaryTab extends StatelessWidget {
  final String folderName;
  final String userId;

  const SummaryTab({
    super.key,
    required this.folderName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Summary: $folderName')),
      body: BlocBuilder<AiBloc, AiState>(
        builder: (context, state) {
          if (state is AiLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AiSuccess) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.read<AiBloc>().add(
                            AiReSummarizeRequested(
                              folderName: folderName,
                              userId: userId,
                            ),
                          );
                    },
                    child: const Text('Re-summarize'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(state.result),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is AiError) {
            return Center(child: Text(state.message));
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<AiBloc>().add(
                      AiSummarizeRequested(
                        folderName: folderName,
                        userId: userId,
                      ),
                    );
              },
              child: const Text('Generate Summary'),
            ),
          );
        },
      ),
    );
  }
}