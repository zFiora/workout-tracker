enum PRType { weight, reps, volume }

class PersonalRecords {
  final double bestWeight;
  final int bestReps;
  final double bestSetVolume;

  const PersonalRecords({
    required this.bestWeight,
    required this.bestReps,
    required this.bestSetVolume,
  });

  const PersonalRecords.empty()
    : bestWeight = 0,
      bestReps = 0,
      bestSetVolume = 0;
}

class PRResult {
  final Set<PRType> types;
  final PersonalRecords previous;

  const PRResult({required this.types, required this.previous});
  bool get hasAny => types.isNotEmpty;
}
