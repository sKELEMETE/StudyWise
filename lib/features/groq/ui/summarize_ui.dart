import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/groq/bloc/groq_bloc.dart';

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

    final bloc = context.read<AiBloc>();
    final state = bloc.state;

    if (state is! AiSuccess) {
      bloc.add(
        AiSummarizeRequested(
          userId: widget.userId,
          folderName: widget.folderName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary: ${widget.folderName}'),
      ),
      body: BlocBuilder<AiBloc, AiState>(
        builder: (context, state) {
          if (state is AiLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AiSuccess) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(state.result),
              ),
            );
          }

          if (state is AiError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('Generating summary...'));
        },
      ),
    );
  }
}