import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/geocoding_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  final GeocodingService _geocoding = GeocodingService();
  late AppSettings _settings;

  SettingsProvider(this._storage) {
    _settings = AppSettings(
      apiKey: _storage.apiKey,
      useDeviceLocation: _storage.useDeviceLocation,
      latitude: _storage.latitude,
      longitude: _storage.longitude,
      locationName: _storage.locationName,
      minutelyIntervalSeconds: _storage.minutelyIntervalSeconds,
      hourlyIntervalSeconds: _storage.hourlyIntervalSeconds,
      backgroundColor: Color(_storage.backgroundColorValue),
      transparentBackground: _storage.transparentBackground,
      themeMode: _themeModeFromString(_storage.themeModeString),
      setupComplete: _storage.setupComplete,
    );
  }

  AppSettings get settings => _settings;
  bool get isSetupComplete => _settings.setupComplete;
  ThemeMode get themeMode => _settings.themeMode;

  bool get isDarkMode {
    if (_settings.themeMode == ThemeMode.dark) return true;
    if (_settings.themeMode == ThemeMode.light) return false;
    return _storage.isDarkMode;
  }

  Future<void> setApiKey(String value) async {
    _settings = _settings.copyWith(apiKey: value);
    await _storage.setApiKey(value);
    notifyListeners();
  }

  Future<void> setUseDeviceLocation(bool value) async {
    _settings = _settings.copyWith(useDeviceLocation: value);
    await _storage.setUseDeviceLocation(value);
    notifyListeners();
  }

  Future<void> setLocation(double lat, double lon) async {
    _settings = _settings.copyWith(latitude: lat, longitude: lon);
    await _storage.setLatitude(lat);
    await _storage.setLongitude(lon);
    notifyListeners();

    // Reverse geocode in background
    final name = await _geocoding.reverseGeocode(lat, lon);
    _settings = _settings.copyWith(locationName: name);
    await _storage.setLocationName(name);
    notifyListeners();
  }

  Future<void> setLocationName(String value) async {
    _settings = _settings.copyWith(locationName: value);
    await _storage.setLocationName(value);
    notifyListeners();
  }

  Future<void> setMinutelyInterval(int seconds) async {
    _settings = _settings.copyWith(minutelyIntervalSeconds: seconds);
    await _storage.setMinutelyIntervalSeconds(seconds);
    notifyListeners();
  }

  Future<void> setHourlyInterval(int seconds) async {
    _settings = _settings.copyWith(hourlyIntervalSeconds: seconds);
    await _storage.setHourlyIntervalSeconds(seconds);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color color) async {
    _settings = _settings.copyWith(
      backgroundColor: color,
      transparentBackground: false,
    );
    await _storage.setBackgroundColorValue(color.value);
    await _storage.setTransparentBackground(false);
    notifyListeners();
  }

  Future<void> setTransparentBackground(bool value) async {
    _settings = _settings.copyWith(transparentBackground: value);
    await _storage.setTransparentBackground(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _storage.setThemeModeString(_themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setSetupComplete(bool value) async {
    _settings = _settings.copyWith(setupComplete: value);
    await _storage.setSetupComplete(value);
    notifyListeners();
  }

  /// Requests current GPS position (one-shot, not continuous).
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
