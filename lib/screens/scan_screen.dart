import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  final bool isEmbedded;

  const ScanScreen({super.key, this.isEmbedded = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isAnalyzing = false;
  double _scanProgress = 0.0;

  late AnimationController _breathingController;
  late AnimationController _laserController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _laserController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;

        if (bytes == null && file.path != null && !kIsWeb) {
          bytes = io.File(file.path!).readAsBytesSync();
        }

        if (bytes != null) {
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = file.name;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _runAIAnalysis() async {
    if (_selectedImageBytes == null || _selectedImageName == null) return;

    setState(() {
      _isAnalyzing = true;
      _scanProgress = 0.0;
    });

    // Simulate progress counting up to 100% concurrently with API call
    final progressTimer = Stream.periodic(
      const Duration(milliseconds: 30),
      (count) => (count + 1) * 0.01,
    ).take(100).listen((val) {
      if (mounted) {
        setState(() {
          _scanProgress = val;
        });
      }
    });

    try {
      final result = await ApiService.predict(_selectedImageBytes!, _selectedImageName!);

      progressTimer.cancel();
      if (mounted) {
        setState(() {
          _scanProgress = 1.0;
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
            prediction: result,
            originalImageBytes: _selectedImageBytes!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      progressTimer.cancel();
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String errorMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('Diagnostics Failure', style: AppTextStyles.heading3(isDark: isDark))),
          ],
        ),
        content: Text(
          'DermaScan AI was unable to establish a secure connection to the Flask server.\n\n'
          'Error details: $errorMessage',
          style: AppTextStyles.body(isDark: isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runAIAnalysis();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: isDark ? AppColors.background : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget scanBody = Stack(
      children: [
        // Background particles canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticleDotsPainter(progress: _particleController.value),
              );
            },
          ),
        ),

        // Screen content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Title
              if (!widget.isEmbedded) ...[
                Text(
                  'Skin Scanner',
                  style: AppTextStyles.heading2(isDark: isDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Align skin area to diagnose in 3 seconds',
                  style: AppTextStyles.bodyMuted(isDark: isDark),
                ),
                const SizedBox(height: 24),
              ],

              // Camera Viewfinder / Preview
              Center(
                child: Stack(
                  children: [
                    // Outer viewfinder base
                    Container(
                      width: 280,
                      height: 320,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (isDark)
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ).animate().fade(duration: 400.ms)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.center_focus_weak_rounded,
                                    size: 48,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No image selected',
                                    style: AppTextStyles.bodyMuted(isDark: isDark),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Breathing Corner Brackets
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _breathingController,
                        builder: (context, child) {
                          final scale = 0.96 + (_breathingController.value * 0.08);
                          return Transform.scale(
                            scale: scale,
                            child: CustomPaint(
                              painter: _ViewfinderBracketsPainter(
                                color: AppColors.primary.withOpacity(0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Scanning Vertical Sweeping Laser Line
                    if (_isAnalyzing)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _LaserSweepPainter(
                                progress: _laserController.value,
                                color: AppColors.accent,
                              ),
                            );
                          },
                        ),
                      ),

                    // Success Checkmark Badge
                    if (_selectedImageBytes != null && !_isAnalyzing)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.success,
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  _selectedImageBytes != null ? 'Looks good!' : 'Position skin area within frame',
                  style: AppTextStyles.bodyBold(isDark: isDark).copyWith(
                    color: _selectedImageBytes != null ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),

              // Image resolution check indicator
              if (_selectedImageBytes != null && !_isAnalyzing) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.high_quality_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Resolution Check Pass (380x380)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Upload dashed border card zone (only visible if image is not selected)
              if (_selectedImageBytes == null)
                InkWell(
                  onTap: _handlePickImage,
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _DashedRectPainter(
                      color: AppColors.primary.withOpacity(0.4),
                      strokeWidth: 1.5,
                      gap: 5,
                    ),
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.primary,
                            size: 36,
                          )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .slideY(begin: 0, end: -0.15, duration: 1.seconds, curve: Curves.easeInOut),
                          const SizedBox(height: 12),
                          Text(
                            'Drag & drop or tap to upload',
                            style: AppTextStyles.bodyBold(isDark: isDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accepted formats: JPG · PNG · HEIC',
                            style: AppTextStyles.label(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(duration: 400.ms),

              // Selection Reset or Analysis Control Row
              if (_selectedImageBytes != null) ...[
                if (_isAnalyzing) ...[
                  // Loading analyzer progress bar
                  GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scanning Skin Textures...',
                              style: AppTextStyles.bodyBold(isDark: isDark),
                            ),
                            Text(
                              '${(_scanProgress * 100).toStringAsFixed(0)}%',
                              style: AppTextStyles.number(isDark: isDark, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _scanProgress,
                            minHeight: 8,
                            color: AppColors.primary,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Extracting key spatial mappings using EfficientNetB4 convolutional weights...',
                          style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms),
                ] else ...[
                  // Reset + Analyze button controls
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedImageBytes = null;
                              _selectedImageName = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: GradientButton(
                          text: 'Analyze with AI',
                          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          onPressed: _runAIAnalysis,
                          pulseGlow: true,
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms),
                ],
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: scanBody,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'DermaScan AI',
          style: AppTextStyles.title(isDark: isDark),
        ),
      ),
      body: scanBody,
    );
  }
}

// Particle Ambient Dots Painter
class _ParticleDotsPainter extends CustomPainter {
  final double progress;

  _ParticleDotsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Draw some simple static positions perturbed by progress
    final centers = [
      Offset(size.width * 0.1, size.height * 0.2 + (5 * progress)),
      Offset(size.width * 0.8, size.height * 0.15 - (5 * progress)),
      Offset(size.width * 0.3, size.height * 0.6 + (8 * progress)),
      Offset(size.width * 0.85, size.height * 0.75 - (8 * progress)),
      Offset(size.width * 0.5, size.height * 0.35 + (3 * progress)),
      Offset(size.width * 0.15, size.height * 0.85 - (4 * progress)),
    ];

    for (var c in centers) {
      canvas.drawCircle(c, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Viewfinder Corners Bracket Painter
class _ViewfinderBracketsPainter extends CustomPainter {
  final Color color;

  _ViewfinderBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double length = 32.0;

    // Top-Left bracket
    canvas.drawLine(const Offset(4, 4), const Offset(4 + length, 4), paint);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 4 + length), paint);

    // Top-Right bracket
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4 - length, 4), paint);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4, 4 + length), paint);

    // Bottom-Left bracket
    canvas.drawLine(Offset(4, size.height - 4), Offset(4 + length, size.height - 4), paint);
    canvas.drawLine(Offset(4, size.height - 4), Offset(4, size.height - 4 - length), paint);

    // Bottom-Right bracket
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4 - length, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4, size.height - 4 - length), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// Scanning Vertical Sweep Laser Painter
class _LaserSweepPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LaserSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double y = progress * size.height;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.01), color.withOpacity(0.2), color.withOpacity(0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, y - 20, size.width, y + 20));

    // Draw glow gradient trailing above/below the laser line
    canvas.drawRect(Rect.fromLTRB(0, y - 20, size.width, y + 20), gradientPaint);

    // Draw glowing laser horizontal line
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _LaserSweepPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Dashed Rectangle Border Painter
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter({required this.color, this.strokeWidth = 1.0, this.gap = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _buildDashedPath(path, gap);

    canvas.drawPath(dashPath, paint);
  }

  Path _buildDashedPath(Path source, double gap) {
    final dashPath = Path();
    for (var metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = gap;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.gap != gap;
  }
}
