import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studywise/features/app_state_bloc.dart';
import 'package:studywise/features/study_material/ui/widgets/study_material_file_picker.dart';
import 'package:studywise/shared/widgets/theme_mode_button.dart';
import '../bloc/topic_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _folderController = TextEditingController();
  StudyMaterialPickedFile? _selectedFile;

  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();

    if (user != null) {
      context.read<TopicBloc>().add(
            LoadTopicsRequested(user!.id),
          );
    }
  }

  Future<void> _showCreateFolderDialog(
    BuildContext rootContext,
    String userId,
  ) async {
    _selectedFile = null;
    _folderController.clear();

    final topicBloc = rootContext.read<TopicBloc>();

    return showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: topicBloc,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text('New Topic'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _folderController,
                      decoration: const InputDecoration(
                        hintText: 'Enter topic name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final pickedFile = await pickStudyMaterialFile(ctx);
                          if (pickedFile == null) return;

                          setStateDialog(() {
                            _selectedFile = pickedFile;
                          });
                        } catch (error) {
                          if (!rootContext.mounted) return;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                error
                                    .toString()
                                    .replaceFirst('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose File'),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(_selectedFile!.name),
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

                      if (folderName.isEmpty || _selectedFile == null) {
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a topic name and choose a file.',
                            ),
                          ),
                        );
                        return;
                      }

                      topicBloc.add(
                        CreateTopicRequested(
                          userId: userId,
                          folderName: folderName,
                          fileName: _selectedFile!.name,
                          fileType: _selectedFile!.fileType,
                          fileBytes: _selectedFile!.bytes,
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
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          const ThemeModeButton(),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.read<AppStateCubit>().clearSelection();
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: BlocConsumer<TopicBloc, TopicState>(
        listener: (context, state) {
          if (state is TopicActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }

          if (state is TopicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user!.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => _showCreateFolderDialog(context, user!.id),
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create Topic'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is TopicLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is TopicLoaded) {
                      if (state.topics.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Create a topic to start studying.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: state.topics.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final folder = state.topics[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(folder.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                context.read<AppStateCubit>().selectFolder(
                                      userId: user!.id,
                                      folderName: folder.name,
                                    );

                                context.go('/source');
                              },
                            ),
                          );
                        },
                      );
                    }

                    return const Center(
                      child: Text('Load topics'),
                    );
                  },
                ),
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
