import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:spectre/services/photo_storage.dart';

class PhotoRepository extends ChangeNotifier {
  PhotoRepository({required PhotoStorage storage}) : _storage = storage;

  final PhotoStorage _storage;

  List<File> _photos = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _loadError;
  Future<void>? _loadOperation;

  List<File> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  Future<void> loadPhotos() {
    return _loadOperation ??= _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _photos = await _storage.loadPhotos();
      _hasLoaded = true;
    } catch (_) {
      _loadError = 'Unable to load your collection.';
    } finally {
      _isLoading = false;
      _loadOperation = null;
      notifyListeners();
    }
  }

  Future<void> _ensureLoaded() async {
    final pendingLoad = _loadOperation;

    if (pendingLoad != null) {
      await pendingLoad;
    } else if (!_hasLoaded) {
      await loadPhotos();
    }

    if (!_hasLoaded || _loadError != null) {
      throw StateError('Unable to load the photo collection.');
    }
  }

  Future<File> savePhoto(XFile photo) async {
    await _ensureLoaded();

    final savedPhoto = await _storage.savePhoto(photo);

    _photos = [savedPhoto, ..._photos];
    notifyListeners();

    return savedPhoto;
  }

  Future<void> deletePhoto(File photo) async {
    await _ensureLoaded();

    await _storage.deletePhoto(photo);

    _photos = _photos
        .where((savedPhoto) => savedPhoto.path != photo.path)
        .toList();

    notifyListeners();
  }
}
