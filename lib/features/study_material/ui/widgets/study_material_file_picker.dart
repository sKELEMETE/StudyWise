import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum StudyMaterialUploadType {
  pdf(
    label: 'PDF',
    icon: Icons.picture_as_pdf_rounded,
    extensions: ['pdf'],
  ),

  image(
    label: 'Image',
    icon: Icons.image_rounded,
    extensions: ['jpg', 'jpeg', 'png'],
  ),

  camera(
    label: 'Camera',
    icon: Icons.photo_camera_rounded,
    extensions: [],
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose file type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 16),

              Row(
  children: [
    Expanded(
      flex: 2,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.pop(
          context,
          StudyMaterialUploadType.pdf,
        ),
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('PDF'),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      flex: 2,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.pop(
          context,
          StudyMaterialUploadType.image,
        ),
        icon: const Icon(Icons.image_rounded),
        label: const Text('Image'),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      flex: 1,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera support coming soon.',
              ),
            ),
          );
        },
        child: const Icon(Icons.photo_camera_rounded),
      ),
    ),
  ],
),
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
    fileType:
        file.extension?.toLowerCase() ??
        uploadType.extensions.first,
    bytes: bytes,
  );
}