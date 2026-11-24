import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';

class PhotoReviewButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dark;
  final VoidCallback onPressed;
  const PhotoReviewButton({
    super.key,
    required this.icon,
    required this.dark,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.md,
          children: [
            Icon(icon, color: dark ? colors.primary : Colors.black),
            Text(
              text,
              style: TextStyle(
                fontSize: AppFontSizes.title,
                color: dark ? colors.primary : Colors.black,
              ),
            ),
          ],
        ),
        style: FilledButton.styleFrom(
          backgroundColor: dark
              ? Colors.black
              : Theme.of(context).colorScheme.primary,
          overlayColor: Colors.white,
          side: dark
              ? const BorderSide(
                  color: Colors.grey, // Your desired border color
                  width: 2.0, // Border thickness (defaults to 1.0)
                )
              : null,
        ),
      ),
    );
  }
}
