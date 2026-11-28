import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spectre/services/photo_repository.dart';
import 'package:spectre/services/photo_storage.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PhotoRepository(storage: PhotoStorage())..loadPhotos(),
      child: const MyApp(),
    ),
  );
}
