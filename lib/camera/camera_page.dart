import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:spectre/camera/components/buttons/camera_buttons.dart';
import 'package:spectre/camera/components/photo_review_controls.dart';
import 'package:spectre/camera/components/signal_status.dart';
import 'package:spectre/constants/app_sizes.dart';
import 'package:spectre/services/ghost_overlay.dart';
import 'package:spectre/services/photo_storage.dart';

import 'dart:io';

class CameraPage extends StatefulWidget {
  final VoidCallback onViewCollection;

  const CameraPage({super.key, required this.onViewCollection});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  bool isFlashlightOn = false;
  bool isTogglingFlashlight = false;

  bool isNightVisionOn = false;

  XFile? capturedPhoto;
  bool isCapturing = false;

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

  Future<void> _capturePhoto() async {
    final controller = cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        isCapturing ||
        capturedPhoto != null) {
      return;
    }

    setState(() => isCapturing = true);

    final nightVision = isNightVisionOn;
    XFile? ghostPhoto;

    try {
      final picture = await controller.takePicture();

      ghostPhoto = await GhostOverlay.apply(
        picture,
        nightVision: nightVision,
      );

      final savedPhoto = await PhotoStorage.savePhoto(ghostPhoto);

      if (!mounted) return;

      setState(() => capturedPhoto = XFile(savedPhoto.path));

      await Gal.putImage(savedPhoto.path);
    } on CameraException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to take the photo.')),
      );
    } on GalException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo saved to Collection, but gallery saving failed.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process or save the photo.')),
      );
    } finally {
      // The collection has its own copy, so remove the temporary composite.
      if (ghostPhoto != null) {
        try {
          await File(ghostPhoto.path).delete();
        } on FileSystemException {
          // Temporary-file cleanup should not interrupt the camera.
        }
      }
      if (mounted) {
        setState(() => isCapturing = false);
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
    if (capturedPhoto == null &&
        (cameraController == null || !cameraController!.value.isInitialized)) {
      return const Center(child: CircularProgressIndicator());
    }

    final Widget preview = capturedPhoto != null
        ? Image.file(File(capturedPhoto!.path), fit: BoxFit.contain)
        : CameraPreview(cameraController!);

    return Center(
      child: isNightVisionOn && capturedPhoto == null
          ? ColorFiltered(
              colorFilter: GhostOverlay.nightVisionFilter,
              child: preview,
            )
          : preview,
    );
  }

  void _keepScanning() {
    if (isCapturing) return;

    setState(() => capturedPhoto = null);
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
                if (capturedPhoto == null) ...[
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
                    onCaptured:
                        cameraController?.value.isInitialized == true &&
                            !isCapturing &&
                            capturedPhoto == null
                        ? _capturePhoto
                        : null,
                  ),
                ] else ...[
                  PhotoReviewControls(
                    onViewCollection: widget.onViewCollection,
                    onKeepScanning: _keepScanning,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
