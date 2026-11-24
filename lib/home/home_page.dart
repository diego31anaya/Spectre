import 'package:flutter/material.dart';
import 'package:spectre/components/primary_button.dart';
import 'package:spectre/constants/app_sizes.dart';

import 'components/device_status.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenCamera;

  const HomePage({super.key, required this.onOpenCamera});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DeviceStatus(),
                PrimaryButton(
                  text: "Initialize Camera",
                  onPressed: widget.onOpenCamera,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
