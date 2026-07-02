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

  final Set<String> sentRequestIds = {};

  Future<String?> send(String addresseeId) async {
    final error = await service.sendRequest(addresseeId);
    if (error == null) {
      sentRequestIds.add(addresseeId);
      notifyListeners();
    }
    return error;
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

  Future<FriendUser?> fetchProfile(String userId) => service.fetchProfile(userId);

  /// Resets cached state. Call on sign-out so the next sign-in (possibly
  /// as a different user) doesn't briefly show the previous user's data.
  void clear() {
    loading = false;
    friends = [];
    incoming = [];
    searchResults = [];
    sentRequestIds.clear();
    notifyListeners();
  }
}
