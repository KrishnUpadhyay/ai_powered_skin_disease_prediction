import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Cell ripple background effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CellRipplePainter(progress: _rippleController.value),
                );
              },
            ),
          ),

          // Central content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo gradient circular badge with Medical Shield + AI spark
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppColors.heroGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      Positioned(
                        top: 28,
                        right: 28,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: AppColors.accent,
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.2, 1.2), duration: 1.seconds)
                            .rotate(begin: 0, end: 0.1, duration: 1.seconds),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .shimmer(delay: 800.ms, duration: 1500.ms, colors: [Colors.transparent, Colors.white30, Colors.transparent]),

                const SizedBox(height: 32),

                // App Name
                Text(
                  'DermaScan AI',
                  style: AppTextStyles.heading1(isDark: true),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.3, end: 0, duration: 500.ms),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Your Skin. Your Health. Powered by AI.',
                  style: AppTextStyles.body(isDark: true).copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
              ],
            ),
          ),

          // Progress Dots at the bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return _buildDot(index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.3, 1.3),
          duration: 600.ms,
          delay: (index * 200).ms,
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.4,
          end: 1.0,
          duration: 600.ms,
          delay: (index * 200).ms,
          curve: Curves.easeInOut,
        );
  }
}

class _CellRipplePainter extends CustomPainter {
  final double progress;

  _CellRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;

    for (int i = 0; i < 3; i++) {
      final currentProgress = (progress + i / 3) % 1.0;
      final radius = maxRadius * currentProgress;
      final opacity = (1.0 - currentProgress) * 0.08;

      final paint = Paint()
        ..color = AppColors.primary.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CellRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
