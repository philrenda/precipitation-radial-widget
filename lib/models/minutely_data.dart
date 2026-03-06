class MinutelyDataPoint {
  final int time;
  final double precipIntensity;
  final double precipProbability;
  final double precipIntensityError;
  final String precipType;

  const MinutelyDataPoint({
    required this.time,
    required this.precipIntensity,
    required this.precipProbability,
    this.precipIntensityError = 0.0,
    this.precipType = 'none',
  });

  factory MinutelyDataPoint.fromJson(Map<String, dynamic> json) {
    return MinutelyDataPoint(
      time: (json['time'] as num).toInt(),
      precipIntensity: (json['precipIntensity'] as num?)?.toDouble() ?? 0.0,
      precipProbability:
          (json['precipProbability'] as num?)?.toDouble() ?? 0.0,
      precipIntensityError:
          (json['precipIntensityError'] as num?)?.toDouble() ?? 0.0,
      precipType: json['precipType'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'precipIntensity': precipIntensity,
        'precipProbability': precipProbability,
        'precipIntensityError': precipIntensityError,
        'precipType': precipType,
      };
}
