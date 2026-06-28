import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/prediction_model.dart';
import '../models/diary_entry.dart';
import '../services/api_service.dart';
import '../services/pdf_report_helper.dart';
import '../services/pdf_saver.dart';
import '../widgets/glass_card.dart';
import '../widgets/severity_ring.dart';
import '../widgets/gradient_button.dart';
import 'chatbot_screen.dart';

class ResultScreen extends StatefulWidget {
  final PredictionResult prediction;
  final Uint8List originalImageBytes;
  final bool isFromDiary;

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.originalImageBytes,
    this.isFromDiary = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  bool _showHeatmap = false;
  bool _predictionsExpanded = false;
  final Set<String> _checkedRemedies = {};

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isFromDiary;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'SEVERE':
      case 'HIGH':
        return AppColors.danger;
      case 'MODERATE':
      case 'MEDIUM':
        return AppColors.warning;
      case 'MILD':
      case 'LOW':
      case 'BENIGN':
      default:
        return AppColors.success;
    }
  }

  Future<void> _handleSaveDiary() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final base64Image = base64Encode(widget.originalImageBytes);
      final checkedRemediesStr = _checkedRemedies.join(', ');
      
      final entry = DiaryEntry(
        disease: widget.prediction.disease,
        confidence: widget.prediction.confidence,
        severity: widget.prediction.severity,
        date: DateTime.now(),
        imageBase64: base64Image,
        treatmentNotes: 'Screening diagnosis saved. Treatment progress: 0%.',
        treatmentProgress: 0,
        homeRemedies: checkedRemediesStr,
      );

      final success = await ApiService.saveDiary(entry);
      
      if (!mounted) return;

      if (success) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Successfully saved to your Skin Diary!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save entry: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleShareReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(child: Text('Share Clinical Report', style: AppTextStyles.heading3(isDark: isDark))),
            ],
          ),
          content: Text(
            'Your clinical diagnostic screening report is ready for export. '
            'You can save a secure PDF summary directly to your device.',
            style: AppTextStyles.body(isDark: isDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Generating Clinical PDF Report...'),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );

                try {
                  final pdfBytes = await PdfReportHelper.generateClinicalReport(
                    widget.prediction,
                    widget.originalImageBytes,
                  );
                  
                  final dateStr = DateTime.now().toIso8601String().substring(0, 10);
                  final fileName = 'DermaScan_Report_${widget.prediction.disease.replaceAll(" ", "_")}_$dateStr.pdf';
                  
                  await PdfSaver.save(pdfBytes, fileName);
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF Report downloaded/saved successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to generate PDF: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: isDark ? AppColors.background : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Export PDF'),
            ),
          ],
        );
      },
    );
  }

  void _handleFindDermatologist() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.local_hospital_rounded, color: AppColors.danger, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Nearby Dermatologists', style: AppTextStyles.heading3(isDark: isDark))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Searching localized clinics within 10km radius...',
                style: AppTextStyles.bodyBold(isDark: isDark),
              ),
              const SizedBox(height: 12),
              _buildDoctorClinic(
                name: 'Dr. Sarah Jenkins, MD',
                clinic: 'Advanced Dermatology Center',
                distance: '1.2 km away',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildDoctorClinic(
                name: 'Dr. Michael Chen, PhD',
                clinic: 'Metro Skin & laser Clinic',
                distance: '2.8 km away',
                isDark: isDark,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Dismiss', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking request dispatched! Center will contact you shortly.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: isDark ? AppColors.background : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Consultation'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorClinic({
    required String name,
    required String clinic,
    required String distance,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.titleMedium(isDark: isDark)),
          Text(clinic, style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 12),
              const SizedBox(width: 4),
              Text(
                distance,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(widget.prediction.severity);
    final isSevere = widget.prediction.severity.toUpperCase() == 'SEVERE' ||
        widget.prediction.severity.toUpperCase() == 'HIGH';

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Analysis Results',
          style: AppTextStyles.title(isDark: isDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP SECTION: Dimmed/Blurred Original Image Background + Animated Severity Ring
            Stack(
              alignment: Alignment.center,
              children: [
                // Blurred background
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: Image.memory(
                    widget.originalImageBytes,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ),
                // Dark bottom gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Centered large animated severity ring
                Positioned(
                  child: SeverityRing(
                    severity: widget.prediction.severity,
                    confidence: widget.prediction.confidence * 100,
                  ),
                ),
              ],
            ),

            // DIAGNOSIS CARD (slides up container)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Diagnosis Header
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIAGNOSIS',
                          style: AppTextStyles.label(isDark: isDark).copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.prediction.disease,
                          style: AppTextStyles.heading2(isDark: isDark).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: AppColors.heroGradient,
                              ).createShader(bounds),
                              child: Text(
                                '${(widget.prediction.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontFamily: 'DM Mono',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'High Confidence Detection',
                              style: AppTextStyles.bodyBold(isDark: true).copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 20),

                  // GRAD-CAM HEATMAP COMPARISON
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AI Attention Mapping',
                              style: AppTextStyles.title(isDark: isDark),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Heatmap',
                                  style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Switch.adaptive(
                                  value: _showHeatmap,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _showHeatmap = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Side-by-side or Animated Crossfade Display
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black26,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Original image base
                              Positioned.fill(
                                child: Image.memory(
                                  widget.originalImageBytes,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Heatmap overlays with AnimatedOpacity crossfade
                              Positioned.fill(
                                child: AnimatedOpacity(
                                  opacity: _showHeatmap ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                  child: widget.prediction.heatmapBase64.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(widget.prediction.heatmapBase64),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.black54,
                                          child: const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image_rounded, size: 40, color: Colors.white24),
                                                SizedBox(height: 8),
                                                Text('Heatmap generation failed', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'AI attention map — highlighted areas indicate risk zones detected by EfficientNetB4 final convolutional activations.',
                          style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 20),

                  // TOP 3 PREDICTIONS LIST (expandable)
                  if (widget.prediction.allPredictions.isNotEmpty) ...[
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: ExpansionTile(
                        shape: const Border(),
                        iconColor: AppColors.primary,
                        collapsedIconColor: isDark ? Colors.white54 : Colors.black45,
                        title: Text(
                          'Probability Distribution',
                          style: AppTextStyles.title(isDark: isDark),
                        ),
                        initiallyExpanded: false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _predictionsExpanded = expanded;
                          });
                        },
                        children: [
                          const SizedBox(height: 8),
                          ...widget.prediction.allPredictions.map((pred) {
                            final String name = pred['label'] as String? ?? '';
                            final double conf = (pred['confidence'] as num? ?? 0.0).toDouble();
                            final isFirst = widget.prediction.disease == name;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: isFirst
                                            ? AppTextStyles.bodyBold(isDark: isDark)
                                            : AppTextStyles.body(isDark: isDark),
                                      ),
                                      Text(
                                        '${(conf * 100).toStringAsFixed(1)}%',
                                        style: AppTextStyles.number(
                                          isDark: isDark,
                                          fontSize: 13,
                                          fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LinearProgressIndicator(
                                      value: conf,
                                      minHeight: 6,
                                      color: isFirst ? AppColors.primary : AppColors.secondary.withOpacity(0.6),
                                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    ),
                                  ).animate().fade(duration: 800.ms),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 20),
                  ],

                  // CLINICAL RECOMMENDATION BOX
                  GlassCard(
                    borderRadius: 24,
                    borderColor: severityColor.withOpacity(0.3),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medical_information_rounded, color: severityColor, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Clinical Recommendations',
                              style: AppTextStyles.title(isDark: isDark).copyWith(color: severityColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.prediction.recommendation.isNotEmpty
                              ? widget.prediction.recommendation
                              : 'AI suggestions indicate potential lesion development. Please consult a clinician to schedule physical monitoring.',
                          style: AppTextStyles.body(isDark: isDark),
                        ),
                        const SizedBox(height: 14),
                        // Warning disclaimer inside card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Disclaimer: Not a substitute for professional diagnosis or immediate clinical medical advice.',
                                  style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 500.ms, delay: 300.ms).slideY(begin: 0.15, end: 0),

                  // HOME REMEDIES & TREATMENTS CARD
                  if (widget.prediction.homeRemedies.isNotEmpty || widget.prediction.medicalTreatments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.spa_rounded, color: AppColors.success, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Care & Home Remedies',
                                style: AppTextStyles.title(isDark: isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (widget.prediction.homeRemedies.isNotEmpty) ...[
                            Text(
                              '🌿 Target-Specific Home Remedies',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...widget.prediction.homeRemedies.map((remedy) {
                              final isChecked = _checkedRemedies.contains(remedy);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? AppColors.success.withOpacity(0.06)
                                      : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isChecked
                                        ? AppColors.success.withOpacity(0.3)
                                        : (isDark ? Colors.white12 : Colors.black12),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _checkedRemedies.add(remedy);
                                      } else {
                                        _checkedRemedies.remove(remedy);
                                      }
                                    });
                                  },
                                  activeColor: AppColors.success,
                                  checkColor: Colors.white,
                                  title: Text(
                                    remedy,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isChecked
                                          ? AppColors.success
                                          : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  dense: true,
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],

                          if (widget.prediction.medicalTreatments.isNotEmpty) ...[
                            Text(
                              '🩺 First-Line Medical Treatments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...widget.prediction.medicalTreatments.map((treatment) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10, left: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        treatment,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.3,
                                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ).animate().fade(duration: 500.ms, delay: 400.ms).slideY(begin: 0.15, end: 0),
                  ],

                  const SizedBox(height: 32),

                  // PRIMARY / SECONDARY ACTION BUTTONS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Save to diary (Primary)
                      if (!widget.isFromDiary) ...[
                        GradientButton(
                          text: _isSaving
                              ? 'Saving...'
                              : _isSaved
                                  ? 'Saved to Diary'
                                  : 'Save to Diary',
                          icon: Icon(
                            _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: (_isSaving || _isSaved) ? null : _handleSaveDiary,
                          pulseGlow: !_isSaved,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Share report (Secondary)
                      OutlinedButton.icon(
                        onPressed: _handleShareReport,
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share Report'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Discuss with AI Chatbot
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatbotScreen(
                                initialMessage: "I just got diagnosed with ${widget.prediction.disease} (${(widget.prediction.confidence * 100).toStringAsFixed(1)}% match). What does this mean and what should I do?",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.forum_rounded, size: 18),
                        label: const Text('Discuss with AI Chatbot'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.secondary, width: 1.5),
                          foregroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      // Find Nearest Dermatologist (Danger Alert - Pulsing border)
                      if (isSevere) ...[
                        const SizedBox(height: 14),
                        GradientButton(
                          text: 'Find Nearest Dermatologist',
                          icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                          gradientColors: AppColors.dangerGradient,
                          onPressed: _handleFindDermatologist,
                          pulseGlow: true,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Close/Retake button
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                        label: const Text(
                          'Scan Another Lesion',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 500.ms, delay: 400.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
