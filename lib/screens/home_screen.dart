import 'dart:convert';
import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    _fetchRecentScans();
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
                  value: '10M+',
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
                icon: Icons.medical_information_rounded,
                title: 'Conditions',
                subtitle: 'Browse 30 diseases',
                badgeColor: AppColors.accent,
                onTap: () {
                  // Simply display info
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catalog covers 30 clinical classifications: Melanoma, Basal Cell, Eczema, Psoriasis, etc.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.support_agent_rounded,
                title: 'Find Doctor',
                subtitle: 'Connect to clinic',
                badgeColor: AppColors.danger,
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Diary switches or shows alert
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Select one of your severe entries in the Skin Diary to find nearest clinics!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
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
