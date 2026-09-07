import 'dart:io';
import 'package:flutter/material.dart';

/// Resolves an [ExerciseModel.workoutImage] value to an [ImageProvider]:
/// bundled asset (`assets/...`), a custom photo on disk (absolute path), or
/// null when there's no image.
ImageProvider? exerciseImageProvider(String path) {
  if (path.isEmpty) return null;
  if (path.startsWith('assets/')) return AssetImage(path);
  return FileImage(File(path));
}

/// Renders an exercise image (asset or custom file) with a graceful fallback,
/// so callers don't each re-implement the asset-vs-file decision.
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final provider = exerciseImageProvider(path);
    final fb = fallback ??
        Icon(
          Icons.fitness_center_rounded,
          size: (width ?? height ?? 24) * 0.55,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    if (provider == null) {
      return SizedBox(width: width, height: height, child: Center(child: fb));
    }
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          SizedBox(width: width, height: height, child: Center(child: fb)),
    );
  }
}
