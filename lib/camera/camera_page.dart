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

    return Center(child: CameraPreview(cameraController!));
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
                  isFlashlightOn: isFlashlightOn,
                  onToggleFlashlight:
                      cameraController?.value.isInitialized == true &&
                          !isTogglingFlashlight
                      ? _toggleFlashlight
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
