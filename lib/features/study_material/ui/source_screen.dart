import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:studywise/features/study_material/bloc/source_bloc.dart';

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

    context.read<SourceBloc>().add(
          LoadSourceRequested(
            userId: widget.userId,
            folderName: widget.folderName,
          ),
        );
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      withData: true,
    );

    if (!mounted) return;

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null) return;

    context.read<SourceBloc>().add(
          UploadFileRequested(
            userId: widget.userId,
            folderName: widget.folderName,
            fileName: file.name,
            fileType: file.extension ?? 'unknown',
            fileBytes: bytes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _uploadFile,
                  icon: const Icon(Icons.add),
                  label: Text(loading ? 'Uploading...' : 'Add File'),
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (_) {
                    if (state is SourceLoading && state is! SourceLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is SourceLoaded) {
                      if (state.files.isEmpty) {
                        return const Center(
                          child: Text('No files found'),
                        );
                      }

                      return ListView.builder(
                        itemCount: state.files.length,
                        itemBuilder: (context, index) {
                          final file = state.files[index];

                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(file.name),
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