import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';

void main() {
  group('WeightUnit', () {
    test('kg is identity', () {
      expect(WeightUnit.kg.fromKg(100), 100);
      expect(WeightUnit.kg.toKg(100), 100);
      expect(WeightUnit.kg.format(102.5), '102.5');
      expect(WeightUnit.kg.formatWithUnit(100), '100 kg');
    });

    test('kg → lb display is correct', () {
      // 100 kg ≈ 220.46 lb
      expect(WeightUnit.lb.fromKg(100), closeTo(220.462, 0.01));
      expect(WeightUnit.lb.formatWithUnit(100), '220.5 lb');
    });

    test('lb input converts back to kg', () {
      // 225 lb ≈ 102.058 kg
      expect(WeightUnit.lb.toKg(225), closeTo(102.058, 0.01));
    });

    test('round-trip kg→lb→kg is lossless (no storage corruption)', () {
      for (final kg in [20.0, 60.0, 100.0, 102.5, 142.5, 227.3]) {
        final lb = WeightUnit.lb.fromKg(kg);
        final back = WeightUnit.lb.toKg(lb);
        expect(back, closeTo(kg, 1e-9),
            reason: 'kg=$kg must survive a lb round-trip');
      }
    });

    test('format trims a trailing .0', () {
      expect(WeightUnit.kg.format(100.0), '100');
      expect(WeightUnit.kg.format(100.5), '100.5');
    });
  });
}
