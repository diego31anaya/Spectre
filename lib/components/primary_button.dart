import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: AppFontSizes.title),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          overlayColor: Colors.white
        ),
      ),
    );
  }
}
