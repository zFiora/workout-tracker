import 'package:workout_tracker/home/history/models/PRModels.dart';

import '../../session/models/sessionModels.dart';

class PRDetector {
  PRResult detectForNewSet({
    required PersonalRecords previous,
    required PerformedSet newSet,
  }) {
    final types = <PRType>{};

    if (newSet.weight > previous.bestWeight) types.add(PRType.weight);
    if (newSet.reps > previous.bestReps) types.add(PRType.reps);

    final newVol = newSet.weight * newSet.reps;
    if (newVol > previous.bestSetVolume) types.add(PRType.volume);

    return PRResult(types: types, previous: previous);
  }
}
