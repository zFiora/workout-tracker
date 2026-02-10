import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';

class HistorySessionDetailVM extends ChangeNotifier {
  HistorySessionDetailVM({
    required this.historyKey,
    required HistoryService historyService,
  }) : _service = historyService;

  final dynamic historyKey;
  final HistoryService _service;

  Set<String> _prKeys = <String>{};
  bool _loading = true;

  Set<String> get prKeys => _prKeys;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _prKeys = await _service.loadBestWeightPrKeys(historyKey);

    _loading = false;
    notifyListeners();
  }

  bool isPr(int exerciseId, DateTime ts) =>
      _service.isPr(_prKeys, exerciseId, ts);
}
