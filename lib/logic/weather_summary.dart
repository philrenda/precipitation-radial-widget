import '../models/minutely_data.dart';
import '../models/hourly_data.dart';
import 'precipitation_colors.dart';

/// Port of the JS card's _getCombinedWeatherSummary algorithm.
class WeatherSummary {
  static const int _drySpellMinutes = 5;

  /// Returns a human-readable summary like "Light Rain ending in 5 min".
  static String getSummary(
    List<MinutelyDataPoint> minutely,
    List<HourlyDataPoint> hourly,
  ) {
    if (minutely.isEmpty && hourly.isEmpty) return 'No data';
    if (minutely.isEmpty) {
      return hourly.isNotEmpty ? hourly[0].summary : 'No data';
    }

    final precipType = _getPrecipType(hourly);

    bool isCurrentlyPrecipitating = false;
    double maxIntensity = 0.0;
    int actualStartsIn = -1;
    int actualSpellDuration = -1;
    int actualEndsIn = -1;

    // Check first minute
    if (_isPrecip(minutely[0])) {
      isCurrentlyPrecipitating = true;
      maxIntensity = minutely[0].precipIntensity;
    }

    if (isCurrentlyPrecipitating) {
      // Currently raining — find when it ends
      for (int i = 1; i < minutely.length; i++) {
        if (_isPrecip(minutely[i])) {
          if (minutely[i].precipIntensity > maxIntensity) {
            maxIntensity = minutely[i].precipIntensity;
          }
        } else {
          // Check for dry spell of _drySpellMinutes
          bool isDrySpell = true;
          for (int j = i; j < i + _drySpellMinutes && j < minutely.length; j++) {
            if (_isPrecip(minutely[j])) {
              isDrySpell = false;
              break;
            }
          }
          if (isDrySpell) {
            actualEndsIn = i;
            break;
          }
        }
      }
      if (actualEndsIn == -1) {
        actualEndsIn = minutely.length;
      }
    } else {
      // Not raining — find when it starts
      int firstPrecipMinute = -1;
      int lastPrecipMinute = -1;

      for (int i = 1; i < minutely.length; i++) {
        if (_isPrecip(minutely[i])) {
          if (minutely[i].precipIntensity > maxIntensity) {
            maxIntensity = minutely[i].precipIntensity;
          }
          if (firstPrecipMinute == -1) {
            firstPrecipMinute = i;
          }
          lastPrecipMinute = i;
        } else if (firstPrecipMinute != -1) {
          // Check for dry spell
          bool isDrySpell = true;
          for (int j = i; j < i + _drySpellMinutes && j < minutely.length; j++) {
            if (_isPrecip(minutely[j])) {
              isDrySpell = false;
              break;
            }
          }
          if (isDrySpell) {
            actualStartsIn = firstPrecipMinute;
            actualSpellDuration = lastPrecipMinute - firstPrecipMinute + 1;
            break;
          }
        }
      }
      if (firstPrecipMinute != -1 && actualStartsIn == -1) {
        actualStartsIn = firstPrecipMinute;
        actualSpellDuration = lastPrecipMinute - firstPrecipMinute + 1;
      }
    }

    final intensityDesc = _getIntensityDescription(maxIntensity, precipType);

    if (isCurrentlyPrecipitating) {
      if (actualEndsIn < minutely.length) {
        return '$intensityDesc ending in $actualEndsIn min';
      }
      return '$intensityDesc ongoing';
    }

    if (actualStartsIn > 0) {
      if (actualSpellDuration > 0) {
        return '$intensityDesc starting in $actualStartsIn min, for $actualSpellDuration min';
      }
      return '$intensityDesc starting in $actualStartsIn min';
    }

    // Fallback to hourly summary
    if (hourly.isNotEmpty) {
      return hourly[0].summary;
    }
    return 'No precipitation expected';
  }

  static bool _isPrecip(MinutelyDataPoint point) {
    return PrecipitationColors.isPrecip(
      point.precipIntensity,
      point.precipProbability,
    );
  }

  static String _getPrecipType(List<HourlyDataPoint> hourly) {
    if (hourly.isEmpty) return 'Rain';
    final icon = hourly[0].icon.toLowerCase();
    if (icon.contains('snow')) return 'Snow';
    if (icon.contains('sleet')) return 'Sleet';
    if (icon.contains('rain') ||
        icon.contains('showers') ||
        icon.contains('thunderstorm')) return 'Rain';
    return 'Precipitation';
  }

  static String _getIntensityDescription(double intensity, String type) {
    if (intensity >= 0.8) return 'Very Heavy $type';
    if (intensity >= 0.5) return 'Heavy $type';
    if (intensity >= 0.2) return 'Moderate $type';
    if (intensity > 0.005) return 'Light $type';
    return type;
  }
}
