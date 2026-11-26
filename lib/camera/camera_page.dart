import 'dart:async';
import 'dart:math';

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

import 'package:flutter/services.dart';

enum EncounterPhase { searching, approaching, nearby }

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

  Timer? _signalTimer;
  final Random _random = Random();

  EncounterPhase _phase = EncounterPhase.searching;

  double _signal = 0.1;
  int _phaseTicks = 0;
  int _phaseDuration = 0;

  bool _isAppActive = true;

  String get _signalLabel {
    return switch (_phase) {
      EncounterPhase.searching => 'Low',
      EncounterPhase.approaching => 'Rising',
      EncounterPhase.nearby => 'High',
    };
  }

  String get _signalMessage {
    return switch (_phase) {
      EncounterPhase.searching => 'Scanning for activity...',
      EncounterPhase.approaching => 'Something is getting closer...',
      EncounterPhase.nearby => "It's close. Capture now!",
    };
  }

  // Updates the phase values
  void _enterPhase(EncounterPhase phase) {
    _phase = phase;
    _phaseTicks = 0;

    // Two ticks per second because the timer runs every 0.5 seconds
    _phaseDuration = switch (phase) {
      EncounterPhase.searching => (5 + _random.nextInt(6)) * 2,
      EncounterPhase.approaching => (3 + _random.nextInt(3)) * 2,
      EncounterPhase.nearby => (3 + _random.nextInt(2)) * 2,
    };

    _signal = switch (phase) {
      EncounterPhase.searching => 0.1,
      EncounterPhase.approaching => 0.35,
      EncounterPhase.nearby => 0.9,
    };
  }

  void _startEncounter() {
    _signalTimer?.cancel();

    if (!mounted ||
        !_isAppActive ||
        isCapturing ||
        capturedPhoto != null ||
        cameraController?.value.isInitialized != true) {
      return;
    }

    setState(() {
      _enterPhase(EncounterPhase.searching);
    });

    _signalTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted ||
          !_isAppActive ||
          isCapturing ||
          capturedPhoto != null ||
          cameraController?.value.isInitialized != true) {
        _signalTimer?.cancel();
        return;
      }

      setState(() {
        _phaseTicks++;

        if (_phaseTicks >= _phaseDuration) {
          final nextPhase = switch (_phase) {
            EncounterPhase.searching => EncounterPhase.approaching,
            EncounterPhase.approaching => EncounterPhase.nearby,
            EncounterPhase.nearby => EncounterPhase.searching,
          };
          _enterPhase(nextPhase);
        }

        _signal = switch (_phase) {
          EncounterPhase.searching => 0.1 + _random.nextDouble() * 0.25,
          EncounterPhase.approaching =>
            0.35 + 0.45 * (_phaseTicks / _phaseDuration),
          EncounterPhase.nearby => 0.85 + _random.nextDouble() * 0.15,
        };
      });
    });
  }

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

    if (!_isAppActive ||
        controller == null ||
        !controller.value.isInitialized ||
        isCapturing ||
        capturedPhoto != null) {
      return;
    }

    final caughtGhost = _phase == EncounterPhase.nearby;

    final nightVision = isNightVisionOn;
    XFile? ghostPhoto;

    if (caughtGhost) {
      try {
        _signalTimer?.cancel();
        setState(() => isCapturing = true);

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

          if (capturedPhoto == null) {
            _startEncounter();
          }
        }
      }
    } else {
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No ghost nearby. Wait for a high signal!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: AppFontSizes.text,
            ),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
          duration: const Duration(seconds: 2),
        ),
      );

      await HapticFeedback.heavyImpact();
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
    _signalTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;

    if (!_isAppActive) {
      _signalTimer?.cancel();
    }

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
        _startEncounter();
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

    _startEncounter();
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
                  SignalStatus(
                    signal: _signal,
                    label: _signalLabel,
                    message: _signalMessage,
                  ),
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
