import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/radial_chart_widget.dart';
import '../widgets/color_legend.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initial fetch if no data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weather = context.read<WeatherProvider>();
      if (!weather.hasData) {
        weather.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Precipitation Radial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
      body: Consumer2<WeatherProvider, SettingsProvider>(
        builder: (context, weather, settings, _) {
          return RefreshIndicator(
            onRefresh: () => weather.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (weather.isLoading && !weather.hasData)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (weather.hasData)
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: settings.settings.transparentBackground
                              ? null
                              : settings.settings.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadialChartWidget(
                          weatherData: weather.weatherData!,
                          locationName: settings.settings.locationName,
                          isDarkMode: settings.isDarkMode,
                          backgroundColor:
                              settings.settings.transparentBackground
                                  ? Colors.transparent
                                  : settings.settings.backgroundColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ColorLegend(),
                      const SizedBox(height: 8),
                      Text(
                        'in/hr',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  )
                else if (weather.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            weather.error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => weather.refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (weather.hasData) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: ${_formatTime(weather.weatherData!.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (weather.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }
}
