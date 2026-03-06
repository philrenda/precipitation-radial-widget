import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/minutely_data.dart';
import '../models/hourly_data.dart';
import '../models/weather_data.dart';

class PirateWeatherService {
  static const String _baseUrl = 'https://api.pirateweather.net/forecast';
  static const Duration _timeout = Duration(seconds: 30);

  /// Validates an API key by making a minimal test call.
  Future<bool> validateApiKey(
      String apiKey, double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$apiKey/$lat,$lon?exclude=minutely,hourly,daily,alerts,flags&units=us',
      );
      final response = await http.get(url).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches minutely precipitation data.
  Future<List<MinutelyDataPoint>> fetchMinutely(
    String apiKey,
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/$apiKey/$lat,$lon?exclude=hourly,daily,current,alerts,flags&units=us',
    );
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('PirateWeather API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final minutely = json['minutely'] as Map<String, dynamic>?;
    if (minutely == null) return [];
    final data = minutely['data'] as List? ?? [];
    return data
        .map((m) => MinutelyDataPoint.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetches hourly forecast + current conditions.
  Future<({List<HourlyDataPoint> hourly, double currentTemp, double windSpeed, String currentIcon, double todayHigh, double todayLow})>
      fetchHourly(
    String apiKey,
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/$apiKey/$lat,$lon?exclude=minutely,daily,alerts,flags&units=us',
    );
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('PirateWeather API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Parse current conditions
    final currently = json['currently'] as Map<String, dynamic>? ?? {};
    final currentTemp = (currently['temperature'] as num?)?.toDouble() ?? 0.0;
    final windSpeed = (currently['windSpeed'] as num?)?.toDouble() ?? 0.0;
    final currentIcon = currently['icon'] as String? ?? 'cloudy';

    // Parse hourly data
    final hourlySection = json['hourly'] as Map<String, dynamic>?;
    final hourlyData = hourlySection?['data'] as List? ?? [];
    final hourly = hourlyData
        .take(24)
        .map((h) => HourlyDataPoint.fromJson(h as Map<String, dynamic>))
        .toList();

    // Calculate today's high/low from hourly
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    double high = double.negativeInfinity;
    double low = double.infinity;
    for (final h in hourly) {
      final dt = DateTime.fromMillisecondsSinceEpoch(h.time * 1000);
      if (dt.isAfter(todayStart) && dt.isBefore(todayEnd)) {
        if (h.temperature > high) high = h.temperature;
        if (h.temperature < low) low = h.temperature;
      }
    }
    if (high == double.negativeInfinity) high = currentTemp;
    if (low == double.infinity) low = currentTemp;

    return (
      hourly: hourly,
      currentTemp: currentTemp,
      windSpeed: windSpeed,
      currentIcon: currentIcon,
      todayHigh: high,
      todayLow: low,
    );
  }

  /// Fetches all weather data in two API calls.
  Future<WeatherData> fetchAll(
    String apiKey,
    double lat,
    double lon,
  ) async {
    final results = await Future.wait([
      fetchMinutely(apiKey, lat, lon),
      fetchHourly(apiKey, lat, lon),
    ]);

    final minutely = results[0] as List<MinutelyDataPoint>;
    final hourlyResult = results[1]
        as ({
          List<HourlyDataPoint> hourly,
          double currentTemp,
          double windSpeed,
          String currentIcon,
          double todayHigh,
          double todayLow,
        });

    return WeatherData(
      minutely: minutely,
      hourly: hourlyResult.hourly,
      currentTemp: hourlyResult.currentTemp,
      todayHigh: hourlyResult.todayHigh,
      todayLow: hourlyResult.todayLow,
      windSpeed: hourlyResult.windSpeed,
      currentIcon: hourlyResult.currentIcon,
      lastUpdated: DateTime.now(),
    );
  }
}
