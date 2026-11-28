import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spectre/components/primary_button.dart';
import 'package:spectre/constants/app_sizes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:spectre/services/photo_repository.dart';

class PhotoPage extends StatefulWidget {
  final File photo;

  const PhotoPage({super.key, required this.photo});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {

  Future<void> _deletePhoto() async {

    final repository = context.read<PhotoRepository>();


    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete photo?'),
          content: const Text(
            'This permanently removes the photo from Spectre. '
            'Your phone’s gallery copy will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await repository.deletePhoto(widget.photo);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the photo. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ghost Photo"), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: Center(
                    child: Image.file(
                      widget.photo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined),
                        );
                      },
                    ),
                  ),
                ),
                Builder(
                  builder: (buttonContext) {
                    return PrimaryButton(
                      text: 'Send to a Friend',
                      onPressed: () async {
                        final box =
                            buttonContext.findRenderObject() as RenderBox?;

                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(widget.photo.path)],
                              sharePositionOrigin: box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to share the photo. Please try again.',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                TextButton(
                  onPressed: _deletePhoto,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: AppFontSizes.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
