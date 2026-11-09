import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  const PrimaryButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: () {},
        child: Text(
          text,
          style: TextStyle(fontSize: 24),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
