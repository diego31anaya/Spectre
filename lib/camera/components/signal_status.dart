import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';

class SignalStatus extends StatefulWidget {
  const SignalStatus({super.key});

  @override
  State<SignalStatus> createState() => _SignalStatusState();
}

class _SignalStatusState extends State<SignalStatus> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Signal", style: TextStyle(fontSize: AppFontSizes.subtitle, height: 1.0)),
          Text(
            "High",
            style: TextStyle(
              color: colors.primary,
              fontSize: AppFontSizes.title,
            ),
          ),
          LinearProgressIndicator(
            value: 0.85,
            backgroundColor: colors.tertiary,
            color: colors.primary,
          ),
          Center(child: Text("Hold steady. It's close.", style: TextStyle(fontSize: AppFontSizes.text),)),
        ],
      ),
    );
  }
}
