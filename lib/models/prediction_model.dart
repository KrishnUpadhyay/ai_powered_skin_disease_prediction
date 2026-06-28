class PredictionResult {
  final String disease;
  final double confidence;
  final String severity;
  final String recommendation;
  final String heatmapBase64;
  final List<Map<String, dynamic>> allPredictions;
  final List<String> homeRemedies;
  final List<String> medicalTreatments;
  final double processingLatency;
  final bool cancerRiskAlert;

  PredictionResult({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.recommendation,
    required this.heatmapBase64,
    required this.allPredictions,
    required this.homeRemedies,
    required this.medicalTreatments,
    required this.processingLatency,
    required this.cancerRiskAlert,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    var predsRaw = json['all_predictions'] as List? ?? [];
    List<Map<String, dynamic>> processedPreds = predsRaw.map((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();

    var remediesRaw = json['home_remedies'] as List? ?? [];
    List<String> remedies = remediesRaw.map((e) => e.toString()).toList();

    var treatmentsRaw = json['medical_treatments'] as List? ?? [];
    List<String> treatments = treatmentsRaw.map((e) => e.toString()).toList();

    return PredictionResult(
      disease: json['disease'] as String? ?? 'Unknown Skin Condition',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      severity: json['severity'] as String? ?? 'Moderate',
      recommendation: json['recommendation'] as String? ?? '',
      heatmapBase64: json['heatmap'] as String? ?? '',
      allPredictions: processedPreds,
      homeRemedies: remedies,
      medicalTreatments: treatments,
      processingLatency: (json['processing_latency'] as num? ?? 0.0).toDouble(),
      cancerRiskAlert: json['cancer_risk_alert'] as bool? ?? false,
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
      'home_remedies': homeRemedies,
      'medical_treatments': medicalTreatments,
      'processing_latency': processingLatency,
      'cancer_risk_alert': cancerRiskAlert,
    };
  }
}
