import 'package:flutter/material.dart';

import '../models/weather_data.dart';
import '../painters/radial_chart_painter.dart';

class RadialChartWidget extends StatelessWidget {
  final WeatherData weatherData;
  final String locationName;
  final bool isDarkMode;
  final Color backgroundColor;

  const RadialChartWidget({
    super.key,
    required this.weatherData,
    required this.locationName,
    required this.isDarkMode,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: RadialChartPainter(
          weatherData: weatherData,
          locationName: locationName,
          isDarkMode: isDarkMode,
          backgroundColor: backgroundColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}
