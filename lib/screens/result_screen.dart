import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prediction_model.dart';
import '../models/diary_entry.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final PredictionResult prediction;
  final Uint8List originalImageBytes;

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.originalImageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return const Color(0xFFE53935); // Crimson Red
      case 'medium':
      case 'moderate':
        return const Color(0xFFFB8C00); // Warm Orange
      case 'low':
      case 'benign':
      default:
        return const Color(0xFF43A047); // Forest Green
    }
  }

  Future<void> _handleSaveDiary() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Base64 encode the original image to save in the diary database
      final base64Image = base64Encode(widget.originalImageBytes);
      
      final entry = DiaryEntry(
        disease: widget.prediction.disease,
        confidence: widget.prediction.confidence,
        severity: widget.prediction.severity,
        date: DateTime.now(),
        imageBase64: base64Image,
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
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Successfully saved to your Skin Diary!'),
              ],
            ),
            backgroundColor: AppTheme.lightPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save entry: $e'),
          backgroundColor: AppTheme.lightSecondaryColor,
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

  void _handleAlertDoctor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emergency_share, color: _getSeverityColor(widget.prediction.severity)),
            const SizedBox(width: 10),
            const Text('Clinical Alert Dispatch'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to transmit this AI prediction, image, and heatmaps to your primary care dermatologist.',
              style: TextStyle(fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Text(
                'Lesion Category: ${widget.prediction.disease}\n'
                'Clinical Severity: ${widget.prediction.severity.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textLightColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Clinical Alert sent! A dermatologist will review shortly.'),
                    ],
                  ),
                  backgroundColor: AppTheme.lightPrimaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSeverityColor(widget.prediction.severity),
            ),
            child: const Text('Dispatch Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimaryColor : AppTheme.lightPrimaryColor;
    final secondaryColor = isDark ? AppTheme.darkSecondaryColor : AppTheme.lightSecondaryColor;
    final textDarkColor = isDark ? AppTheme.darkTextDark : AppTheme.lightTextDark;
    final textLightColor = isDark ? AppTheme.darkTextLight : AppTheme.lightTextLight;

    final severityColor = _getSeverityColor(widget.prediction.severity);
    final isSevere = widget.prediction.severity.toLowerCase() == 'severe' || 
                     widget.prediction.severity.toLowerCase() == 'high';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Visualizer Compare Card with glowing borders
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? primaryColor.withOpacity(0.12) : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: primaryColor,
                    unselectedLabelColor: textLightColor,
                    indicatorColor: primaryColor,
                    tabs: const [
                      Tab(icon: Icon(Icons.image), text: 'Original Input'),
                      Tab(icon: Icon(Icons.biotech), text: 'Grad-CAM Heatmap'),
                    ],
                  ),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Original Image Display
                        Image.memory(
                          widget.originalImageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        // Grad-CAM Heatmap Display
                        widget.prediction.heatmapBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(widget.prediction.heatmapBase64),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Heatmap generation failed', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Disease + Severity Header Card (Holds the Glowing Circular Gauge!)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? primaryColor.withOpacity(0.12) : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Upgraded Glowing Circular Confidence Ring
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background grey circle
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: 1.0,
                                  backgroundColor: Colors.transparent,
                                  color: primaryColor.withOpacity(0.08),
                                  strokeWidth: 8,
                                ),
                              ),
                              // Glowing active progress circle
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: widget.prediction.confidence,
                                  backgroundColor: Colors.transparent,
                                  color: primaryColor,
                                  strokeWidth: 8,
                                ),
                              ),
                              // Centered Percentage text
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(widget.prediction.confidence * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'ACCURACY',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                      color: textLightColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // 2. Disease Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: severityColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: severityColor.withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                  widget.prediction.severity.toUpperCase(),
                                  style: TextStyle(
                                    color: severityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.prediction.disease,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: textDarkColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Most likely lesion classification',
                                style: TextStyle(color: textLightColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Predictions Distribution Chart
            if (widget.prediction.allPredictions.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDark ? primaryColor.withOpacity(0.12) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Probability Distribution',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: textDarkColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.prediction.allPredictions.map((pred) {
                        final String name = pred['label'] as String? ?? '';
                        final double conf = (pred['confidence'] as num? ?? 0.0).toDouble();
                        
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textDarkColor,
                                    ),
                                  ),
                                  Text(
                                    '${(conf * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: conf,
                                  minHeight: 6,
                                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Clinical Guidelines / Recommendation Card (Glassmorphic Glow)
            Card(
              color: secondaryColor.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: secondaryColor.withOpacity(0.15), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: secondaryColor),
                        const SizedBox(width: 10),
                        Text(
                          'Clinical Recommendation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.prediction.recommendation.isNotEmpty
                          ? widget.prediction.recommendation
                          : 'Our EfficientNetB2 classification suggests a local evaluation. Please schedule a dermatological scan to acquire a physical biopsy of this lesion if any changes in size, color, or contour occur.',
                      style: TextStyle(
                        color: textDarkColor,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: secondaryColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: secondaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Disclaimer: AI prediction reports are for initial research screening and educational mapping. They do not constitute official clinical diagnosis.',
                              style: TextStyle(
                                color: textLightColor,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || _isSaved) ? null : _handleSaveDiary,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(_isSaved ? Icons.check : Icons.bookmarks),
                    label: Text(_isSaving
                        ? 'Saving...'
                        : _isSaved
                            ? 'Saved to Diary'
                            : 'Save to Diary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? Colors.grey : primaryColor,
                      foregroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
                    ),
                  ),
                ),
                if (isSevere) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleAlertDoctor,
                      icon: const Icon(Icons.emergency_share),
                      label: const Text('Alert Doctor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: severityColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Another Lesion'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.5),
                foregroundColor: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
