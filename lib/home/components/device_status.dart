import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spectre/constants/app_sizes.dart';
import 'package:spectre/themes/dark_mode.dart';

class DeviceStatus extends StatefulWidget {
  const DeviceStatus({super.key});

  @override
  State<DeviceStatus> createState() => _DeviceStatusState();
}

class _DeviceStatusState extends State<DeviceStatus>
    with WidgetsBindingObserver {
  bool? cameraPermission;
  bool cameraPermissionError = false;
  bool _floatingMessageVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        cameraPermission != null &&
        !cameraRequestInProgress) {
      _refreshCameraPermission();
    }
  }

  Future<void> _refreshCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (!mounted) return;

      setState(() {
        cameraPermission = status.isGranted;
        cameraPermissionError = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Camera permission refresh failed: $error\n$stackTrace');
      if (!mounted) return;

      setState(() {
        cameraPermission = false;
        cameraPermissionError = true;
      });
      _showFloatingMessage(
        'Unable to check camera access. Tap Camera to retry.',
      );
    }
  }

  void _showFloatingMessage(String message, {bool showSettings = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    messenger.hideCurrentSnackBar();
    setState(() => _floatingMessageVisible = true);
    final messageController = messenger.showSnackBar(
      SnackBar(
        backgroundColor: colors.secondary,
        content: Text(
          message,
          style: TextStyle(fontSize: AppFontSizes.subtitle, color: colors.onPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppSpacing.md),
        action: showSettings
            ? SnackBarAction(
                label: 'Settings',
                textColor: colors.onPrimary,
                onPressed: () async {
                  await openAppSettings();
                },
              )
            : null,
      ),
    );
    messageController.closed.then((_) {
      if (mounted) {
        setState(() => _floatingMessageVisible = false);
      }
    });
  }

  Future<void> _loadInitialPermissions() async {
    try {
      var status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();

        if (status.isGranted) {
          if (!mounted) return;
          setState(() {
            cameraPermission = status.isGranted;
          });
        } else {
          if (!mounted) return;
          setState(() => cameraPermission = false);
          if (status.isPermanentlyDenied) {
            _showFloatingMessage(
              'Enable camera access in Settings.',
              showSettings: true,
            );
          } else {
            _showFloatingMessage(
              'Camera access is needed to scan your surroundings.',
            );
          }
        }
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => cameraPermission = false);
        _showFloatingMessage(
          'Enable camera access in Settings.',
          showSettings: true,
        );
      } else if (status.isGranted) {
        if (!mounted) return;
        setState(() {
          cameraPermission = true;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Camera permission check failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        cameraPermission = false;
        cameraPermissionError = true;
      });
      _showFloatingMessage(
        'Unable to check camera access. Tap Camera to retry.',
      );
    }
  }

  bool cameraRequestInProgress = false;
  Future<void> _onCameraPressed() async {
    if (cameraRequestInProgress || _floatingMessageVisible) return;
    setState(() {
      cameraRequestInProgress = true;
      cameraPermissionError = false;
    });

    try {
      var status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();

        if (status.isGranted) {
          if (!mounted) return;
          setState(() {
            cameraPermission = status.isGranted;
          });
        } else {
          if (!mounted) return;
          setState(() => cameraPermission = false);
          if (status.isPermanentlyDenied) {
            _showFloatingMessage(
              'Enable camera access in Settings.',
              showSettings: true,
            );
          } else {
            _showFloatingMessage(
              'Camera access is needed to scan your surroundings.',
            );
          }
        }
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => cameraPermission = false);
        _showFloatingMessage(
          'Enable camera access in Settings.',
          showSettings: true,
        );
      } else if (status.isGranted) {
        if (!mounted) return;
        setState(() {
          cameraPermission = true;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Camera permission check failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        cameraPermission = false;
        cameraPermissionError = true;
      });
      _showFloatingMessage(
        'Unable to check camera access. Tap Camera to retry.',
      );
    } finally {
      if (mounted) {
        setState(() => cameraRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget statusRow(String label, bool? ready) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                cameraPermission == null ||
                    cameraRequestInProgress ||
                    _floatingMessageVisible
                ? null
                : _onCameraPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF101610),
              side: BorderSide(color: colors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: darkMode.colorScheme.primary,
                  ),
                ),
                Text(
                  cameraPermissionError
                      ? 'Check Failed'
                      : ready == null
                      ? 'Loading...'
                      : ready == true
                      ? 'Ready'
                      : 'Needs Access',
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    color: darkMode.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Device Status",
          style: TextStyle(fontSize: AppFontSizes.title, color: darkMode.colorScheme.primary),
        ),
        Column(children: [statusRow("Camera", cameraPermission)]),
      ],
    );
  }
}
