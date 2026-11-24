import 'package:flutter/material.dart';
import 'package:spectre/camera/components/buttons/photo_review_button.dart';
import 'package:spectre/constants/app_sizes.dart';

class PhotoReviewControls extends StatefulWidget {
  final VoidCallback onViewCollection;
  final VoidCallback onKeepScanning;

  const PhotoReviewControls({
    super.key,
    required this.onViewCollection,
    required this.onKeepScanning,
  });

  @override
  State<PhotoReviewControls> createState() => _PhotoReviewControlsState();
}

class _PhotoReviewControlsState extends State<PhotoReviewControls> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          Icon(Icons.check, color: colors.primary, size: AppFontSizes.heading),
          Text(
            "Evidence saved to Collection.",
            style: TextStyle(
              color: colors.primary,
              fontSize: AppFontSizes.subtitle,
            ),
          ),
          PhotoReviewButton(
            icon: Icons.camera_alt_outlined,
            text: "Keep Scanning",
            dark: false,
            onPressed: widget.onKeepScanning,
          ),
          PhotoReviewButton(
            icon: Icons.collections_outlined,
            text: "View Collection",
            dark: true,
            onPressed: widget.onViewCollection,
          ),
        ],
      ),
    );
  }
}
