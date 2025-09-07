// lib/viewmodels/friends_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/home/friends/friendsService.dart';

class FriendsViewModel extends ChangeNotifier {
  final FriendService service;
  FriendsViewModel(this.service);

  bool loading = false;
  List<RecordModel> friends = [];
  List<RecordModel> incoming = [];
  List<RecordModel> outgoing = [];
  List<RecordModel> searchResults = [];

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    friends = await service.listFriends();
    incoming = await service.incomingPending();
    outgoing = await service.outgoingPending();
    loading = false;
    notifyListeners();
  }

  Future<void> send(String toUserId) async {
    await service.sendRequest(toUserId);
    await refresh();
  }

  Future<void> accept(String id) async {
    await service.accept(id);
    await refresh();
  }

  Future<void> decline(String id) async {
    await service.decline(id);
    await refresh();
  }

  Future<void> cancel(String id) async {
    await service.cancel(id);
    await refresh();
  }

  Future<void> search(String q) async {
    searchResults = q.trim().isEmpty ? [] : await service.searchUsers(q.trim());
    notifyListeners();
  }
}
