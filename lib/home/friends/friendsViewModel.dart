import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/friends/friendModel.dart';
import 'package:workout_tracker/home/friends/friendsService.dart';

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel(this.service);
  final FriendService service;

  bool loading = false;
  List<FriendUser> friends = [];
  List<PendingRequest> incoming = [];
  List<FriendUser> searchResults = [];

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    friends = await service.listFriends();
    incoming = await service.incomingPending();
    loading = false;
    notifyListeners();
  }

  Future<void> send(String addresseeId) async {
    await service.sendRequest(addresseeId);
    await refresh();
  }

  Future<void> accept(String friendshipId) async {
    await service.accept(friendshipId);
    await refresh();
  }

  Future<void> decline(String friendshipId) async {
    await service.decline(friendshipId);
    await refresh();
  }

  Future<void> remove(String friendshipId) async {
    await service.remove(friendshipId);
    await refresh();
  }

  Future<void> search(String q) async {
    searchResults = q.trim().isEmpty ? [] : await service.searchUsers(q.trim());
    notifyListeners();
  }
}
