import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Keeps progress photos on-device only, in `<app documents>/progress_photos/`.
/// Same approach as `ExerciseImageStore` (image_picker returns a temporary
/// cache path the OS may purge, so the file is copied somewhere permanent),
/// except callers get back a *file name*, not an absolute path — iOS moves
/// the app's container between updates, so absolute paths go stale.
///
/// Nothing here talks to the network; photos are never uploaded.
class ProgressPhotoStore {
  ProgressPhotoStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  static final ProgressPhotoStore I = ProgressPhotoStore();

  static const folderName = 'progress_photos';

  final Future<Directory> Function() _baseDir;

  Future<Directory> _folder({bool create = false}) async {
    final dir = Directory('${(await _baseDir()).path}/$folderName');
    if (create && !await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] into the photo folder; returns the new file name.
  Future<String> persist(String sourcePath) async {
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : sourcePath.substring(dot + 1).toLowerCase();
    final name = '${const Uuid().v4()}.$ext';
    final dir = await _folder(create: true);
    await File(sourcePath).copy('${dir.path}/$name');
    return name;
  }

  /// The file for [fileName], or null if it no longer exists.
  Future<File?> resolve(String fileName) async {
    if (!_isSafeName(fileName)) return null;
    final file = File('${(await _folder()).path}/$fileName');
    return await file.exists() ? file : null;
  }

  /// Best-effort delete; safe to call for missing files.
  Future<void> delete(String fileName) async {
    if (!_isSafeName(fileName)) return;
    try {
      final file = File('${(await _folder()).path}/$fileName');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Removes every progress photo (account switch / account deletion).
  Future<void> deleteAll() async {
    try {
      final dir = await _folder();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Stored names are plain file names we generated; refuse anything that
  /// could escape the folder.
  static bool _isSafeName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains('\\') &&
      !name.contains('..');
}
