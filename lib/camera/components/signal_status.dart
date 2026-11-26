import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';

class SignalStatus extends StatelessWidget {
  final double signal;
  final String label;
  final String message;

  const SignalStatus({
    super.key,
    required this.signal,
    required this.label,
    required this.message,
  });


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Signal",
          style: TextStyle(fontSize: AppFontSizes.subtitle, height: 1.0),
        ),
        Text(
          label,
          style: TextStyle(
            color: colors.primary,
            fontSize: AppFontSizes.title,
          ),
        ),
        LinearProgressIndicator(
          value: signal,
          backgroundColor: colors.tertiary,
          color: colors.primary,
        ),
        Center(
          child: Text(
            message,
            style: TextStyle(fontSize: AppFontSizes.text),
          ),
        ),
      ],
    );
  }
}
