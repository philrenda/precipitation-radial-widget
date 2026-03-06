import 'package:flutter_test/flutter_test.dart';
import 'package:precipitation_radial_widget/logic/hour_formatter.dart';

void main() {
  group('HourFormatter', () {
    test('midnight is 12a', () {
      expect(HourFormatter.format(0), '12a');
    });

    test('1 AM is 1a', () {
      expect(HourFormatter.format(1), '1a');
    });

    test('11 AM is 11a', () {
      expect(HourFormatter.format(11), '11a');
    });

    test('noon is 12p', () {
      expect(HourFormatter.format(12), '12p');
    });

    test('1 PM is 1p', () {
      expect(HourFormatter.format(13), '1p');
    });

    test('11 PM is 11p', () {
      expect(HourFormatter.format(23), '11p');
    });
  });
}
