import 'dart:async';

import 'package:flutter/material.dart';

import '../models/weather_data.dart';
import '../services/pirate_weather_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import 'settings_provider.dart';

class WeatherProvider extends ChangeNotifier {
  final PirateWeatherService _api;
  final StorageService _storage;
  final WidgetService _widgetService;

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;
  Timer? _minutelyTimer;
  Timer? _hourlyTimer;
  SettingsProvider? _settings;

  WeatherProvider(this._api, this._storage, this._widgetService) {
    // Load cached data
    _weatherData = WeatherData.deserialize(_storage.cachedWeatherData);
  }

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _weatherData != null;

  void updateSettings(SettingsProvider settings) {
    final oldSettings = _settings;
    _settings = settings;

    // Restart timers if intervals changed
    if (oldSettings == null ||
        oldSettings.settings.minutelyIntervalSeconds !=
            settings.settings.minutelyIntervalSeconds ||
        oldSettings.settings.hourlyIntervalSeconds !=
            settings.settings.hourlyIntervalSeconds) {
      _restartTimers();
    }
  }

  void _restartTimers() {
    _minutelyTimer?.cancel();
    _hourlyTimer?.cancel();

    if (_settings == null || _settings!.settings.apiKey.isEmpty) return;

    final minutelyInterval =
        Duration(seconds: _settings!.settings.minutelyIntervalSeconds);
    final hourlyInterval =
        Duration(seconds: _settings!.settings.hourlyIntervalSeconds);

    _minutelyTimer = Timer.periodic(minutelyInterval, (_) => refresh());
    _hourlyTimer = Timer.periodic(hourlyInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_settings == null || _settings!.settings.apiKey.isEmpty) return;
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      double lat = _settings!.settings.latitude;
      double lon = _settings!.settings.longitude;

      // If using device location, get a one-shot GPS fix
      if (_settings!.settings.useDeviceLocation) {
        final pos = await _settings!.getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lon = pos.longitude;
          await _settings!.setLocation(lat, lon);
        }
      }

      _weatherData = await _api.fetchAll(
        _settings!.settings.apiKey,
        lat,
        lon,
      );

      // Cache data
      await _storage.setCachedWeatherData(_weatherData!.serialize());

      // Update native widget
      await _widgetService.updateWidget(
        data: _weatherData!,
        locationName: _settings!.settings.locationName,
        isDarkMode: _settings!.isDarkMode,
        backgroundColor: _settings!.settings.backgroundColor,
        transparentBackground: _settings!.settings.transparentBackground,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _minutelyTimer?.cancel();
    _hourlyTimer?.cancel();
    super.dispose();
  }
}
