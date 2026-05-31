class PredictionResult {
  final String disease;
  final double confidence;
  final String severity;
  final String recommendation;
  final String heatmapBase64;
  final List<Map<String, dynamic>> allPredictions;

  PredictionResult({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.recommendation,
    required this.heatmapBase64,
    required this.allPredictions,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Process all predictions cleanly
    var predsRaw = json['all_predictions'] as List? ?? [];
    List<Map<String, dynamic>> processedPreds = predsRaw.map((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();

    return PredictionResult(
      disease: json['disease'] as String? ?? 'Unknown Skin Condition',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      severity: json['severity'] as String? ?? 'Moderate',
      recommendation: json['recommendation'] as String? ?? '',
      heatmapBase64: json['heatmap'] as String? ?? '',
      allPredictions: processedPreds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'recommendation': recommendation,
      'heatmap': heatmapBase64,
      'all_predictions': allPredictions,
    };
  }
}
