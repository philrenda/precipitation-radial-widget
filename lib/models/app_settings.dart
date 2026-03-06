import 'package:flutter/material.dart';

class AppSettings {
  final String apiKey;
  final bool useDeviceLocation;
  final double latitude;
  final double longitude;
  final String locationName;
  final int minutelyIntervalSeconds;
  final int hourlyIntervalSeconds;
  final Color backgroundColor;
  final bool transparentBackground;
  final ThemeMode themeMode;
  final bool setupComplete;

  const AppSettings({
    this.apiKey = '',
    this.useDeviceLocation = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.locationName = '',
    this.minutelyIntervalSeconds = 600,
    this.hourlyIntervalSeconds = 1800,
    this.backgroundColor = Colors.black,
    this.transparentBackground = false,
    this.themeMode = ThemeMode.system,
    this.setupComplete = false,
  });

  AppSettings copyWith({
    String? apiKey,
    bool? useDeviceLocation,
    double? latitude,
    double? longitude,
    String? locationName,
    int? minutelyIntervalSeconds,
    int? hourlyIntervalSeconds,
    Color? backgroundColor,
    bool? transparentBackground,
    ThemeMode? themeMode,
    bool? setupComplete,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      minutelyIntervalSeconds:
          minutelyIntervalSeconds ?? this.minutelyIntervalSeconds,
      hourlyIntervalSeconds:
          hourlyIntervalSeconds ?? this.hourlyIntervalSeconds,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      transparentBackground:
          transparentBackground ?? this.transparentBackground,
      themeMode: themeMode ?? this.themeMode,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }

  int get estimatedMonthlyApiCalls {
    final minutelyCalls = 86400 ~/ minutelyIntervalSeconds;
    final hourlyCalls = 86400 ~/ hourlyIntervalSeconds;
    return (minutelyCalls + hourlyCalls) * 30;
  }
}
