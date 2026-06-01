import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class SeverityRing extends StatefulWidget {
  final String severity; // MILD, MODERATE, SEVERE
  final double confidence; // e.g. 91.4
  final double size;

  const SeverityRing({
    super.key,
    required this.severity,
    required this.confidence,
    this.size = 180,
  });

  @override
  State<SeverityRing> createState() => _SeverityRingState();
}

class _SeverityRingState extends State<SeverityRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getSeverityColor() {
    switch (widget.severity.toUpperCase()) {
      case 'SEVERE':
        return AppColors.danger;
      case 'MODERATE':
        return AppColors.warning;
      case 'MILD':
      default:
        return AppColors.success;
    }
  }

  IconData getSeverityIcon() {
    switch (widget.severity.toUpperCase()) {
      case 'SEVERE':
        return Icons.warning_rounded;
      case 'MODERATE':
        return Icons.waves_rounded;
      case 'MILD':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = getSeverityColor();
    final severityIcon = getSeverityIcon();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: severityColor.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _SeverityRingPainter(
              progress: _animation.value,
              confidence: widget.confidence,
              color: severityColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    severityIcon,
                    color: severityColor,
                    size: 36,
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    widget.severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                    ).createShader(bounds),
                    child: Text(
                      '${widget.confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeverityRingPainter extends CustomPainter {
  final double progress;
  final double confidence;
  final Color color;

  _SeverityRingPainter({
    required this.progress,
    required this.confidence,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw animated progress track based on confidence
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (confidence / 100) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SeverityRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.confidence != confidence ||
        oldDelegate.color != color;
  }
}
