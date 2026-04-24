import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../datasource/study_material/storage_service.dart';
import '../../datasource/study_material/extraction_service.dart';

final storageService = StorageService();
final extractionService = ExtractionService();

class SourceScreen extends StatefulWidget {
  final String folderName;

  const SourceScreen({super.key, required this.folderName});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final String userId = Supabase.instance.client.auth.currentUser!.id;
  bool _isUploading = false;

  Future<void> _uploadFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    
    if (file.bytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await extractionService.processMaterial(
        folderName: widget.folderName,
        fileName: file.name,
        fileBytes: file.bytes!,
      );
      
      debugPrint('Extraction Response: $response');
      
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded and processed successfully')),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: const Icon(Icons.add),
              label: Text(_isUploading ? 'Uploading...' : 'Add File'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FileObject>>(
              future: storageService.listFilesInFolder(userId, widget.folderName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading files'));
                }

                final items = snapshot.data;

                if (items == null || items.isEmpty) {
                  return const Center(child: Text('No files found in this topic'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final file = items[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.name),
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
}