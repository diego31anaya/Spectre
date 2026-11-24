import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStorage {
  static Future<Directory> _collectionDirectory() async {
    // Get the path where we store data in this app.
    final documents = await getApplicationDocumentsDirectory();

    // Get the directory for the collections data by joining the paths.
    final directory = Directory(p.join(documents.path, 'collection'));

    // If the directory does not exist, this creates it.
    // recursive being true means all directories to this path are created.
    await directory.create(recursive: true);
    return directory;
  }

  static Future<File> savePhoto(XFile photo) async {
    final directory = await _collectionDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final extension = p.extension(photo.path);
    final filename =
        'photo_$timestamp${extension.isEmpty ? '.jpg' : extension}';
    final destination = p.join(directory.path, filename);

    return File(photo.path).copy(destination);
  }

  static Future<List<File>> loadPhotos() async {
    final directory = await _collectionDirectory();
    final entries = await directory.list(followLinks: false).toList();

    final photos = entries.whereType<File>().where((file) {
      return p.basename(file.path).startsWith('photo_');
    }).toList();

    // Timestamp filenames put the newest photos first.
    photos.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));

    return photos;
  }

  static Future<void> deletePhoto(File photo) async {
    await photo.delete();
  }
}
