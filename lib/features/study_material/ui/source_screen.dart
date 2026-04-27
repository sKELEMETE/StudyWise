import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../bloc/source_bloc.dart';

class SourceScreen extends StatefulWidget {
  final String folderName;
  const SourceScreen({super.key, required this.folderName});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      context.read<SourceBloc>().add(
        LoadSourceRequested(
          userId: user!.id,
          folderName: widget.folderName,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (user == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      withData: true,
    );

    if (!mounted) return;

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.bytes == null) {
      return;
    }

    final file = result.files.first;

    context.read<SourceBloc>().add(
      UploadFileRequested(
        userId: user!.id,
        folderName: widget.folderName,
        fileName: file.name,
        fileType: file.extension ?? 'unknown',
        fileBytes: file.bytes!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<SourceBloc, SourceState>(
        listener: (context, state) {
          if (state is SourceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SourceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SourceLoading;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _uploadFile,
                  icon: const Icon(Icons.add),
                  label: Text(isLoading ? 'Uploading...' : 'Add File'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is SourceLoading && state is! SourceLoaded) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is SourceLoaded) {
                      if (state.files.isEmpty) {
                        return const Center(
                          child: Text('No files found in this topic'),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.files.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(state.files[index].name),
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