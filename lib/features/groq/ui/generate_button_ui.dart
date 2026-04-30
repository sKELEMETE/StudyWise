import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:studywise/features/groq/bloc/groq_bloc.dart';

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

        if (state is AiSuccess) {
          context.push(
            '/summarize/$folderName',
            extra: {
              'userId': userId,
              'result': state.result,
            },
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AiLoading;

        return ElevatedButton(
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
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Summarize'),
        );
      },
    );
  }
}