import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PhotoZoomDialog extends StatelessWidget {
  final String photoPath;
  final String title;

  const PhotoZoomDialog({
    super.key,
    required this.photoPath,
    required this.title,
  });

  static void show(BuildContext context, String photoPath, String title) {
    showDialog(
      context: context,
      builder: (_) => PhotoZoomDialog(photoPath: photoPath, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    final exists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMain),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neonCyan, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.bgCard,
              ),
              constraints: const BoxConstraints(maxHeight: 460),
              child: exists
                  ? Image.file(
                      file,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Image file not found'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
