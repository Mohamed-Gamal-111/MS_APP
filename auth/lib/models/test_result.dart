class TestResult {
  final String test;
  final String? label;
  final String? prediction;
  final num? score;
  final num? confidence;
  final num? pHealthy;
  final num? pPatient;
  final int? framesUsed;
  final Map<String, dynamic> features;
  final Map<String, dynamic> chartData;
  final String? warning;
  final String? error;
  final String? message;

  TestResult({
    required this.test,
    this.label,
    this.prediction,
    this.score,
    this.confidence,
    this.pHealthy,
    this.pPatient,
    this.framesUsed,
    required this.features,
    required this.chartData,
    this.warning,
    this.error,
    this.message,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      test: json['test']?.toString() ?? 'unknown',
      label: json['label']?.toString(),
      prediction: json['prediction']?.toString(),
      score: json['score'] is num ? json['score'] as num : null,
      confidence: json['confidence'] is num ? json['confidence'] as num : null,
      pHealthy: json['p_healthy'] is num ? json['p_healthy'] as num : null,
      pPatient: json['p_patient'] is num ? json['p_patient'] as num : null,
      framesUsed: json['frames_used'] is int ? json['frames_used'] as int : null,
      features: json['features'] is Map<String, dynamic> ? json['features'] as Map<String, dynamic> : {},
      chartData: json['chart_data'] is Map<String, dynamic> ? json['chart_data'] as Map<String, dynamic> : {},
      warning: json['warning']?.toString(),
      error: json['error']?.toString(),
      message: json['message']?.toString(),
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;
}
