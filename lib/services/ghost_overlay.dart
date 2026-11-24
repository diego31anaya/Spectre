import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GhostOverlay {
  static const nightVisionFilter = ui.ColorFilter.matrix([
    0.17, 0.57, 0.06, 0, -12,
    0.22, 0.74, 0.08, 0, -12,
    0.16, 0.54, 0.05, 0, -12,
    0, 0, 0, 1, 0,
  ]);

  static Future<String> _randomGhostAsset() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final ghosts = manifest.listAssets().where((asset) {
      return p.dirname(asset) == 'assets/images' &&
          p.basename(asset).toLowerCase().startsWith('ghost') &&
          p.extension(asset).toLowerCase() == '.png';
    }).toList();

    if (ghosts.isEmpty) {
      throw StateError('No ghost PNG assets found in assets/images.');
    }

    return ghosts[Random().nextInt(ghosts.length)];
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static Future<XFile> apply(
    XFile photo, {
    bool nightVision = false,
  }) async {
    final ghostAsset = await _randomGhostAsset();
    final background = await _decodeImage(await photo.readAsBytes());

    ui.Image? ghost;
    ui.Image? combined;
    ui.Picture? drawing;

    try {
      final asset = await rootBundle.load(ghostAsset);
      ghost = await _decodeImage(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      );

      final width = background.width.toDouble();
      final height = background.height.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Filter the photo and ghost together when this layer is restored.
      if (nightVision) {
        canvas.saveLayer(
          ui.Rect.fromLTWH(0, 0, width, height),
          ui.Paint()..colorFilter = nightVisionFilter,
        );
      }

      // Draw the captured photo at its original size.
      canvas.drawImage(background, ui.Offset.zero, ui.Paint());

      // Fit the ghost inside the photo without stretching it.
      final widthScale = width / ghost.width;
      final heightScale = height / ghost.height;
      final scale = widthScale < heightScale ? widthScale : heightScale;

      final ghostWidth = ghost.width * scale;
      final ghostHeight = ghost.height * scale;

      final source = ui.Rect.fromLTWH(
        0,
        0,
        ghost.width.toDouble(),
        ghost.height.toDouble(),
      );

      final destination = ui.Rect.fromLTWH(
        (width - ghostWidth) / 2,
        (height - ghostHeight) / 2,
        ghostWidth,
        ghostHeight,
      );

      // Transparent areas of the PNG reveal the photo below.
      canvas.drawImageRect(
        ghost,
        source,
        destination,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );

      if (nightVision) {
        canvas.restore();
      }

      drawing = recorder.endRecording();
      combined = await drawing.toImage(background.width, background.height);

      final bytes = await combined.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        throw StateError('Unable to encode the combined photo.');
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final file = File(
        p.join(temporaryDirectory.path, 'ghost_$timestamp.png'),
      );

      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      return XFile(file.path);
    } finally {
      // Release the decoded images from memory.
      background.dispose();
      ghost?.dispose();
      combined?.dispose();
      drawing?.dispose();
    }
  }
}
