class AccountModel {
  final String id;
  final String userId;
  final String displayName;
  final String username;
  final String email;
  final String? avatarUrl;

  AccountModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.username,
    required this.email,
    required this.avatarUrl,
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
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
