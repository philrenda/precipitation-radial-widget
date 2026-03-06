import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import '../providers/settings_provider.dart';
import '../providers/weather_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _apiKeyController = TextEditingController(text: s.apiKey);
    _latController = TextEditingController(text: s.latitude.toString());
    _lonController = TextEditingController(text: s.longitude.toString());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // API Key
              _sectionHeader('API Key'),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'PirateWeather API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (v) => settings.setApiKey(v.trim()),
              ),

              const SizedBox(height: 24),
              _sectionHeader('Location'),
              SwitchListTile(
                title: const Text('Use device location'),
                subtitle: const Text(
                  'GPS read once per poll interval',
                ),
                value: settings.settings.useDeviceLocation,
                onChanged: (v) async {
                  await settings.setUseDeviceLocation(v);
                  if (v) {
                    final pos = await settings.getCurrentPosition();
                    if (pos != null) {
                      _latController.text = pos.latitude.toStringAsFixed(4);
                      _lonController.text = pos.longitude.toStringAsFixed(4);
                      await settings.setLocation(
                          pos.latitude, pos.longitude);
                    }
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !settings.settings.useDeviceLocation,
                      onChanged: (v) {
                        final lat = double.tryParse(v);
                        final lon =
                            double.tryParse(_lonController.text);
                        if (lat != null && lon != null) {
                          settings.setLocation(lat, lon);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !settings.settings.useDeviceLocation,
                      onChanged: (v) {
                        final lon = double.tryParse(v);
                        final lat =
                            double.tryParse(_latController.text);
                        if (lat != null && lon != null) {
                          settings.setLocation(lat, lon);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (settings.settings.locationName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Location: ${settings.settings.locationName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              const SizedBox(height: 24),
              _sectionHeader('Polling Intervals'),
              _intervalSlider(
                label: 'Minutely',
                value: settings.settings.minutelyIntervalSeconds,
                min: 60,
                max: 3600,
                defaultVal: 600,
                onChanged: (v) => settings.setMinutelyInterval(v),
              ),
              _intervalSlider(
                label: 'Hourly',
                value: settings.settings.hourlyIntervalSeconds,
                min: 300,
                max: 7200,
                defaultVal: 1800,
                onChanged: (v) => settings.setHourlyInterval(v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Est. ${settings.settings.estimatedMonthlyApiCalls} API calls/month (free: 10,000)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('Appearance'),
              const Text('Background'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _bgChip('Black', Colors.black, settings),
                  _bgChip('Dark Gray', const Color(0xFF333333), settings),
                  _bgChip('White', Colors.white, settings),
                  _transparentChip(settings),
                  _customColorChip(settings),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Theme'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (modes) {
                  settings.setThemeMode(modes.first);
                },
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context.read<WeatherProvider>().refresh();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Save & Refresh'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _intervalSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required int defaultVal,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${_formatInterval(value)}'),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ 60,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  String _formatInterval(int seconds) {
    if (seconds < 120) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  Widget _bgChip(String label, Color color, SettingsProvider settings) {
    final isSelected = !settings.settings.transparentBackground &&
        settings.settings.backgroundColor.value == color.value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => settings.setBackgroundColor(color),
      avatar: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _transparentChip(SettingsProvider settings) {
    return ChoiceChip(
      label: const Text('Transparent'),
      selected: settings.settings.transparentBackground,
      onSelected: (_) => settings.setTransparentBackground(true),
      avatar: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.grey],
          ),
        ),
      ),
    );
  }

  Widget _customColorChip(SettingsProvider settings) {
    return ActionChip(
      label: const Text('Custom'),
      onPressed: () async {
        Color pickedColor = settings.settings.backgroundColor;
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pick a color'),
            content: ColorPicker(
              color: pickedColor,
              onColorChanged: (c) => pickedColor = c,
              pickersEnabled: const {
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.wheel: true,
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Select'),
              ),
            ],
          ),
        );
        if (result == true) {
          settings.setBackgroundColor(pickedColor);
        }
      },
    );
  }
}
