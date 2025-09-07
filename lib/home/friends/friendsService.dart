import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class FriendService {
  final PocketBase pb;
  FriendService(this.pb);

  String _pairKey(String a, String b) {
    final s = [a, b]..sort();
    return '${s[0]}_${s[1]}';
  }

  Future<RecordModel> sendRequest(String toUserId) async {
    final me = pb.authStore.record?.id;
    return pb
        .collection('friend_requests')
        .create(
          body: {
            'fromUser': me,
            'toUser': toUserId,
            'status': 'pending', // keep if no server hook
            'pairKey': _pairKey(me!, toUserId), // keep if no server hook
          },
        );
  }

  Future<void> cancel(String requestId) =>
      pb.collection('friend_requests').delete(requestId);

  Future<RecordModel> accept(String requestId) => pb
      .collection('friend_requests')
      .update(requestId, body: {'status': 'accepted'});

  Future<RecordModel> decline(String requestId) => pb
      .collection('friend_requests')
      .update(requestId, body: {'status': 'declined'});

  Future<List<RecordModel>> listFriends() async {
    final me = pb.authStore.record?.id;
    final res = await pb
        .collection('friend_requests')
        .getList(
          page: 1,
          perPage: 200,
          filter: '(fromUser = "$me" || toUser = "$me") && status = "accepted"',
          expand: 'fromUser,toUser',
        );
    final others = <RecordModel>[];
    for (final r in res.items) {
      final from = r.get<RecordModel?>('expand.fromUser');
      final to = r.get<RecordModel?>('expand.toUser');

      final other = (from != null && from.id != me) ? from : to;
      if (other != null) others.add(other);
    }
    return others;
  }

  Future<List<RecordModel>> incomingPending() async {
    final me = pb.authStore.record?.id;
    final res = await pb
        .collection('friend_requests')
        .getList(
          page: 1,
          perPage: 100,
          filter: 'toUser = "$me" && status = "pending"',
          expand: 'fromUser',
        );
    return res.items;
  }

  Future<List<RecordModel>> outgoingPending() async {
    final me = pb.authStore.record?.id;
    final res = await pb
        .collection('friend_requests')
        .getList(
          page: 1,
          perPage: 100,
          filter: 'fromUser = "$me" && status = "pending"',
          expand: 'toUser',
        );
    return res.items;
  }

  // Search helper (username/email → userId)
  // friendsService.dart
  Future<List<RecordModel>> searchUsers(String q) async {
    final query = q.trim();
    if (query.isEmpty) return [];

    // 1) Are we logged in?
    final me = pb.authStore.record?.id;
    if (me == null || !pb.authStore.isValid) {
      debugPrint('[FriendService.searchUsers] not authenticated');
      return [];
    }

    // 2) Build a safe filter (LIKE for username, exact or LIKE for email)
    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

    final isEmail = query.contains('@');
    final filter = isEmail
        // try exact first; fallback to LIKE if you prefer partial email search
        ? 'email = "${esc(query)}"'
        : 'username ~ "%${esc(query)}%"';

    try {
      final res = await pb
          .collection('users')
          .getList(
            page: 1,
            perPage: 20,
            filter: filter,
            // no expand needed here
          );
      debugPrint(
        '[FriendService.searchUsers] q="$query" -> ${res.items.length} items',
      );
      return res.items;
    } on ClientException catch (e) {
      debugPrint(
        '[FriendService.searchUsers] ClientException '
        'status=${e.statusCode}, msg=${e.response?['message']} filter=$filter',
      );
      // 400 here usually means filter invalid or rules deny.
      rethrow; // let UI show a SnackBar
    } catch (e) {
      debugPrint('[FriendService.searchUsers] Unknown error: $e');
      rethrow;
    }
  }
}
