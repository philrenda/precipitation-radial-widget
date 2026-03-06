import 'package:flutter_test/flutter_test.dart';
import 'package:precipitation_radial_widget/logic/weather_summary.dart';
import 'package:precipitation_radial_widget/models/minutely_data.dart';
import 'package:precipitation_radial_widget/models/hourly_data.dart';

MinutelyDataPoint _dry() => const MinutelyDataPoint(
      time: 0,
      precipIntensity: 0.0,
      precipProbability: 0.0,
    );

MinutelyDataPoint _rain({double intensity = 0.1, double prob = 0.5}) =>
    MinutelyDataPoint(
      time: 0,
      precipIntensity: intensity,
      precipProbability: prob,
    );

HourlyDataPoint _hourly({String icon = 'rain', String summary = 'Rain'}) =>
    HourlyDataPoint(
      time: 0,
      icon: icon,
      summary: summary,
      temperature: 65,
      precipIntensity: 0.1,
      precipProbability: 0.5,
    );

void main() {
  group('WeatherSummary', () {
    test('returns hourly summary when no minutely data', () {
      final result = WeatherSummary.getSummary(
        [],
        [_hourly(summary: 'Partly Cloudy')],
      );
      expect(result, 'Partly Cloudy');
    });

    test('detects currently precipitating', () {
      final minutely = [
        _rain(),
        _rain(),
        _rain(),
        _rain(),
        _rain(),
        _dry(),
        _dry(),
        _dry(),
        _dry(),
        _dry(),
      ];
      final result = WeatherSummary.getSummary(minutely, [_hourly()]);
      expect(result, contains('ending in'));
    });

    test('detects rain starting soon', () {
      final minutely = [
        _dry(),
        _dry(),
        _dry(),
        _dry(),
        _dry(),
        _rain(),
        _rain(),
        _rain(),
        _dry(),
        _dry(),
        _dry(),
        _dry(),
        _dry(),
      ];
      final result = WeatherSummary.getSummary(minutely, [_hourly()]);
      expect(result, contains('starting in'));
    });

    test('detects ongoing rain when data is all rain', () {
      final minutely = List.generate(60, (_) => _rain());
      final result = WeatherSummary.getSummary(minutely, [_hourly()]);
      expect(result, contains('ongoing'));
    });

    test('classifies snow type', () {
      final minutely = List.generate(60, (_) => _rain());
      final result = WeatherSummary.getSummary(
        minutely,
        [_hourly(icon: 'snow')],
      );
      expect(result, contains('Snow'));
    });

    test('classifies intensity as Light', () {
      final minutely = List.generate(60, (_) => _rain(intensity: 0.01));
      final result = WeatherSummary.getSummary(minutely, [_hourly()]);
      expect(result, contains('Light'));
    });

    test('classifies intensity as Heavy', () {
      final minutely = List.generate(60, (_) => _rain(intensity: 0.6));
      final result = WeatherSummary.getSummary(minutely, [_hourly()]);
      expect(result, contains('Heavy'));
    });

    test('returns No data for empty inputs', () {
      expect(WeatherSummary.getSummary([], []), 'No data');
    });
  });
}
