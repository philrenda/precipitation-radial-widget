import 'dart:convert';

import 'minutely_data.dart';
import 'hourly_data.dart';

class WeatherData {
  final List<MinutelyDataPoint> minutely;
  final List<HourlyDataPoint> hourly;
  final double currentTemp;
  final double todayHigh;
  final double todayLow;
  final double windSpeed;
  final String currentIcon;
  final DateTime lastUpdated;

  const WeatherData({
    required this.minutely,
    required this.hourly,
    required this.currentTemp,
    required this.todayHigh,
    required this.todayLow,
    required this.windSpeed,
    required this.currentIcon,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'minutely': minutely.map((m) => m.toJson()).toList(),
        'hourly': hourly.map((h) => h.toJson()).toList(),
        'currentTemp': currentTemp,
        'todayHigh': todayHigh,
        'todayLow': todayLow,
        'windSpeed': windSpeed,
        'currentIcon': currentIcon,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      minutely: (json['minutely'] as List)
          .map((m) => MinutelyDataPoint.fromJson(m as Map<String, dynamic>))
          .toList(),
      hourly: (json['hourly'] as List)
          .map((h) => HourlyDataPoint.fromJson(h as Map<String, dynamic>))
          .toList(),
      currentTemp: (json['currentTemp'] as num).toDouble(),
      todayHigh: (json['todayHigh'] as num).toDouble(),
      todayLow: (json['todayLow'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      currentIcon: json['currentIcon'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  String serialize() => jsonEncode(toJson());

  static WeatherData? deserialize(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return WeatherData.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
