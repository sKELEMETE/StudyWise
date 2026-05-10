import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studywise/features/app_state_bloc.dart';
import 'package:studywise/features/study_material/ui/widgets/study_material_file_picker.dart';
import 'package:studywise/shared/widgets/empty_state_widget.dart';
import 'package:studywise/shared/widgets/skeleton_loaders.dart';
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
      context.read<TopicBloc>().add(LoadTopicsRequested(user!.id));
    }
  }

  // 🎨 Stable color per topic name
  Color getColorFromName(String name) {
    final colors = Colors.primaries;
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length].shade100;
  }

  // 🎯 Decide readable color (black or white)
  Color getTextColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;
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
                        final pickedFile =
                            await pickStudyMaterialFile(ctx);

                        if (pickedFile == null) return;

                        setStateDialog(() {
                          _selectedFile = pickedFile;
                        });
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
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final folderName =
                          _folderController.text.trim();

                      if (folderName.isEmpty ||
                          _selectedFile == null) {
                        ScaffoldMessenger.of(rootContext)
                            .showSnackBar(
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
      return const Scaffold(body: Center(child: Text('No user')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyWise'),
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
          ),
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
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (state is TopicLoading) {
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              itemBuilder: (_, __) =>
                                  const ListTileSkeleton(),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemCount: 4,
                            );
                          }

                          if (state is TopicLoaded) {
                            if (state.topics.isEmpty) {
                              return const EmptyStateWidget(
                                icon: Icons.folder_open,
                                message:
                                    'Create a topic to start studying.',
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              itemCount: state.topics.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final folder = state.topics[index];
                                final bgColor =
                                    getColorFromName(folder.name);
                                final textColor =
                                    getTextColor(bgColor);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),

                                    leading: Icon(
                                      Icons.folder,
                                      color: textColor,
                                    ),

                                    title: Text(
                                      folder.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: textColor,
                                    ),

                                    onTap: () {
                                      context
                                          .read<AppStateCubit>()
                                          .selectFolder(
                                            userId: user!.id,
                                            folderName: folder.name,
                                          );

                                      context.push('/source');
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
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 50,
                child: FilledButton.icon(
                  onPressed: () =>
                      _showCreateFolderDialog(context, user!.id),
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('New Topic'),
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