import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../datasource/study_material/storage_service.dart';
import '../../datasource/study_material/extraction_service.dart';

final storageService = StorageService();
final extractionService = ExtractionService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _folderController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isCreating = false;

  Future<void> _showCreateFolderDialog(BuildContext context, String userId) async {
    _selectedFile = null;
    _folderController.clear();

    return showDialog(
      context: context,
      barrierDismissible: !_isCreating,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('New Topic'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _folderController,
                    decoration: const InputDecoration(hintText: 'Enter topic name'),
                    enabled: !_isCreating,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : () async {
                      final result = await FilePicker.pickFiles(
                        withData: true, 
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setStateDialog(() {
                          _selectedFile = result.files.first;
                        });
                      }
                    },
                    child: const Text('Pick a File'),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Text('Selected: ${_selectedFile!.name}'),
                  ],
                  if (_isCreating) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _isCreating ? null : () async {
                    final folderName = _folderController.text.trim();
                    if (folderName.isEmpty || _selectedFile == null || _selectedFile!.bytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a folder name and pick a file')),
                      );
                      return;
                    }

                    setStateDialog(() {
                      _isCreating = true;
                    });

                    try {
                      final response = await extractionService.processMaterial(
                        folderName: folderName,
                        fileName: _selectedFile!.name,
                        fileBytes: _selectedFile!.bytes!,
                      );
                      
                      debugPrint('Extraction Response: $response');

                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Topic created and file processed')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Create folder error: $e');
                      if (context.mounted) {
                        setStateDialog(() {
                          _isCreating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Column(
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
            child: FutureBuilder<List<FileObject>>(
              future: storageService.listUserFolders(user!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading folders'));
                }

                final items = snapshot.data;

                if (items == null || items.isEmpty) {
                  return const Center(child: Text('No topics found'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final folder = items[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      onTap: () {
                        context.push('/source/${folder.name}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }
}