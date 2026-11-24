import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';
import 'package:spectre/services/photo_storage.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<List<File>> _photos;

  @override
  void initState() {
    super.initState();
    _photos = PhotoStorage.loadPhotos();
  }

  void _reloadPhotos() {
    setState(() {
      _photos = PhotoStorage.loadPhotos();
    });
  }

  Future<void> _confirmDeletePhoto(File photo) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
          'This permanently removes the photo from Spectre. '
          'Your phone’s gallery copy will remain.',
        ),
        actions: [ TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),],
      );
    });

    if (confirmed != true || !mounted) return;

    try {
      await PhotoStorage.deletePhoto(photo);

      if (!mounted) return;
      _reloadPhotos();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to delete the photo. Please try again.')),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: FutureBuilder<List<File>>(
        future: _photos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Unable to load your collection."),
                  TextButton(
                    onPressed: _reloadPhotos,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Text(
                "No evidence collected yet.",
                style: TextStyle(
                  color: colors.primary,
                  fontSize: AppFontSizes.title,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Captured Evidence', style: TextStyle(color: colors.primary, fontSize: AppFontSizes.text),), Text('${photos.length} Found', style: TextStyle(fontSize: AppFontSizes.text),)],
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];


                      return GestureDetector(
                        key: ValueKey(photo.path),
                        onLongPress: () => _confirmDeletePhoto(photo),
                        child: Image.file(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image_outlined),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
