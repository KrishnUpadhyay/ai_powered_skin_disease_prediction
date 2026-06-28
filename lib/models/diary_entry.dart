class DiaryEntry {
  final int? id;
  final String disease;
  final double confidence;
  final String severity;
  final DateTime date;
  final String imageBase64;
  final String treatmentNotes;
  final int treatmentProgress;
  final String homeRemedies;

  DiaryEntry({
    this.id,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.date,
    required this.imageBase64,
    this.treatmentNotes = '',
    this.treatmentProgress = 0,
    this.homeRemedies = '',
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as int?,
      disease: json['disease'] as String? ?? 'Unknown Skin Condition',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      severity: json['severity'] as String? ?? 'Moderate',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      imageBase64: json['image_base64'] as String? ?? '',
      treatmentNotes: json['treatment_notes'] as String? ?? '',
      treatmentProgress: json['treatment_progress'] as int? ?? 0,
      homeRemedies: json['home_remedies'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'date': date.toIso8601String(),
      'image_base64': imageBase64,
      'treatment_notes': treatmentNotes,
      'treatment_progress': treatmentProgress,
      'home_remedies': homeRemedies,
    };
  }
}
