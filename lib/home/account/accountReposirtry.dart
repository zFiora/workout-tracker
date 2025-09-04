// lib/home/account/data/account_repository.dart
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/home/account/model/accountModel.dart';

class AccountRepository {
  final PocketBase pb;
  AccountRepository(this.pb);

  /// Loads the logged-in user's info.
  /// Prefers data from `profiles` (if it exists) but **always** reads core fields
  /// (email, username, avatar) from the expanded `user`.
  Future<AccountModel> fetchMe() async {
    // Refresh token if present but invalid
    if (!pb.authStore.isValid && pb.authStore.token.isNotEmpty) {
      try {
        await pb.collection('users').authRefresh();
      } catch (_) {}
    }

    final user = pb.authStore.record;
    if (user == null) throw Exception('Not authenticated');

    RecordModel? profile;
    try {
      profile = await pb
          .collection('profiles')
          .getFirstListItem('user="${user.id}"', expand: 'user');
    } on ClientException catch (e) {
      // 404 not found → proceed without a profile
      if (e.statusCode != 404) rethrow;
    }

    // If profile exists, get expanded user from it; otherwise fetch user directly
    RecordModel userRec;
    if (profile != null) {
      final expanded = profile.expand['user'];
      if (expanded != null && expanded.isNotEmpty) {
        userRec = expanded.first;
      } else {
        // rare: expansion failed; fetch directly
        userRec = await pb.collection('users').getOne(user.id);
      }
    } else {
      userRec = await pb.collection('users').getOne(user.id);
    }

    
    final email = userRec.getStringValue('email');

    // name/displayName
    final profileDisplay = profile?.getStringValue('displayName') ?? '';
    final userNameField = userRec.getStringValue('name'); // PocketBase "name"
    final displayName = profileDisplay.isNotEmpty
        ? profileDisplay
        : (userNameField.isNotEmpty
              ? userNameField
              : userRec.getStringValue('username'));

    // username
    final profileUsername = profile?.getStringValue('username') ?? '';
    final userUsername = userRec.getStringValue('username');
    final username = profileUsername.isNotEmpty
        ? profileUsername
        : userUsername;

    
    final userAvatar = userRec.getStringValue('avatar'); 
    final String? avatarUrl = userAvatar.isNotEmpty
        ? pb.files
              .getUrl(userRec, userAvatar, query: {'thumb': '112x112'})
              .toString()
        : null;

    return AccountModel(
      id: profile?.id ?? user.id, // if no profile, store user id here
      userId: user.id,
      displayName: displayName,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

 
  Future<AccountModel> updateMe({
    String? displayName,
    String? username,
    List<http.MultipartFile> files = const [], // for users.avatar
  }) async {
    final user = pb.authStore.record;
    if (user == null) throw Exception('Not authenticated');

    
    final userBody = <String, dynamic>{};
    if (displayName != null) userBody['name'] = displayName; 
    if (username != null) userBody['username'] = username;

    RecordModel updatedUser = await pb
        .collection('users')
        .update(
          user.id,
          body: userBody,
          files: files, 
        );

    
    try {
      final profile = await pb
          .collection('profiles')
          .getFirstListItem('user="${user.id}"');
      final profileBody = <String, dynamic>{};
      if (displayName != null) profileBody['displayName'] = displayName;
      if (username != null) profileBody['username'] = username;
      if (profileBody.isNotEmpty) {
        await pb.collection('profiles').update(profile.id, body: profileBody);
      }
    } catch (e) {
      
    }

    
    final email = updatedUser.getStringValue('email');
    final display = displayName ?? updatedUser.getStringValue('name');
    final userUsername = username ?? updatedUser.getStringValue('username');

    final avatar = updatedUser.getStringValue('avatar');
    final String? avatarUrl = avatar.isNotEmpty
        ? pb.files
              .getUrl(updatedUser, avatar, query: {'thumb': '112x112'})
              .toString()
        : null;

    return AccountModel(
      id: user.id,
      userId: user.id,
      displayName: display.isNotEmpty ? display : userUsername,
      username: userUsername,
      email: email,
      avatarUrl: avatarUrl,
    );
  }
}
