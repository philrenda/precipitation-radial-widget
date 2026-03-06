import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/weather_data.dart';
import '../logic/precipitation_colors.dart';
import '../logic/weather_summary.dart';
import '../logic/weather_icons.dart';
import '../logic/hour_formatter.dart';

/// Renders the radial precipitation chart to a Flutter Canvas.
/// Direct port of the JS SVG card to Canvas API.
///
/// Coordinate system: 100×100 logical units, scaled to actual size.
class RadialChartPainter extends CustomPainter {
  final WeatherData weatherData;
  final String locationName;
  final bool isDarkMode;
  final Color backgroundColor;

  // Shared constants (must match Kotlin renderer)
  static const double _coordSpace = 100.0;
  static const double _center = 50.0;
  static const double _minuteRingRadius = 30.0;
  static const double _barWidth = 4.5;
  static const double _hourRingRadius = 42.5; // 30 + 4.5 + 8
  static const double _hourDotRadius = 3.2;

  RadialChartPainter({
    required this.weatherData,
    required this.locationName,
    required this.isDarkMode,
    this.backgroundColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _coordSpace;
    canvas.save();
    canvas.scale(scale, scale);

    // Background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _coordSpace, _coordSpace),
      bgPaint,
    );

    _drawBaseRing(canvas);
    _drawMinutelyBars(canvas);
    _drawMinuteLabels(canvas);
    _drawBaseHourTicks(canvas);
    _drawHourlyDots(canvas);
    _drawHourLabels(canvas);
    _drawCenterContent(canvas);
    _drawLocationName(canvas);

    canvas.restore();
  }

  void _drawBaseRing(Canvas canvas) {
    final paint = Paint()
      ..color = isDarkMode
          ? PrecipitationColors.baseRingDark
          : PrecipitationColors.baseRingLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = _barWidth + 0.5;
    canvas.drawCircle(
      const Offset(_center, _center),
      _minuteRingRadius,
      paint,
    );
  }

