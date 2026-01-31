class PrHit {
  final int exerciseId;
  final DateTime performedAt;
  final double weight;
  final int reps;

  /// e.g. "bestWeight"
  final String kind;

  const PrHit({
    required this.exerciseId,
    required this.performedAt,
    required this.weight,
    required this.reps,
    required this.kind,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'performedAt': performedAt.toIso8601String(),
        'weight': weight,
        'reps': reps,
        'kind': kind,
      };
}
