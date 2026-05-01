import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/features/study_material/bloc/source_bloc.dart';
import 'package:studywise/features/study_material/ui/widgets/study_material_file_picker.dart';
import 'package:studywise/shared/widgets/theme_mode_button.dart';

class SourceScreen extends StatefulWidget {
  final String folderName;
  final String userId;

  const SourceScreen({
    super.key,
    required this.folderName,
    required this.userId,
  });

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  @override
  void initState() {
    super.initState();

    _loadFiles();
  }

  @override
  void didUpdateWidget(covariant SourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId ||
        oldWidget.folderName != widget.folderName) {
      _loadFiles();
    }
  }

  void _loadFiles() {
    context.read<SourceBloc>().add(
          LoadSourceRequested(
            userId: widget.userId,
            folderName: widget.folderName,
          ),
        );
  }

  Future<void> _uploadFile() async {
    late final StudyMaterialPickedFile? file;
    try {
      file = await pickStudyMaterialFile(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    if (!mounted || file == null) return;

    context.read<SourceBloc>().add(
          UploadFileRequested(
            userId: widget.userId,
            folderName: widget.folderName,
            fileName: file.name,
            fileType: file.fileType,
            fileBytes: file.bytes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: const [ThemeModeButton()],
      ),
      body: BlocConsumer<SourceBloc, SourceState>(
        listener: (context, state) {
          if (state is SourceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }

          if (state is SourceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is SourceLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: loading ? null : _uploadFile,
                  icon: const Icon(Icons.add),
                  label: Text(loading ? 'Uploading...' : 'Add File'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (state is SourceLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is SourceLoaded) {
                      if (state.files.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No files in this topic yet.',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: state.files.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = state.files[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(file.name),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
