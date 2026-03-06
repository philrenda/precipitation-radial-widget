import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'services/storage_service.dart';
import 'services/pirate_weather_service.dart';
import 'services/widget_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background tasks are handled by native Kotlin WorkManager.
    // This Dart callback is a no-op; the Kotlin WidgetUpdateWorker
    // does the actual API fetch + render.
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  HomeWidget.setAppGroupId('com.philrenda.precipitationradialwidget');

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, WeatherProvider>(
          create: (context) => WeatherProvider(
            PirateWeatherService(),
            storageService,
            WidgetService(),
          ),
          update: (context, settings, previous) =>
              previous!..updateSettings(settings),
        ),
      ],
      child: const PrecipitationRadialApp(),
    ),
  );
}
