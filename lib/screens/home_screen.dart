import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'scan_screen.dart';
import 'diary_screen.dart';
import 'login_screen.dart';
import 'hospital_map_screen.dart';
import 'treatment_progress_screen.dart';
import 'chatbot_screen.dart';
import 'fitzpatrick_calculator_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/diary_entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<DiaryEntry> _recentScans = [];
  bool _loadingScans = false;

  // UV advisor state variables
  Map<String, dynamic>? _uvData;
  bool _loadingUv = false;
  String? _uvError;

  // Sunscreen timer state
  Timer? _sunscreenTimer;
  int _sunscreenSecondsRemaining = 0;
  int _sunscreenTotalSeconds = 0;
  bool _isSunscreenTimerRunning = false;

  // Weekly self-exam reminder state
  bool _selfExamCompletedThisWeek = false;
  String _lastSelfExamDate = "Never";

  @override
  void initState() {
    super.initState();
    _fetchRecentScans();
    _fetchUvIndex();
  }

  @override
  void dispose() {
    _sunscreenTimer?.cancel();
    super.dispose();
  }

  void _startSunscreenTimer(int minutes) {
    _sunscreenTimer?.cancel();
    setState(() {
      _sunscreenTotalSeconds = minutes * 60;
      _sunscreenSecondsRemaining = _sunscreenTotalSeconds;
      _isSunscreenTimerRunning = true;
    });

    _sunscreenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sunscreenSecondsRemaining > 0) {
        setState(() {
          _sunscreenSecondsRemaining--;
        });
      } else {
        _sunscreenTimer?.cancel();
        setState(() {
          _isSunscreenTimerRunning = false;
        });
        _showSunscreenAlert();
      }
    });
  }

  void _stopSunscreenTimer() {
    _sunscreenTimer?.cancel();
    setState(() {
      _isSunscreenTimerRunning = false;
      _sunscreenSecondsRemaining = 0;
    });
  }

  void _showSunscreenAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.alarm_on_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              "Reapply Sunscreen",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Your safe sun exposure timer has expired! Please reapply broad-spectrum sunscreen (minimum SPF 30+) to protect your skin from harmful UV damage.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSunscreenTimer(120); // Quick restart for 2 hours
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Restart (2h)", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _completeSelfExam() {
    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";
    setState(() {
      _selfExamCompletedThisWeek = true;
      _lastSelfExamDate = formattedDate;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Weekly Skin Self-Examination Logged successfully!"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatSunscreenDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchRecentScans() async {
    if (_loadingScans) return;
    setState(() {
      _loadingScans = true;
    });
    try {
      final entries = await ApiService.getDiary();
      if (mounted) {
        setState(() {
          _recentScans = entries;
          _loadingScans = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingScans = false;
        });
      }
    }
  }

  Future<void> _fetchUvIndex() async {
    if (_loadingUv) return;
    setState(() {
      _loadingUv = true;
      _uvError = null;
    });
    try {
      final data = await ApiService.getUvIndex();
      if (mounted) {
        setState(() {
          _uvData = data;
          _loadingUv = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uvError = e.toString();
          _loadingUv = false;
        });
      }
    }
  }

  void _showSymptomLogSheet(BuildContext context) {
    int itchiness = 0;
    int redness = 0;
    int waterIntake = 0;
    bool isSaving = false;
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Daily Symptom & Hydration Log",
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Log today's symptoms to track correlation between hydration and inflammation flares.",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Itchiness Selector
                    Text(
                      "Itchiness Intensity: $itchiness / 5",
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: itchiness.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      activeColor: AppColors.primary,
                      inactiveColor: isDark ? Colors.white10 : Colors.black12,
                      onChanged: (val) {
                        setSheetState(() {
                          itchiness = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Redness Selector
                    Text(
                      "Redness Intensity: $redness / 5",
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: redness.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      activeColor: AppColors.secondary,
                      inactiveColor: isDark ? Colors.white10 : Colors.black12,
                      onChanged: (val) {
                        setSheetState(() {
                          redness = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Water Intake Selector
                    Text(
                      "Water Intake: $waterIntake Glasses (250ml each)",
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: waterIntake.toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 12,
                      activeColor: AppColors.accent,
                      inactiveColor: isDark ? Colors.white10 : Colors.black12,
                      onChanged: (val) {
                        setSheetState(() {
                          waterIntake = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() {
                                isSaving = true;
                              });
                              try {
                                final success = await ApiService.saveSymptoms(
                                  itchiness,
                                  redness,
                                  waterIntake,
                                  dateStr,
                                );
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Daily log saved to SQLite database."),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: ${e.toString()}"),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              } finally {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "Save Entry",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClinicalAlarmsHud() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      borderColor: AppColors.secondary.withOpacity(0.2),
      backgroundColor: AppColors.surface.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alarm_add_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Clinical Reminders HUD",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                // Sunscreen countdown section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sunscreen Timer",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isSunscreenTimerRunning) ...[
                        Text(
                          _formatSunscreenDuration(_sunscreenSecondsRemaining),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'DMMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _stopSunscreenTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Stop", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        Text(
                          "Inactive",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _startSunscreenTimer(60),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("1 hr", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _startSunscreenTimer(120),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("2 hr", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Vertical Divider
                VerticalDivider(
                  width: 24,
                  thickness: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),

                // Weekly skin exam section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Weekly Self-Exam",
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selfExamCompletedThisWeek ? "Completed" : "Action Needed",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _selfExamCompletedThisWeek ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Last: $_lastSelfExamDate",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_selfExamCompletedThisWeek)
                        ElevatedButton(
                          onPressed: _completeSelfExam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Log Check", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selfExamCompletedThisWeek = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Reset Flag", style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
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

  // Active body builder based on selected bottom tab index
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ScanScreen(isEmbedded: true);
      case 2:
        return const DiaryScreen(isEmbedded: true);
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboard();
    }
  }

  void _showSunProtectionSheet(BuildContext context, Map<String, dynamic> uvData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: UvAdvisorSheetContent(uvData: uvData),
        );
      },
    );
  }

  Widget _buildLiveUvCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      borderColor: _uvData != null
          ? _colorFromHex(_uvData!['color_hex'] ?? '#00BFA5').withOpacity(0.3)
          : AppColors.primary.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: _uvData != null
                        ? _colorFromHex(_uvData!['color_hex'] ?? '#FFD740')
                        : Colors.orange,
                    size: 20,
                  ).animate(onPlay: (controller) => controller.repeat())
                   .rotate(duration: 12.seconds),
                  const SizedBox(width: 8),
                  Text(
                    'Real-Time UV Advisor',
                    style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 15),
                  ),
                ],
              ),
              if (_loadingUv)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _fetchUvIndex,
                  color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingUv && _uvData == null)
            const SizedBox(
              height: 70,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_uvError != null && _uvData == null)
            Column(
              children: [
                Text(
                  'Failed to fetch UV forecast details.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _fetchUvIndex,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            )
          else if (_uvData != null)
            Row(
              children: [
                Container(
                  width: 90,
                  height: 60,
                  margin: const EdgeInsets.only(right: 18),
                  child: CustomPaint(
                    painter: UvGaugePainter(
                      uvValue: (_uvData!['uv_index'] as num?)?.toDouble() ?? 0.0,
                      color: _colorFromHex(_uvData!['color_hex'] ?? '#00BFA5'),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          (_uvData!['uv_index'] ?? 0.0).toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black.withOpacity(0.85),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'UV INDEX',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _colorFromHex(_uvData!['color_hex'] ?? '#00BFA5').withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: _colorFromHex(_uvData!['color_hex'] ?? '#00BFA5'),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              (_uvData!['level'] ?? 'Low').toUpperCase(),
                              style: TextStyle(
                                color: _colorFromHex(_uvData!['color_hex'] ?? '#00BFA5'),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Time: ${_formatHourString((_uvData!['hour'] as num?)?.toDouble() ?? 12.0)}',
                            style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uvData!['description'] ?? '',
                        style: AppTextStyles.body(isDark: isDark).copyWith(fontSize: 12.5, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showSunProtectionSheet(context, _uvData!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sun Protection Guide & Timer',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatHourString(double hourDec) {
    final int hour = hourDec.floor();
    final int min = ((hourDec - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ApiService.currentUser;
    final userName = user != null ? user['name'] as String? ?? 'User' : 'User';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // HERO BANNER mesh gradient teal to violet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detect Skin Conditions\nInstantly',
                      style: AppTextStyles.heading2(isDark: true).copyWith(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI-powered analysis in under 3 seconds',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // CTA Button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1; // Switches to Scan tab
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scan Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryDark),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating 3D Bio-Scan illustration
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .slideY(begin: -0.15, end: 0.15, duration: 2.seconds, curve: Curves.easeInOut)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),

          // STATS ROW (3 cards, horizontal scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.biotech_rounded,
                  value: '103',
                  label: 'Scans Done',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  icon: Icons.verified_rounded,
                  value: '94.2%',
                  label: 'Accuracy',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  icon: Icons.flash_on_rounded,
                  value: '< 3s',
                  label: 'Speed',
                  color: AppColors.accent,
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          _buildLiveUvCard(),

          const SizedBox(height: 24),

          _buildClinicalAlarmsHud(),

          const SizedBox(height: 28),

          // QUICK ACTIONS (2x2 grid)
          Text(
            'Quick Actions',
            style: AppTextStyles.heading3(isDark: isDark),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildQuickActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Scan Skin',
                subtitle: 'Analyze mole spots',
                badgeColor: AppColors.primary,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildQuickActionCard(
                icon: Icons.book_rounded,
                title: 'Skin Diary',
                subtitle: 'View historical data',
                badgeColor: AppColors.secondary,
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              _buildQuickActionCard(
                icon: Icons.trending_up_rounded,
                title: 'Progress Log',
                subtitle: 'Track healing curves',
                badgeColor: AppColors.accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TreatmentProgressScreen()),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.map_rounded,
                title: 'Find Doctor',
                subtitle: 'Locator map & clinics',
                badgeColor: AppColors.danger,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HospitalMapScreen()),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.forum_rounded,
                title: 'AI Chatbot',
                subtitle: 'Clinical triage chatbot',
                badgeColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.wb_sunny_rounded,
                title: 'UV Advisor',
                subtitle: 'Sun safety advice',
                badgeColor: AppColors.warning,
                onTap: () {
                  if (_uvData != null) {
                    _showSunProtectionSheet(context, _uvData!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Retrieving live UV index...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _fetchUvIndex().then((_) {
                      if (_uvData != null && mounted) {
                        _showSunProtectionSheet(context, _uvData!);
                      }
                    });
                  }
                },
              ),
              _buildQuickActionCard(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Skin Quiz',
                subtitle: 'Scale UV exposure timer',
                badgeColor: AppColors.secondary,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FitzpatrickCalculatorScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchUvIndex();
                  }
                },
              ),
              _buildQuickActionCard(
                icon: Icons.opacity_rounded,
                title: 'Symptom Log',
                subtitle: 'Log daily itch & water',
                badgeColor: AppColors.primary,
                onTap: () {
                  _showSymptomLogSheet(context);
                },
              ),
            ],
          ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),

          // RECENT SCANS
          if (_recentScans.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Scans',
                  style: AppTextStyles.heading3(isDark: isDark),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recentScans.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final entry = _recentScans[index];
                  final severityColor = _getSeverityColor(entry.severity);

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 14),
                    child: InkWell(
                      onTap: () {
                        // Switch to diary or review result
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.withOpacity(0.1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: entry.imageBase64.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(entry.imageBase64),
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(Icons.image, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    entry.disease,
                                    style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 12.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(entry.confidence * 100).toStringAsFixed(0)}% match',
                                    style: AppTextStyles.number(isDark: isDark, fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severityColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: severityColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      entry.severity.toUpperCase(),
                                      style: TextStyle(
                                        color: severityColor,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
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
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        borderRadius: 20,
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        shadows: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.08),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.number(isDark: isDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.label(isDark: isDark).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: badgeColor.withOpacity(0.12),
              child: Icon(icon, color: badgeColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.bodyBold(isDark: isDark),
            ),
            Text(
              subtitle,
              style: AppTextStyles.label(isDark: isDark).copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ApiService.currentUser;
    final userName = user != null ? user['name'] as String? ?? 'User' : 'User';
    final userEmail = user != null ? user['email'] as String? ?? 'user@dermascan.ai' : 'user@dermascan.ai';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // User Card
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: AppTextStyles.heading3(isDark: isDark),
                ),
                Text(
                  userEmail,
                  style: AppTextStyles.bodyMuted(isDark: isDark),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Dermatological Analyst',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Technical Details Block
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings_suggest_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'AI Diagnostics Framework',
                      style: AppTextStyles.title(isDark: isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTechSpec(
                  title: 'Core Architecture',
                  val: 'EfficientNetB4 (Clinical weights)',
                  isDark: isDark,
                ),
                _buildTechSpec(
                  title: 'Model Resolution',
                  val: '380 x 380 px input matrix',
                  isDark: isDark,
                ),
                _buildTechSpec(
                  title: 'Grad-CAM Feature Layer',
                  val: 'Last Conv Feature Map gradients',
                  isDark: isDark,
                ),
                _buildTechSpec(
                  title: 'Database Support',
                  val: 'SQLite local diary with custom user partitions',
                  isDark: isDark,
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Theme Selector & Settings Actions
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Theme Toggle row
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: DermaScanApp.themeNotifier,
                  builder: (context, currentMode, _) {
                    final isDarkActive = currentMode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(
                        isDarkActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        'App Theme Mode',
                        style: AppTextStyles.bodyBold(isDark: isDark),
                      ),
                      subtitle: Text(
                        isDarkActive ? 'Obsidian Slate active' : 'Pure clinical light active',
                        style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                      ),
                      trailing: Switch.adaptive(
                        value: isDarkActive,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          DermaScanApp.themeNotifier.value =
                              val ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: Text(
                    'Terminate Console Session',
                    style: AppTextStyles.bodyBold(isDark: isDark).copyWith(color: AppColors.danger),
                  ),
                  subtitle: Text(
                    'Log out of clinical device partition',
                    style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                  ),
                  onTap: () {
                    ApiService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTechSpec({required String title, required String val, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyMuted(isDark: isDark)),
          Text(val, style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 13, color: AppColors.primary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ApiService.currentUser;
    final userName = user != null ? user['name'] as String? ?? 'User' : 'User';
    final userInitials = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.background, AppColors.background.withOpacity(0.8)]
                  : [AppColors.lightBackground, AppColors.lightBackground.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: User Profile Avatar Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          userInitials,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Good Morning, $userName 👋',
                            style: AppTextStyles.titleMedium(isDark: isDark),
                          ),
                          Text(
                            'Your Skin. Your Health. Powered by AI.',
                            style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: Bell icon with red dot notification badge
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new alerts. AI scanner console active and healthy.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.center_focus_strong_rounded, 'Scan'),
                _buildNavItem(2, Icons.collections_bookmark_rounded, 'Diary'),
                _buildNavItem(3, Icons.account_circle_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final picker = ImagePicker();
            final XFile? image = await picker.pickImage(
              source: ImageSource.camera,
              maxWidth: 1020,
              maxHeight: 1020,
            );
            if (image != null) {
              final bytes = await image.readAsBytes();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanScreen(
                    initialCaptureBytes: bytes,
                    initialCaptureName: image.name,
                  ),
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera capture error: $e'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: const Text(
          'Quick Scan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;

    Widget navContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textMuted : AppColors.lightTextMuted),
          size: 24,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textMuted : AppColors.lightTextMuted),
          ),
        ),
        const SizedBox(height: 2),
        // Active indicator dot sliding transitions
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 4 : 0,
          height: isSelected ? 4 : 0,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0 || index == 2) {
            _fetchRecentScans();
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: navContent,
      ),
    );
  }
}

class UvGaugePainter extends CustomPainter {
  final double uvValue;
  final Color color;

  UvGaugePainter({required this.uvValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 8;

    // Draw background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw active sweep arc (UV index maxes at 12)
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = (uvValue / 12.0).clamp(0.0, 1.0) * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant UvGaugePainter oldDelegate) {
    return oldDelegate.uvValue != uvValue || oldDelegate.color != color;
  }
}

class UvAdvisorSheetContent extends StatefulWidget {
  final Map<String, dynamic> uvData;

  const UvAdvisorSheetContent({super.key, required this.uvData});

  @override
  State<UvAdvisorSheetContent> createState() => _UvAdvisorSheetContentState();
}

class _UvAdvisorSheetContentState extends State<UvAdvisorSheetContent> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final String maxExposureText = widget.uvData['max_exposure_minutes'] ?? '30 minutes';
    double minutes = _parseMinutes(maxExposureText).toDouble();
    
    // Scale based on Fitzpatrick Skin Type if calculated
    final skinType = ApiService.fitzpatrickSkinType;
    if (skinType != null) {
      double factor = 1.0;
      switch (skinType) {
        case "Type I": factor = 0.5; break;
        case "Type II": factor = 0.7; break;
        case "Type III": factor = 1.0; break;
        case "Type IV": factor = 1.3; break;
        case "Type V": factor = 1.6; break;
        case "Type VI": factor = 2.0; break;
      }
      minutes = minutes * factor;
    }
    
    _totalSeconds = (minutes * 60).toInt();
    _remainingSeconds = _totalSeconds;
  }

  String _getFactorText(String type) {
    switch (type) {
      case "Type I": return "0.5";
      case "Type II": return "0.7";
      case "Type III": return "1.0";
      case "Type IV": return "1.3";
      case "Type V": return "1.6";
      case "Type VI": return "2.0";
      default: return "1.0";
    }
  }

  int _parseMinutes(String text) {
    if (text.contains('No restriction') || text.contains('unlimited')) {
      return 120; // 2 hours
    }
    if (text.contains('45 - 60')) return 60;
    if (text.contains('30 - 45')) return 45;
    if (text.contains('15 - 25')) return 20;
    if (text.contains('10 minutes or less')) return 10;
    return 30; // fallback
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Safe sun exposure time limit reached! Seek shade or reapply sunscreen.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  IconData _getGearIcon(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('sunglass')) return Icons.visibility_rounded;
    if (lower.contains('hat') || lower.contains('cap')) return Icons.face_retouching_natural_rounded;
    if (lower.contains('sunscreen') || lower.contains('spf')) return Icons.clean_hands_rounded;
    if (lower.contains('shirt') || lower.contains('clothing') || lower.contains('pants')) return Icons.checkroom_rounded;
    if (lower.contains('umbrella') || lower.contains('parasol')) return Icons.beach_access_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getUvColor(String? level) {
    if (level == null) return Colors.grey;
    switch (level.toUpperCase()) {
      case 'LOW':
        return const Color(0xFF2E7D32);
      case 'MODERATE':
        return const Color(0xFFFBC02D);
      case 'HIGH':
        return const Color(0xFFF57C00);
      case 'VERY HIGH':
        return const Color(0xFFD84315);
      case 'EXTREME':
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = _colorFromHex(widget.uvData['color_hex'] ?? '#00BFA5');
    final level = widget.uvData['level'] ?? 'Low';
    final uvIndex = widget.uvData['uv_index'] ?? 0.0;
    final gearList = widget.uvData['protective_gear'] as List<dynamic>? ?? [];
    final forecast = widget.uvData['hourly_forecast'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sun Safety Advisor',
                      style: AppTextStyles.heading2(isDark: isDark).copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live simulation coordinates: New Delhi',
                      style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              borderColor: themeColor.withOpacity(0.3),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColor.withOpacity(0.15),
                      border: Border.all(color: themeColor, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            uvIndex.toString(),
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'INDEX',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            level.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.uvData['description'] ?? '',
                          style: AppTextStyles.body(isDark: isDark).copyWith(fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Safe Sun Exposure Timer',
              style: AppTextStyles.heading3(isDark: isDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              borderRadius: 20,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0,
                          strokeWidth: 10,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black.withOpacity(0.85),
                              fontFamily: 'DMMono',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'REMAINING',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.0,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_isRunning ? 'Pause' : 'Start Timer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Safe Exposure Limit based on UV: ${widget.uvData['max_exposure_minutes']}',
                    style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 11),
                  ),
                  if (ApiService.fitzpatrickSkinType != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Personalized for Fitzpatrick ${ApiService.fitzpatrickSkinType} (Factor: ${_getFactorText(ApiService.fitzpatrickSkinType!)}x)',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Required Protective Gear',
              style: AppTextStyles.heading3(isDark: isDark),
            ),
            const SizedBox(height: 12),
            if (gearList.isEmpty)
              const Text('No special protective gear required.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemCount: gearList.length,
                itemBuilder: (context, index) {
                  final String gearName = gearList[index].toString();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getGearIcon(gearName),
                          color: themeColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            gearName,
                            style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 11.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            Text(
              'Hourly UV Forecast',
              style: AppTextStyles.heading3(isDark: isDark),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final fItem = forecast[index];
                  final fUv = (fItem['uv_index'] as num?)?.toDouble() ?? 0.0;
                  final fLvl = fItem['level'] ?? 'Low';
                  final fColor = _getUvColor(fLvl);

                  return Container(
                    width: 95,
                    margin: const EdgeInsets.only(right: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 16,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fItem['time'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fUv.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: fColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              fLvl,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: fColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DISCLAIMER: UV forecasts and safe exposure timers are simulated approximations based on location indices. Individual skin characteristics vary. Consult a medical professional or dermatologist for personalized sun care advice.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
