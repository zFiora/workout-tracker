class FriendUser {
  final String id;
  final String email;
  final String username;
  final String? displayName;

  /// Raw base64-encoded avatar image (no data-URI prefix), or null.
  final String? avatarBase64;
  final int currentStreak;
  final int bestStreak;

  const FriendUser({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarBase64,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  String get name =>
      (displayName?.isNotEmpty == true) ? displayName! : username;

  factory FriendUser.fromJson(Map<String, dynamic> json) => FriendUser(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['displayName'] as String?,
    avatarBase64: json['avatarBase64'] as String?,
    currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
  );
}

class PendingRequest {
  final String friendshipId;
  final FriendUser requester;
  final DateTime createdAt;

  const PendingRequest({
    required this.friendshipId,
    required this.requester,
    required this.createdAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) => PendingRequest(
    friendshipId: json['friendshipId'] as String? ?? '',
    requester: FriendUser.fromJson(
      json['requester'] as Map<String, dynamic>? ?? {},
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now(),
  );
}
