import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:spectre/camera/components/camera_buttons.dart';
import 'package:spectre/camera/components/signal_status.dart';
import 'package:spectre/constants/app_sizes.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  bool isFlashlightOn = false;
  bool isTogglingFlashlight = false;

  bool isNightVisionOn = false;

  void _toggleNightVision() {
  setState(() {
    isNightVisionOn = !isNightVisionOn;
  });
}

  Future<void> _toggleFlashlight() async {
    final controller = cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        isTogglingFlashlight) {
      return;
    }

    final nextValue = !isFlashlightOn;
    setState(() => isTogglingFlashlight = true);

    try {
      await controller.setFlashMode(
        nextValue ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;
      setState(() => isFlashlightOn = nextValue);
    } on CameraException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to change the flashlight.')),
      );
    } finally {
      if (mounted) {
        setState(() => isTogglingFlashlight = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUpCameraController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = cameraController;

      setState(() {
        cameraController = null;
        isFlashlightOn = false;
        isTogglingFlashlight = false;
      });

      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setUpCameraController();
    }
  }

  Future<void> _setUpCameraController() async {
    List<CameraDescription> _cameras = await availableCameras();
    if (!mounted) return;

    final rearCameras = _cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .toList();

    if (rearCameras.isNotEmpty) {
      setState(() {
        cameras = _cameras;
        cameraController = CameraController(
          rearCameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
      });
      cameraController?.initialize().then((_) {
        if (!mounted) return;
        // This causes the widget tree to rebuild
        setState(() {});
      });
    }
  }

  Widget _cameraView() {
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    }

    final preview = CameraPreview(cameraController!);

    return Center(
      child: isNightVisionOn ?  ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          // Mix each pixel into muted green tones with deeper shadows.
          // Retain red and blue for softer, less neon highlights.
          0.17, 0.57, 0.06, 0, -12,
          0.22, 0.74, 0.08, 0, -12,
          0.16, 0.54, 0.05, 0, -12,
          // Preserve opacity.
          0, 0, 0, 1, 0,
        ]),
        child: preview,
       ) : preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ghost Finder"), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Expanded(child: _cameraView()),
                SignalStatus(),
                CameraButtons(
                  isNightVisionOn: isNightVisionOn,
                  isFlashlightOn: isFlashlightOn,
                  onToggleFlashlight:
                      cameraController?.value.isInitialized == true &&
                          !isTogglingFlashlight
                      ? _toggleFlashlight
                      : null,
                  onToggleNightVision: _toggleNightVision,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
