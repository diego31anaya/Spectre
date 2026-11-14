import 'package:flutter/material.dart';
import 'package:spectre/constants/app_sizes.dart';

class CameraButtons extends StatefulWidget {
  final bool isFlashlightOn;
  final VoidCallback? onToggleFlashlight;

  const CameraButtons({super.key, required this.isFlashlightOn, required this.onToggleFlashlight});

  @override
  State<CameraButtons> createState() => _CameraButtonsState();
}

class _CameraButtonsState extends State<CameraButtons> {
  Widget _captureButton() {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: () {},
      icon: const Icon(Icons.camera_alt_outlined),
      iconSize: 28,
      style: IconButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        padding: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  Widget _flashlightButton() {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: widget.onToggleFlashlight,
      icon: Icon(widget.isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off),
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        padding: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Column(
        spacing: AppSpacing.xs,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: SizedBox()),
              _captureButton(),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _flashlightButton(),
                ),
              ),
            ],
          ),
          Text(
            "CAPTURE GHOST",
            style: TextStyle(
              color: colors.primary,
              fontSize: AppFontSizes.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
