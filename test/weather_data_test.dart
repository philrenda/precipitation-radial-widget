import 'package:flutter_test/flutter_test.dart';
import 'package:precipitation_radial_widget/models/weather_data.dart';
import 'package:precipitation_radial_widget/models/minutely_data.dart';
import 'package:precipitation_radial_widget/models/hourly_data.dart';

void main() {
  group('WeatherData serialization', () {
    test('roundtrip serialize/deserialize', () {
      final data = WeatherData(
        minutely: [
          const MinutelyDataPoint(
            time: 1000,
            precipIntensity: 0.05,
            precipProbability: 0.8,
          ),
        ],
        hourly: [
          const HourlyDataPoint(
            time: 2000,
            icon: 'rain',
            summary: 'Light Rain',
            temperature: 65.5,
            precipIntensity: 0.1,
            precipProbability: 0.7,
          ),
        ],
        currentTemp: 68.2,
        todayHigh: 75.0,
        todayLow: 55.0,
        windSpeed: 12.3,
        currentIcon: 'cloudy',
        lastUpdated: DateTime(2024, 1, 15, 10, 30),
      );

      final serialized = data.serialize();
      final deserialized = WeatherData.deserialize(serialized);

      expect(deserialized, isNotNull);
      expect(deserialized!.minutely.length, 1);
      expect(deserialized.minutely[0].precipIntensity, 0.05);
      expect(deserialized.hourly.length, 1);
      expect(deserialized.hourly[0].icon, 'rain');
      expect(deserialized.currentTemp, 68.2);
      expect(deserialized.todayHigh, 75.0);
      expect(deserialized.todayLow, 55.0);
      expect(deserialized.windSpeed, 12.3);
      expect(deserialized.currentIcon, 'cloudy');
    });

    test('deserialize returns null for invalid data', () {
      expect(WeatherData.deserialize(null), isNull);
      expect(WeatherData.deserialize(''), isNull);
      expect(WeatherData.deserialize('not json'), isNull);
    });
  });

  group('MinutelyDataPoint', () {
    test('fromJson parses correctly', () {
      final json = {
        'time': 1234567890,
        'precipIntensity': 0.1234,
        'precipProbability': 0.567,
        'precipIntensityError': 0.01,
        'precipType': 'rain',
      };
      final point = MinutelyDataPoint.fromJson(json);
      expect(point.time, 1234567890);
      expect(point.precipIntensity, 0.1234);
      expect(point.precipProbability, 0.567);
      expect(point.precipType, 'rain');
    });

    test('fromJson handles missing fields', () {
      final json = {'time': 0};
      final point = MinutelyDataPoint.fromJson(json);
      expect(point.precipIntensity, 0.0);
      expect(point.precipProbability, 0.0);
      expect(point.precipType, 'none');
    });
  });
}
