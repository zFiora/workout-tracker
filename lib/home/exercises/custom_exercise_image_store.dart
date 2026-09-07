import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies user-picked exercise photos into a permanent app directory so they
/// survive restarts (image_picker hands back a temporary cache path that the OS
/// may purge). Built-in asset paths are left untouched.
class ExerciseImageStore {
  ExerciseImageStore._();

  static const _folder = 'exercise_images';

  /// Copies [sourcePath] into the app documents dir and returns the new
  /// permanent absolute path.
  static Future<String> persist(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = '${dir.path}/${const Uuid().v4()}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Deletes a previously-persisted photo. No-ops for empty paths and bundled
  /// assets, so it's always safe to call.
  static Future<void> deleteIfLocal(String path) async {
    if (path.isEmpty || path.startsWith('assets/')) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // best-effort cleanup
    }
  }
}
