import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/ai/bloc/groq_bloc.dart';

class SummarizeButton extends StatelessWidget {
  final String userId;
  final String folderName;

  const SummarizeButton({
    super.key,
    required this.userId,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiBloc, AiState>(
      listener: (context, state) {
        if (state is AiError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AiLoading;

        String? result;
        if (state is AiSuccess) {
          result = state.result;
        }

        return Column(
          children: [
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AiBloc>().add(
                            AiSummarizeRequested(
                              userId: userId,
                              folderName: folderName,
                            ),
                          );
                    },
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Summarize'),
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Text(result),
            ]
          ],
        );
      },
    );
  }
}