class PredictionResult {
  final String conditionName;
  final double confidence; // Percentage, e.g., 91.4
  final String severity; // Mild, Moderate, Severe
  final String riskLevel; // Low, Medium, High
  final String description;
  final List<String> careTips;
  final String doctorAction;

  PredictionResult({
    required this.conditionName,
    required this.confidence,
    required this.severity,
    required this.riskLevel,
    required this.description,
    required this.careTips,
    required this.doctorAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'conditionName': conditionName,
      'confidence': confidence,
      'severity': severity,
      'riskLevel': riskLevel,
      'description': description,
      'careTips': careTips,
      'doctorAction': doctorAction,
    };
  }

  factory PredictionResult.fromMap(Map<dynamic, dynamic> map) {
    return PredictionResult(
      conditionName: map['conditionName'] as String? ?? 'Unknown Skin Condition',
      confidence: (map['confidence'] as num? ?? 0.0).toDouble(),
      severity: map['severity'] as String? ?? 'Moderate',
      riskLevel: map['riskLevel'] as String? ?? 'Medium',
      description: map['description'] as String? ?? '',
      careTips: List<String>.from(map['careTips'] as List? ?? []),
      doctorAction: map['doctorAction'] as String? ?? '',
    );
  }
}
