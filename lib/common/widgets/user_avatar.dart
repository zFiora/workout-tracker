import 'dart:convert';

import 'package:flutter/material.dart';

/// Decodes and memoizes base64 avatar blobs.
///
/// Avatars now arrive inlined as base64 on every user JSON (friends list,
/// leaderboard, exercise ranking) rather than as a CDN URL, so the same blob
/// can appear in many list rows that rebuild often. Decoding is not free, so
/// we decode each distinct blob once and reuse the [MemoryImage].
class AvatarCache {
  AvatarCache._();

  static final Map<String, MemoryImage> _cache = {};

  /// Returns a cached [MemoryImage] for [base64], or `null` if it's empty or
  /// not valid base64. Keyed by the raw string, so identical blobs across
  /// users/screens share one decode.
  static MemoryImage? image(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final cached = _cache[base64];
    if (cached != null) return cached;
    try {
      final img = MemoryImage(base64Decode(base64));
      _cache[base64] = img;
      return img;
    } catch (_) {
      return null; // malformed payload → fall back to initials/icon
    }
  }
}

/// Circular user avatar backed by a base64 blob, falling back to the first
/// letter of [name] when there's no image. Use everywhere a user avatar is
/// shown so decoding/caching stays consistent.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.base64,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? base64;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = AvatarCache.image(base64);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? cs.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: foregroundColor ?? cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
