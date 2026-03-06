class HourlyDataPoint {
  final int time;
  final String icon;
  final String summary;
  final double temperature;
  final double precipIntensity;
  final double precipProbability;

  const HourlyDataPoint({
    required this.time,
    required this.icon,
    required this.summary,
    required this.temperature,
    required this.precipIntensity,
    required this.precipProbability,
  });

  factory HourlyDataPoint.fromJson(Map<String, dynamic> json) {
    return HourlyDataPoint(
      time: (json['time'] as num).toInt(),
      icon: json['icon'] as String? ?? 'cloudy',
      summary: json['summary'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      precipIntensity: (json['precipIntensity'] as num?)?.toDouble() ?? 0.0,
      precipProbability:
          (json['precipProbability'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'icon': icon,
        'summary': summary,
        'temperature': temperature,
        'precipIntensity': precipIntensity,
        'precipProbability': precipProbability,
      };
}
