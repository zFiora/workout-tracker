import 'package:hive/hive.dart';

part 'measurement_entry.g.dart';

@HiveType(typeId: 30) // pick a unique number not used in your app
class MeasurementEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date; // store UTC to avoid timezone bugs

  @HiveField(2)
  final double weightKg;

  MeasurementEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  MeasurementEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
  }) {
    return MeasurementEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}
