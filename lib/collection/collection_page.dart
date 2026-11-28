import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spectre/constants/app_sizes.dart';
import 'package:spectre/photo_view/photo_page.dart';
import 'package:spectre/services/photo_repository.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  Future<void> _confirmDeletePhoto(File photo) async {
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
      await context.read<PhotoRepository>().deletePhoto(photo);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the photo. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final collection = context.watch<PhotoRepository>();
    final photos = collection.photos;

    Widget content;

    if (collection.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (collection.loadError != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(collection.loadError!),
            TextButton(
              onPressed: () {
                context.read<PhotoRepository>().loadPhotos();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (photos.isEmpty) {
      content = Center(
        child: Text(
          'No evidence collected yet.',
          style: TextStyle(color: colors.primary, fontSize: AppFontSizes.title),
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Captured Evidence',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: AppFontSizes.text,
                  ),
                ),
                Text(
                  '${photos.length} Found',
                  style: TextStyle(fontSize: AppFontSizes.text),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PhotoPage(photo: photo),
                        ),
                      );
                    },
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
    }

    return SafeArea(child: content);
  }
}
