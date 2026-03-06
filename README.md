# Precipitation Radial Widget

A standalone Android app with a home screen widget that shows a radial precipitation forecast visualization. Powered by [PirateWeather](https://pirateweather.net) API.

No Home Assistant required — works as a standalone Android app.

## Features

- **Radial precipitation chart** — 60-minute minutely forecast (inner ring) + 12-hour hourly forecast (outer ring)
- **Home screen widget** — updates in background via WorkManager, even when the app is closed
- **Customizable appearance** — dark/light/system theme, custom background color, transparent mode
- **Configurable polling** — separate minutely (60–3600s) and hourly (300–7200s) intervals
- **Location** — manual lat/lon or device GPS (read once per poll, not continuous)
- **Color-coded intensity** — 8-step color scale from trace to torrential precipitation

## Install

1. Download the latest APK from [Releases](https://github.com/philrenda/precipitation-radial-widget/releases)
2. Sideload the APK on your Android device (enable "Install unknown apps" if needed)
3. Open the app and follow the setup wizard

## Setup

1. **Get a PirateWeather API key** — sign up free at [pirateweather.net](https://pirateweather.net)
2. Enter your API key in the app
3. Set your location (GPS or manual coordinates)
4. Add the "Precipitation Radial" widget to your home screen

## API Usage

At default polling intervals (minutely: 10min, hourly: 30min), the app uses ~5,760 API calls/month, well within PirateWeather's free tier of 10,000 calls/month.

## Color Scale (in/hr)

| Intensity | Color |
|-----------|-------|
| < 0.005 | Gray (none) |
| 0.005 | Light Green |
| 0.01 | Pale Green |
| 0.05 | Green |
| 0.15 | Yellow |
| 0.30 | Orange |
| 0.60 | Red-Orange |
| 1.0+ | Dark Red |

## Building from Source

```bash
flutter pub get
flutter test
flutter build apk --release
```

Requires Flutter SDK and Java 17.

## License

MIT