  void _drawMinutelyBars(Canvas canvas) {
    final data = weatherData.minutely;
    final count = min(60, data.length);

    for (int i = 0; i < count; i++) {
      final point = data[i];
      if (!PrecipitationColors.isPrecip(
        point.precipIntensity,
        point.precipProbability,
      )) {
        continue;
      }

      final color = PrecipitationColors.getColor(
        point.precipIntensity,
        point.precipProbability,
      );

      // Angle: starts at top (12 o'clock), clockwise
      // i=15 is straight up in the original JS
      final angle = ((i - 15) / 60) * 2 * pi;

      final innerR = _minuteRingRadius - _barWidth;
      final outerR = _minuteRingRadius;

      final x1 = _center + innerR * cos(angle);
      final y1 = _center + innerR * sin(angle);
      final x2 = _center + outerR * cos(angle);
      final y2 = _center + outerR * sin(angle);

      final paint = Paint()
        ..color = color
        ..strokeWidth = _barWidth + 0.5
        ..strokeCap = StrokeCap.butt;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawMinuteLabels(Canvas canvas) {
    final labels = [0, 10, 20, 30, 40, 50];
    final labelRadius = _minuteRingRadius - _barWidth / 2; // 27.75

    for (final minute in labels) {
      final angle = ((minute - 15) / 60) * 2 * pi;
      final x = _center + labelRadius * cos(angle);
      final y = _center + labelRadius * sin(angle);

      _drawOutlinedText(
        canvas,
        minute.toString(),
        Offset(x, y),
        2.8,
        FontWeight.bold,
      );
    }
  }

  void _drawBaseHourTicks(Canvas canvas) {
    final paint = Paint()
      ..color = isDarkMode
          ? PrecipitationColors.baseRingDark
          : PrecipitationColors.baseRingLight
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = ((i - 3) / 12) * 2 * pi;
      final x = _center + _hourRingRadius * cos(angle);
      final y = _center + _hourRingRadius * sin(angle);
      canvas.drawCircle(Offset(x, y), _hourDotRadius * 0.7, paint);
    }
  }

  void _drawHourlyDots(Canvas canvas) {
    final hourNow = DateTime.now().hour;
    final count = min(12, weatherData.hourly.length);

    for (int i = 0; i < count; i++) {
      final data = weatherData.hourly[i];

      if (!PrecipitationColors.isPrecip(
        data.precipIntensity,
        data.precipProbability,
      )) {
        continue;
      }

      final color = PrecipitationColors.getColor(
        data.precipIntensity,
        data.precipProbability,
      );

      final actualHour = (hourNow + i) % 24;
      final clockPos = actualHour % 12;
      final angle = ((clockPos - 3) / 12) * 2 * pi;

      final x = _center + _hourRingRadius * cos(angle);
      final y = _center + _hourRingRadius * sin(angle);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), _hourDotRadius, paint);
    }
  }

  void _drawHourLabels(Canvas canvas) {
    final hourNow = DateTime.now().hour;

    for (int i = 0; i < 12; i++) {
      final actualHour = (hourNow + i) % 24;
      final clockPos = actualHour % 12;
      final angle = ((clockPos - 3) / 12) * 2 * pi;

      // Place labels slightly outside the hour ring
      final labelR = _hourRingRadius + _hourDotRadius + 2.0;
      final x = _center + labelR * cos(angle);
      final y = _center + labelR * sin(angle);

      _drawOutlinedText(
        canvas,
        HourFormatter.format(actualHour),
        Offset(x, y),
        3.2,
        FontWeight.normal,
      );
    }
  }

  void _drawCenterContent(Canvas canvas) {
    // Weather icon
    final iconKey = WeatherIcons.getCurrentIconKey(
      weatherData.minutely,
      weatherData.hourly,
    );
    final iconData = WeatherIcons.getIcon(iconKey);
    _drawIcon(canvas, iconData, const Offset(_center, _center - 10), 12);

    // Summary text
    final summary = WeatherSummary.getSummary(
      weatherData.minutely,
      weatherData.hourly,
    );
    _drawCenteredText(
      canvas,
      summary,
      const Offset(_center, _center - 1),
      3.0,
      isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF333333),
      FontWeight.w500,
    );

    // Temperature: current / high / low
    final temp = weatherData.currentTemp.round();
    final high = weatherData.todayHigh.round();
    final low = weatherData.todayLow.round();
    _drawCenteredText(
      canvas,
      '$temp°F  H:$high° L:$low°',
      const Offset(_center, _center + 4),
      2.6,
      isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF555555),
      FontWeight.normal,
    );

    // Wind speed
    final wind = weatherData.windSpeed.round();
    _drawCenteredText(
      canvas,
      'Wind $wind mph',
      const Offset(_center, _center + 8),
      2.4,
      isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF555555),
      FontWeight.normal,
    );
  }

  void _drawLocationName(Canvas canvas) {
    if (locationName.isEmpty) return;
    _drawOutlinedText(
      canvas,
      locationName,
      const Offset(5, 5),
      3.0,
      FontWeight.w500,
      align: TextAlign.left,
    );
  }

  void _drawIcon(Canvas canvas, IconData iconData, Offset center, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: isDarkMode ? Colors.white : const Color(0xFF333333),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 60);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawOutlinedText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize,
    FontWeight weight, {
    TextAlign align = TextAlign.center,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final strokeColor = isDarkMode ? Colors.black : Colors.white;

    // Draw stroke (outline)
    final strokePainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = strokeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    strokePainter.layout();

    final offset = align == TextAlign.left
        ? position
        : Offset(
            position.dx - strokePainter.width / 2,
            position.dy - strokePainter.height / 2,
          );

    strokePainter.paint(canvas, offset);

    // Draw fill
    final fillPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    fillPainter.layout();
    fillPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant RadialChartPainter oldDelegate) {
    return weatherData != oldDelegate.weatherData ||
        locationName != oldDelegate.locationName ||
        isDarkMode != oldDelegate.isDarkMode ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
