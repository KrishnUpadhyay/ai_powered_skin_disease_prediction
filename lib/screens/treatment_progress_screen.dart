import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/diary_entry.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class TreatmentProgressScreen extends StatefulWidget {
  final DiaryEntry? initialEntry;

  const TreatmentProgressScreen({super.key, this.initialEntry});

  @override
  State<TreatmentProgressScreen> createState() => _TreatmentProgressScreenState();
}

class _TreatmentProgressScreenState extends State<TreatmentProgressScreen> {
  bool _isLoading = true;
  List<DiaryEntry> _historyEntries = [];
  DiaryEntry? _beforeEntry;
  DiaryEntry? _afterEntry;
  
  double _sliderClipRatio = 0.5; // Controls the Before/After split position
  double _healingProgress = 0.0;
  final _notesController = TextEditingController();
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadDiaryHistory();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await ApiService.getDiary();
      
      if (!mounted) return;
      
      setState(() {
        _historyEntries = entries;
        
        if (_historyEntries.isNotEmpty) {
          // If we passed an initial entry, find it
          if (widget.initialEntry != null) {
            _afterEntry = widget.initialEntry;
            
            // Find the oldest scan of the same disease as "Before"
            final sameDisease = _historyEntries.where((e) => e.disease == widget.initialEntry!.disease).toList();
            if (sameDisease.length > 1) {
              // Sort by date ascending to find oldest
              sameDisease.sort((a, b) => a.date.compareTo(b.date));
              _beforeEntry = sameDisease.first;
              
              // If the initial entry happens to be the oldest, set afterEntry to the latest one
              if (_beforeEntry!.id == widget.initialEntry!.id) {
                _afterEntry = sameDisease.last;
              }
            } else {
              _beforeEntry = widget.initialEntry;
            }
          } else {
            // Default: pick the oldest and newest scans for comparison
            if (_historyEntries.length > 1) {
              _historyEntries.sort((a, b) => a.date.compareTo(b.date));
              _beforeEntry = _historyEntries.first;
              _afterEntry = _historyEntries.last;
            } else {
              _beforeEntry = _historyEntries.first;
              _afterEntry = _historyEntries.first;
            }
          }
          
          if (_afterEntry != null) {
            _healingProgress = _afterEntry!.treatmentProgress.toDouble();
            _notesController.text = _afterEntry!.treatmentNotes;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load history logs: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _saveTreatmentProgress() async {
    if (_afterEntry == null) return;
    
    setState(() {
      _isSavingProgress = true;
    });

    try {
      final updatedEntry = DiaryEntry(
        id: _afterEntry!.id,
        disease: _afterEntry!.disease,
        confidence: _afterEntry!.confidence,
        severity: _afterEntry!.severity,
        date: _afterEntry!.date,
        imageBase64: _afterEntry!.imageBase64,
        treatmentNotes: _notesController.text.trim(),
        treatmentProgress: _healingProgress.toInt(),
        homeRemedies: _afterEntry!.homeRemedies,
      );

      final success = await ApiService.saveDiary(updatedEntry);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Treatment logs updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDiaryHistory();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update progress: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Treatment Progress Tracker',
          style: AppTextStyles.title(isDark: isDark),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _historyEntries.isEmpty
              ? _buildEmptyState(isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. COMPARISON SLIDER SLATE
                      if (_beforeEntry != null && _afterEntry != null) ...[
                        Text(
                          'Visual Healing Comparison',
                          style: AppTextStyles.heading3(isDark: isDark),
                        ),
                        const SizedBox(height: 12),
                        _buildBeforeAfterSlider(isDark),
                        const SizedBox(height: 24),
                      ],

                      // 2. PROGRESS CONTROLLERS
                      GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Healing Progress',
                                      style: AppTextStyles.bodyBold(isDark: isDark),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_healingProgress.toInt()}% Healed',
                                  style: AppTextStyles.number(
                                    isDark: isDark, 
                                    fontWeight: FontWeight.bold,
                                  ).copyWith(color: AppColors.primary, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withOpacity(0.12),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: _healingProgress,
                                min: 0.0,
                                max: 100.0,
                                divisions: 20,
                                label: '${_healingProgress.toInt()}%',
                                onChanged: (val) {
                                  setState(() {
                                    _healingProgress = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. CLINICAL LOGS & NOTES
                      GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Clinical Progress Log',
                                  style: AppTextStyles.bodyBold(isDark: isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _notesController,
                              maxLines: 4,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                              decoration: InputDecoration(
                                hintText: 'Log your symptoms, treatment application (e.g. daily cream), or doctor advice details here...',
                                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.01),
                                filled: true,
                              ),
                            ),
                            if (_afterEntry != null && _afterEntry!.homeRemedies.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Applied Remedies Checklist:',
                                style: AppTextStyles.label(isDark: isDark),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                                child: Text(
                                  _afterEntry!.homeRemedies,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            GradientButton(
                              text: 'Save Treatment Progress',
                              isLoading: _isSavingProgress,
                              onPressed: _saveTreatmentProgress,
                              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'No diagnostic logs found',
              style: AppTextStyles.title(isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by capturing a skin scan. Once saved to your Skin Diary, you can log healing progress longitudinally.',
              style: AppTextStyles.bodyMuted(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ↔️ SIDE-BY-SIDE BEFORE/AFTER SLIDER WIDGET
  Widget _buildBeforeAfterSlider(bool isDark) {
    // Decode base64 image bytes safely
    Uint8List beforeBytes;
    Uint8List afterBytes;
    
    try {
      beforeBytes = const Base64Decoder().convert(_beforeEntry!.imageBase64);
    } catch (e) {
      beforeBytes = Uint8List(0); // fallback
    }

    try {
      afterBytes = const Base64Decoder().convert(_afterEntry!.imageBase64);
    } catch (e) {
      afterBytes = Uint8List(0);
    }

    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: isDark ? Colors.black26 : Colors.black12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              
              return GestureDetector(
                onPanUpdate: (details) {
                  final localPos = details.localPosition;
                  setState(() {
                    _sliderClipRatio = (localPos.dx / width).clamp(0.0, 1.0);
                  });
                },
                child: Stack(
                  children: [
                    // Right image: "After / Current Scan" (background layer)
                    Positioned.fill(
                      child: afterBytes.isNotEmpty
                          ? Image.memory(afterBytes, fit: ioFitCover(beforeBytes.isEmpty))
                          : Container(color: AppColors.secondary.withOpacity(0.1)),
                    ),
                    
                    // Left image: "Before / Initial Scan" (clipped overlay layer)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _BeforeAfterClipper(_sliderClipRatio),
                        child: beforeBytes.isNotEmpty
                            ? Image.memory(beforeBytes, fit: BoxFit.cover)
                            : Container(color: AppColors.primary.withOpacity(0.1)),
                      ),
                    ),
                    
                    // Vertical divider bar with slider arrows
                    Positioned(
                      left: (width * _sliderClipRatio) - 2,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        color: Colors.white,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // "Before" label badge (Left top)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Before',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    // "After / Current" label badge (Right top)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Cover Fit mode helper
  BoxFit ioFitCover(bool isFallback) => isFallback ? BoxFit.contain : BoxFit.cover;
}

// ✂️ CUSTOM CLIPPING PATH FOR COMPARISON SLIDER EFFECT
class _BeforeAfterClipper extends CustomClipper<Rect> {
  final double clipRatio;

  _BeforeAfterClipper(this.clipRatio);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * clipRatio, size.height);
  }

  @override
  bool shouldReclip(covariant _BeforeAfterClipper oldClipper) {
    return oldClipper.clipRatio != clipRatio;
  }
}
