class AccountModel {
  final String id;
  final String userId;
  final String displayName;
  final String username;
  final String email;

  /// Raw base64-encoded avatar image (no data-URI prefix), or null.
  final String? avatarBase64;

  /// Streak fields are server-owned (bumped by the backend on workout save);
  /// the client only reads them.
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastWorkoutDate;

  AccountModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.username,
    required this.email,
    required this.avatarBase64,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastWorkoutDate,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    return AccountModel(
      id: id,
      userId: id,
      displayName:
          (json['displayName'] as String?)?.isNotEmpty == true
              ? json['displayName'] as String
              : (json['username'] as String? ?? ''),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarBase64: json['avatarBase64'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastWorkoutDate:
          DateTime.tryParse(json['lastWorkoutDate'] as String? ?? ''),
    );
  }
}
