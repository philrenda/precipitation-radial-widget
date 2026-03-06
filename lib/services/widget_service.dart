import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../painters/radial_chart_painter.dart';
import '../models/weather_data.dart';

/// Bridge to push rendered bitmaps to the native Android widget.
class WidgetService {
  static const int renderSize = 800;

  /// Renders the radial chart to a PNG and updates the native widget.
  Future<void> updateWidget({
    required WeatherData data,
    required String locationName,
    required bool isDarkMode,
    required Color backgroundColor,
    required bool transparentBackground,
  }) async {
    try {
      // Render chart to image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 800);

      final painter = RadialChartPainter(
        weatherData: data,
        locationName: locationName,
        isDarkMode: isDarkMode,
        backgroundColor: transparentBackground
            ? Colors.transparent
            : backgroundColor,
      );

      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(renderSize, renderSize);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      // Save PNG to app storage
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final file = File('${directory.path}/widget_chart.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Push to native widget via home_widget
      await HomeWidget.saveWidgetData<String>(
        'chart_path',
        file.path,
      );
      await HomeWidget.updateWidget(
        androidName: 'PrecipitationWidget',
      );
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
