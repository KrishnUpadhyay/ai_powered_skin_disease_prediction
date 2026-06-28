import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/prediction_model.dart';
import 'api_service.dart';

class PdfReportHelper {
  static Future<Uint8List> generateClinicalReport(
    PredictionResult prediction,
    Uint8List originalImageBytes,
  ) async {
    final pdf = pw.Document();
    
    // Convert memory image bytes safely
    pw.MemoryImage? pdfImage;
    if (originalImageBytes.isNotEmpty) {
      try {
        pdfImage = pw.MemoryImage(originalImageBytes);
      } catch (_) {
        // Ignored fallback
      }
    }

    final user = ApiService.currentUser;
    final patientName = user != null ? user['name'] as String? ?? 'User Account' : 'Anonymous User';
    final patientEmail = user != null ? user['email'] as String? ?? 'N/A' : 'N/A';
    final patientPhone = user != null ? user['phone_number'] as String? ?? 'N/A' : 'N/A';
    final reportDate = DateTime.now().toString().substring(0, 16);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DermaScan AI',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Clinical Diagnostic Screening Report',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $reportDate',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Report ID: DS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(thickness: 1.5, color: PdfColors.teal),
              pw.SizedBox(height: 16),

              // Patient Info Section
              pw.Text(
                'PATIENT INFORMATION',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Patient Name: $patientName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Email: $patientEmail', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Phone: $patientPhone', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              
              pw.SizedBox(height: 20),

              // Main Diagnostic Overview box (Teal shaded card)
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(14),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PRIMARY CLASSIFICATION',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          prediction.disease,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'MATCH CONFIDENCE: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'SEVERITY: ${prediction.severity.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: prediction.severity.toUpperCase() == 'SEVERE' 
                                ? PdfColors.red800 
                                : PdfColors.teal800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Symptoms & Image layout
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left side: Description & Triage Advice
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLINICAL FINDINGS & TRIAGE ADVICE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          prediction.recommendation,
                          style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.3),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right side: Embedded scan photo
                  if (pdfImage != null)
                    pw.Column(
                      children: [
                        pw.Text(
                          'VISUAL EVIDENCE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: 140,
                          height: 140,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
                        ),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Care Guidelines: Remedies and Treatments
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Remedies
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RECOMMENDED HOME CARE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        if (prediction.homeRemedies.isEmpty)
                          pw.Text('No specific home remedies logged.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
                        else
                          ...prediction.homeRemedies.map((remedy) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('- ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                    pw.Expanded(child: pw.Text(remedy, style: const pw.TextStyle(fontSize: 9))),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Treatments
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLINICAL TREATMENTS (CONSULT DOCTOR)',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        if (prediction.medicalTreatments.isEmpty)
                          pw.Text('Clinical evaluation required.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
                        else
                          ...prediction.medicalTreatments.map((treatment) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('- ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                    pw.Expanded(child: pw.Text(treatment, style: const pw.TextStyle(fontSize: 9))),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Legal Disclaimer Footer
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  'DISCLAIMER: This diagnostic report is generated by the DermaScan AI screening model. '
                  'This is for educational and tracking support only, and does NOT constitute formal medical advice. '
                  'It does not replace professional clinical biopsies, examinations, or consultations with a board-certified dermatologist.',
                  textAlign: pw.TextAlign.justify,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
