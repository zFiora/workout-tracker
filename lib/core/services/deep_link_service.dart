import 'dart:async';

import 'package:app_links/app_links.dart';

/// Handles incoming custom-scheme deep links. Currently only the password
/// reset link is understood:
///
///     workouttracker://reset-password?token=RESET_TOKEN
///
/// The token is never persisted or logged here — it's parsed out of the URI
/// and handed straight to the reset screen (see the security notes in the
/// backend contract).
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  static const scheme = 'workouttracker';
  static const resetHost = 'reset-password';

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// Pure parser (no plugin/platform dependency) so it can be unit-tested.
  /// Returns the reset token if [uri] is a valid reset link, else null.
  ///
  /// Accepts the token whether `reset-password` lands as the URI host
  /// (`scheme://reset-password?...`) or as a path segment
  /// (`scheme://host/reset-password?...`), since custom-scheme URI parsing
  /// differs subtly by platform.
  static String? resetTokenFrom(Uri uri) {
    if (uri.scheme.toLowerCase() != scheme) return null;
    final isReset =
        uri.host == resetHost || uri.pathSegments.contains(resetHost);
    if (!isReset) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  /// Reset token from the link the app was cold-started with, or null.
  /// Call once, before `runApp`, so a launch-from-link routes straight to
  /// the reset screen with no flash of the normal startup flow.
  Future<String?> getInitialResetToken() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return null;
      return resetTokenFrom(uri);
    } catch (_) {
      // Plugin unavailable (e.g. unsupported platform) — no deep link.
      return null;
    }
  }

  /// Subscribes to links delivered while the app is already running (warm
  /// start / foreground). [onResetToken] fires only for valid reset links.
  void listen(void Function(String token) onResetToken) {
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        final token = resetTokenFrom(uri);
        if (token != null) onResetToken(token);
      },
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
