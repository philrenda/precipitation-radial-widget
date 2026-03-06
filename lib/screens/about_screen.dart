import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.grain, size: 64),
          const SizedBox(height: 16),
          Text(
            'Precipitation Radial Widget',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Powered by PirateWeather'),
            subtitle: Text('pirateweather.net'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Source Code'),
            subtitle:
                Text('github.com/philrenda/precipitation-radial-widget'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Precipitation Radial Widget',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}
