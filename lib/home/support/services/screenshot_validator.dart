/// Mirrors the exact rules `BugReportsController.Create` enforces server-side
/// (`AllowedScreenshotTypes` / `MaxScreenshotBytes`) so a bad pick fails fast
/// on-device instead of round-tripping to the server first.
abstract final class ScreenshotValidator {
  static const maxBytes = 5 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Returns a user-facing error message, or null if the file passes.
  static String? validate({required String path, required int sizeBytes}) {
    if (!allowedExtensions.contains(_extensionOf(path))) {
      return 'Only JPEG, PNG and WebP screenshots are allowed.';
    }
    if (sizeBytes > maxBytes) {
      return 'Screenshot must be under 5MB.';
    }
    return null;
  }

  /// MIME type for the multipart part's Content-Type header. Dio's
  /// `MultipartFile.fromFile` defaults to `application/octet-stream` when no
  /// content type is given, which the backend would reject outright — this
  /// must always be sent explicitly for a screenshot part.
  static String contentTypeFor(String path) => switch (_extensionOf(path)) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
