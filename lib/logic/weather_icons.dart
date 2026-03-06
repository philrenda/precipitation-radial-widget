import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/minutely_data.dart';
import '../models/hourly_data.dart';
import 'precipitation_colors.dart';

class WeatherIcons {
  static final Map<String, IconData> _iconMap = {
    'clear-day': MdiIcons.weatherSunny,
    'clear-night': MdiIcons.weatherNight,
    'rain': MdiIcons.weatherRainy,
    'snow': MdiIcons.weatherSnowy,
    'sleet': MdiIcons.weatherSnowyRainy,
    'wind': MdiIcons.weatherWindy,
    'fog': MdiIcons.weatherFog,
    'cloudy': MdiIcons.weatherCloudy,
    'partly-cloudy-day': MdiIcons.weatherPartlyCloudy,
    'partly-cloudy-night': MdiIcons.weatherNightPartlyCloudy,
    'hail': MdiIcons.weatherHail,
    'thunderstorm': MdiIcons.weatherLightning,
    'sunny': MdiIcons.weatherSunny,
    'mostly_sunny': MdiIcons.weatherSunny,
    'partly_sunny': MdiIcons.weatherPartlyCloudy,
    'mostly_cloudy': MdiIcons.weatherCloudy,
    'chance_of_rain': MdiIcons.weatherRainy,
    'showers': MdiIcons.weatherPouring,
  };

  static IconData getIcon(String key) {
    return _iconMap[key] ?? MdiIcons.weatherCloudy;
  }

  /// Determines the current overall icon key based on minutely + hourly data.
  /// If minutely shows precipitation in next 15 min, use a precipitation icon.
  /// Otherwise, use the current hourly icon.
  static String getCurrentIconKey(
    List<MinutelyDataPoint> minutely,
    List<HourlyDataPoint> hourly,
  ) {
    // Check if minutely data has precipitation in next 15 minutes
    bool hasMinutelyPrecip = false;
    for (int i = 0; i < 15 && i < minutely.length; i++) {
      if (PrecipitationColors.isPrecip(
        minutely[i].precipIntensity,
        minutely[i].precipProbability,
      )) {
        hasMinutelyPrecip = true;
        break;
      }
    }

    if (hasMinutelyPrecip && hourly.isNotEmpty) {
      final hourIcon = hourly[0].icon.toLowerCase();
      for (final type in ['rain', 'snow', 'sleet', 'hail', 'thunderstorm']) {
        if (hourIcon.contains(type)) return hourIcon;
      }
      return 'rain';
    }

    if (hourly.isNotEmpty) {
      return hourly[0].icon;
    }
    return 'cloudy';
  }
}
