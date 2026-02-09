import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';

class HistorySessionDetailVM extends ChangeNotifier {
  HistorySessionDetailVM({
    required this.historyKey,
    required PrEventsRepository prRepo,
  }) : _prRepo = prRepo;

  final dynamic historyKey;
  final PrEventsRepository _prRepo;

  Set<String> _prKeys = <String>{};
  bool _loading = true;

  Set<String> get prKeys => _prKeys;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _prKeys = await _prRepo.loadBestWeightPrKeys(historyKey);

    _loading = false;
    notifyListeners();
  }

  bool isPr(int exerciseId, DateTime ts) => _prRepo.isPr(_prKeys, exerciseId, ts);
}
