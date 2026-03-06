import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'services/storage_service.dart';
import 'services/pirate_weather_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  HomeWidget.setAppGroupId('com.philrenda.precipitationradialwidget');

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
