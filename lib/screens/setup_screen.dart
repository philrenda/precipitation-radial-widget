import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/weather_provider.dart';
import '../services/pirate_weather_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _apiKeyController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  int _currentStep = 0;
  bool _validating = false;
  String? _validationError;
  bool _useGps = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _validateApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _validationError = 'API key cannot be empty');
      return;
    }

    setState(() {
      _validating = true;
      _validationError = null;
    });

    // Use a test location (NYC)
    final valid = await PirateWeatherService()
        .validateApiKey(apiKey, 40.7128, -74.0060);

    setState(() {
      _validating = false;
      if (valid) {
        _validationError = null;
        _currentStep = 1;
      } else {
        _validationError = 'Invalid API key or network error';
      }
    });

    if (valid) {
      await context.read<SettingsProvider>().setApiKey(apiKey);
    }
  }

  Future<void> _getGpsLocation() async {
    setState(() => _validating = true);

    final settings = context.read<SettingsProvider>();
    final pos = await settings.getCurrentPosition();

    if (pos != null) {
      _latController.text = pos.latitude.toStringAsFixed(4);
      _lonController.text = pos.longitude.toStringAsFixed(4);
      await settings.setUseDeviceLocation(true);
      await settings.setLocation(pos.latitude, pos.longitude);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get GPS location')),
        );
      }
    }

    setState(() => _validating = false);
  }

  Future<void> _finishSetup() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude')),
      );
      return;
    }

    final settings = context.read<SettingsProvider>();
    if (!_useGps) {
      await settings.setUseDeviceLocation(false);
    }
    await settings.setLocation(lat, lon);
    await settings.setSetupComplete(true);

    if (mounted) {
      // Trigger initial data fetch
      await context.read<WeatherProvider>().refresh();
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: Stepper(
        currentStep: _currentStep,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('PirateWeather API Key'),
            isActive: _currentStep >= 0,
            state:
                _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get a free API key at pirateweather.net',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    border: const OutlineInputBorder(),
                    errorText: _validationError,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _validating ? null : _validateApiKey,
                  child: _validating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Validate & Continue'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Location'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Use device location'),
                  subtitle: const Text(
                    'GPS is read once per poll interval, not continuously',
                  ),
                  value: _useGps,
                  onChanged: (value) {
                    setState(() => _useGps = value);
                    if (value) _getGpsLocation();
                  },
                ),
                const SizedBox(height: 8),
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
                        enabled: !_useGps,
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
                        enabled: !_useGps,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _validating ? null : _finishSetup,
                  child: const Text('Finish Setup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
