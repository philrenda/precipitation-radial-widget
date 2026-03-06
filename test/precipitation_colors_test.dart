import 'package:flutter_test/flutter_test.dart';
import 'package:precipitation_radial_widget/logic/precipitation_colors.dart';

void main() {
  group('PrecipitationColors', () {
    test('returns noPercip for low probability', () {
      final color = PrecipitationColors.getColor(0.5, 0.05);
      expect(color, PrecipitationColors.noPercip);
    });

    test('returns noPercip for low intensity', () {
      final color = PrecipitationColors.getColor(0.001, 0.5);
      expect(color, PrecipitationColors.noPercip);
    });

    test('returns trace for 0.005-0.01 intensity', () {
      final color = PrecipitationColors.getColor(0.006, 0.5);
      expect(color, PrecipitationColors.trace);
    });

    test('returns veryLight for 0.01-0.05 intensity', () {
      final color = PrecipitationColors.getColor(0.02, 0.5);
      expect(color, PrecipitationColors.veryLight);
    });

    test('returns light for 0.05-0.15 intensity', () {
      final color = PrecipitationColors.getColor(0.10, 0.5);
      expect(color, PrecipitationColors.light);
    });

    test('returns moderate for 0.15-0.30 intensity', () {
      final color = PrecipitationColors.getColor(0.20, 0.5);
      expect(color, PrecipitationColors.moderate);
    });

    test('returns heavy for 0.30-0.60 intensity', () {
      final color = PrecipitationColors.getColor(0.40, 0.5);
      expect(color, PrecipitationColors.heavy);
    });

    test('returns veryHeavy for 0.60-1.0 intensity', () {
      final color = PrecipitationColors.getColor(0.80, 0.5);
      expect(color, PrecipitationColors.veryHeavy);
    });

    test('returns extreme for >= 1.0 intensity', () {
      final color = PrecipitationColors.getColor(1.5, 0.5);
      expect(color, PrecipitationColors.extreme);
    });

    test('isPrecip returns false below thresholds', () {
      expect(PrecipitationColors.isPrecip(0.001, 0.5), false);
      expect(PrecipitationColors.isPrecip(0.5, 0.05), false);
      expect(PrecipitationColors.isPrecip(0.001, 0.05), false);
    });

    test('isPrecip returns true above thresholds', () {
      expect(PrecipitationColors.isPrecip(0.005, 0.10), true);
      expect(PrecipitationColors.isPrecip(1.0, 0.5), true);
    });
  });
}
