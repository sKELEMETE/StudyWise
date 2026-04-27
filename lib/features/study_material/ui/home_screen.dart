import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/topic_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _folderController = TextEditingController();
  PlatformFile? _selectedFile;
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      context.read<TopicBloc>().add(LoadTopicsRequested(user!.id));
    }
  }

  Future<void> _showCreateFolderDialog(BuildContext context, String userId) async {
    _selectedFile = null;
    _folderController.clear();

    final topicBloc = context.read<TopicBloc>();

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: topicBloc,
          child: StatefulBuilder(
            builder: (builderContext, setStateDialog) {
              return AlertDialog(
                title: const Text('New Topic'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _folderController,
                      decoration: const InputDecoration(hintText: 'Enter topic name'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(withData: true);
                        if (result != null && result.files.isNotEmpty) {
                          setStateDialog(() => _selectedFile = result.files.first);
                        }
                      },
                      child: const Text('Pick a File'),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text('Selected: ${_selectedFile!.name}'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final folderName = _folderController.text.trim();
                      
                      if (folderName.isEmpty || _selectedFile == null || _selectedFile!.bytes == null) {
                        ScaffoldMessenger.of(builderContext).showSnackBar(
                          const SnackBar(content: Text('Enter topic name and pick file'))
                        );
                        return;
                      }

                      topicBloc.add(
                        CreateTopicRequested(
                          userId: userId,
                          folderName: folderName,
                          fileName: _selectedFile!.name,
                          fileType: _selectedFile!.extension ?? 'unknown',
                          fileBytes: _selectedFile!.bytes!,
                        ),
                      );
                      
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async => await Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: BlocConsumer<TopicBloc, TopicState>(
        listener: (context, state) {
          if (state is TopicActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message))
            );
          } else if (state is TopicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.red)))
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Welcome ${user?.email ?? "User"}'),
              ),
              ElevatedButton(
                onPressed: () => _showCreateFolderDialog(context, user!.id),
                child: const Text('Create New Topic'),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  if (state is TopicLoading) return const Center(child: CircularProgressIndicator());
                  
                  if (state is TopicLoaded) {
                    if (state.topics.isEmpty) return const Center(child: Text('No topics found'));
                    
                    return ListView.builder(
                      itemCount: state.topics.length,
                      itemBuilder: (context, index) {
                        final folder = state.topics[index];
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder.name),
                          onTap: () => context.push('/source/${folder.name}'),
                        );
                      },
                    );
                  }
                  
                  return const Center(child: Text('Failed to load topics'));
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }
}