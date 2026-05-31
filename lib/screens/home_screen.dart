import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';
import 'diary_screen.dart';
import 'login_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Active body builder based on bottom navigation index
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const DiaryScreen();
      case 2:
        return _buildAboutTab();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Hero card with gorgeous teal gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'AI Skin Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Instantly upload or capture a skin image for deep learning-powered diagnosis and heatmaps.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Action Centers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Cards
          _buildActionCard(
            icon: Icons.camera_alt,
            title: 'Scan Skin Lesions',
            subtitle: 'Trigger camera or upload from gallery',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.calendar_month,
            title: 'Skin Diary History',
            subtitle: 'Monitor diagnostics timeline & trends',
            color: AppTheme.secondaryColor,
            onTap: () {
              setState(() {
                _selectedIndex = 1; // Switch active tab to Diary
              });
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.info_outline,
            title: 'About Diagnostics',
            subtitle: 'Read clinical details & AI architecture',
            color: AppTheme.accentColor,
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Switch to About tab
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  radius: 24,
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textDarkColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textLightColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildInfoBlock(
            title: 'Diagnostic AI Engine',
            icon: Icons.biotech,
            color: AppTheme.primaryColor,
            description: 
                'DermaScan AI leverages an advanced deep learning architecture trained on the '
                'historical HAM10000 dataset (ISIC Archive).\n\n'
                'The base feature extractor uses EfficientNetB0, pre-trained on ImageNet, fine-tuned '
                'for diagnostic precision across 7 distinct skin disease classifications.',
          ),
          const SizedBox(height: 16),
          _buildInfoBlock(
            title: 'Grad-CAM Heatmaps',
            icon: Icons.radar,
            color: AppTheme.secondaryColor,
            description: 
                'Grad-CAM (Gradient-weighted Class Activation Mapping) calculates the gradients '
                'of the classification score with respect to the final convolutional feature maps.\n\n'
                'This highlights the exact spatial pixels the neural network focused on, '
                'giving clinicians transparent explanations for each inference result.',
          ),
          const SizedBox(height: 16),
          _buildInfoBlock(
            title: 'Clinician Safety Guidelines',
            icon: Icons.verified_user,
            color: AppTheme.accentColor,
            description: 
                'This software is designed as a monitoring and diagnostic supportive reference. '
                'All estimations are strictly probabilistic.\n\n'
                'Never delay professional clinical advice or ignore medical treatments based on AI predictions.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoBlock({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppTheme.textDarkColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 
            ? 'DermaScan AI' 
            : (_selectedIndex == 1 ? 'Skin Diary' : 'About Diagnostics')),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: DermaScanApp.themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  DermaScanApp.themeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
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
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info, color: AppTheme.primaryColor),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
