import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00BFA5);       // mint teal — health, calm
  static const Color primaryDark = Color(0xFF00897B);   // deep teal
  static const Color secondary = Color(0xFF7C4DFF);     // electric violet — AI/tech feel
  static const Color accent = Color(0xFF00E5FF);        // neon cyan — futuristic
  
  // Semantic Colors
  static const Color success = Color(0xFF69F0AE);       // mint green
  static const Color warning = Color(0xFFFFD740);       // amber
  static const Color danger = Color(0xFFFF5252);        // coral red
  static const Color dangerDark = Color(0xFFFF1744);    // red alert dark
  
  // Dark Mode System
  static const Color background = Color(0xFF0A0E1A);    // deep navy — dark mode base
  static const Color surface = Color(0xFF111827);       // dark card surface
  static const Color surfaceLight = Color(0xFF1E2A3A);  // elevated card
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);  // cool grey
  static const Color textMuted = Color(0xFF546E7A);
  
  // Light Mode System
  static const Color lightBackground = Color(0xFFF3F4F6); // modern warm grey
  static const Color lightSurface = Color(0xFFFFFFFF);    // clean white
  static const Color lightSurfaceLight = Color(0xFFE5E7EB); // subtle border/elevation grey
  static const Color lightTextPrimary = Color(0xFF111827);  // deep obsidian
  static const Color lightTextSecondary = Color(0xFF4B5563); // medium charcoal
  static const Color lightTextMuted = Color(0xFF9CA3AF);     // cool grey

  // Gradients
  static const List<Color> heroGradient = [primary, secondary];
  static const List<Color> scanGradient = [accent, primary];
  static const List<Color> dangerGradient = [danger, dangerDark];
  static const List<Color> cardShimmer = [Color(0xFF1E2A3A), Color(0xFF263547)];
  static const List<Color> lightCardShimmer = [Color(0xFFE5E7EB), Color(0xFFF3F4F6)];

  // Color tinted shadow
  static BoxShadow primaryGlow(BuildContext context) {
    return BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow secondaryGlow(BuildContext context) {
    return BoxShadow(
      color: secondary.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow accentGlow(BuildContext context) {
    return BoxShadow(
      color: accent.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }
}
