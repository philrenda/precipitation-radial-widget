import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences. All keys use the `flutter.` prefix
/// automatically (SharedPreferences does this), which lets the Kotlin
/// WorkManager read them directly.
class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // API Key
  String get apiKey => _prefs.getString('api_key') ?? '';
  Future<void> setApiKey(String value) => _prefs.setString('api_key', value);

  // Location
  bool get useDeviceLocation =>
      _prefs.getBool('use_device_location') ?? false;
  Future<void> setUseDeviceLocation(bool value) =>
      _prefs.setBool('use_device_location', value);

  double get latitude => _prefs.getDouble('latitude') ?? 0.0;
  Future<void> setLatitude(double value) =>
      _prefs.setDouble('latitude', value);

  double get longitude => _prefs.getDouble('longitude') ?? 0.0;
  Future<void> setLongitude(double value) =>
      _prefs.setDouble('longitude', value);

  String get locationName => _prefs.getString('location_name') ?? '';
  Future<void> setLocationName(String value) =>
      _prefs.setString('location_name', value);

  // Polling intervals
  int get minutelyIntervalSeconds =>
      _prefs.getInt('minutely_interval_seconds') ?? 600;
  Future<void> setMinutelyIntervalSeconds(int value) =>
      _prefs.setInt('minutely_interval_seconds', value);

  int get hourlyIntervalSeconds =>
      _prefs.getInt('hourly_interval_seconds') ?? 1800;
  Future<void> setHourlyIntervalSeconds(int value) =>
      _prefs.setInt('hourly_interval_seconds', value);

  // Appearance
  int get backgroundColorValue =>
      _prefs.getInt('background_color') ?? Colors.black.value;
  Future<void> setBackgroundColorValue(int value) =>
      _prefs.setInt('background_color', value);

  bool get transparentBackground =>
      _prefs.getBool('transparent_background') ?? false;
  Future<void> setTransparentBackground(bool value) =>
      _prefs.setBool('transparent_background', value);

  String get themeModeString =>
      _prefs.getString('theme_mode') ?? 'system';
  Future<void> setThemeModeString(String value) =>
      _prefs.setString('theme_mode', value);

  // Setup
  bool get setupComplete => _prefs.getBool('setup_complete') ?? false;
  Future<void> setSetupComplete(bool value) =>
      _prefs.setBool('setup_complete', value);

  // Cached weather data
  String? get cachedWeatherData => _prefs.getString('weather_data');
  Future<void> setCachedWeatherData(String value) =>
      _prefs.setString('weather_data', value);

  // Dark mode helper
  bool get isDarkMode {
    final mode = themeModeString;
    if (mode == 'dark') return true;
    if (mode == 'light') return false;
    // System mode — check platform brightness
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }
}
