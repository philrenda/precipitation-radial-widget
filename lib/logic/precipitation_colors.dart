import 'dart:ui';

/// 8-step color scale for precipitation intensity (inches/hour).
/// Matches the JS card's _getColorForPrecip exactly.
class PrecipitationColors {
  static const double probThreshold = 0.10;
  static const double intensityThreshold = 0.005;

  static const Color noPercip = Color(0xFFCCCCCC);
  static const Color trace = Color(0xFFAED581);
  static const Color veryLight = Color(0xFF9CCC65);
  static const Color light = Color(0xFF66BB6A);
  static const Color moderate = Color(0xFFFFEE58);
  static const Color heavy = Color(0xFFFFCA28);
  static const Color veryHeavy = Color(0xFFFF7043);
  static const Color extreme = Color(0xFFE53935);

  /// Dark theme base ring color (no precipitation).
  static const Color baseRingDark = Color(0xFF444444);

  /// Light theme base ring color (no precipitation).
  static const Color baseRingLight = Color(0xFFE0E0E0);

  /// Returns the color for a given precipitation intensity and probability.
  static Color getColor(double intensity, double probability) {
    if (probability < probThreshold || intensity < intensityThreshold) {
      return noPercip;
    }
    if (intensity < 0.01) return trace;
    if (intensity < 0.05) return veryLight;
    if (intensity < 0.15) return light;
    if (intensity < 0.30) return moderate;
    if (intensity < 0.60) return heavy;
    if (intensity < 1.0) return veryHeavy;
    return extreme;
  }

  /// Whether a data point qualifies as precipitating.
  static bool isPrecip(double intensity, double probability) {
    return intensity >= intensityThreshold && probability >= probThreshold;
  }

  /// All threshold entries for the legend.
  static const List<({String label, double intensity, Color color})>
      legendEntries = [
    (label: '<0.005', intensity: 0.0, color: noPercip),
    (label: '0.005', intensity: 0.005, color: trace),
    (label: '0.01', intensity: 0.01, color: veryLight),
    (label: '0.05', intensity: 0.05, color: light),
    (label: '0.15', intensity: 0.15, color: moderate),
    (label: '0.30', intensity: 0.30, color: heavy),
    (label: '0.60', intensity: 0.60, color: veryHeavy),
    (label: '1.0+', intensity: 1.0, color: extreme),
  ];
}
