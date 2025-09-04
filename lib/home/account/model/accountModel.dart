// models/account.dart
class AccountModel {
  final String id;            // profile record id
  final String userId;        // _pb_users_auth_ id
  final String displayName;
  final String username;
  final String email;         // from expanded user
  final String? avatarUrl;    // full URL or null

  AccountModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });
}
