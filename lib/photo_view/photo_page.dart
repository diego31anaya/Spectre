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
  bool _isDeleting = false;

  Future<void> _deletePhoto() async {
    if (_isDeleting) return;

    final repository = context.read<PhotoRepository>();

    setState(() => _isDeleting = true);

    try {
      await repository.deletePhoto(widget.photo);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isDeleting = false);

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
                  onPressed: _isDeleting ? null : _deletePhoto,
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
