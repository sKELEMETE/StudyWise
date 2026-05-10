import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum StudyMaterialUploadType {
  pdf(label: 'Upload PDF', icon: Icons.picture_as_pdf, extensions: ['pdf']),
  image(
    label: 'Upload Image',
    icon: Icons.image,
    extensions: ['jpg', 'jpeg', 'png'],
  );

  const StudyMaterialUploadType({
    required this.label,
    required this.icon,
    required this.extensions,
  });

  final String label;
  final IconData icon;
  final List<String> extensions;
}

class StudyMaterialPickedFile {
  final String name;
  final String fileType;
  final Uint8List bytes;

  const StudyMaterialPickedFile({
    required this.name,
    required this.fileType,
    required this.bytes,
  });
}

Future<StudyMaterialPickedFile?> pickStudyMaterialFile(
  BuildContext context,
) async {
  final uploadType = await showModalBottomSheet<StudyMaterialUploadType>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose file type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final type in StudyMaterialUploadType.values) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, type),
                  icon: Icon(type.icon),
                  label: Text(type.label),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || uploadType == null) return null;

  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: uploadType.extensions,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    throw Exception('Could not read the selected file.');
  }

  return StudyMaterialPickedFile(
    name: file.name,
    fileType: file.extension?.toLowerCase() ?? uploadType.extensions.first,
    bytes: bytes,
  );
}
