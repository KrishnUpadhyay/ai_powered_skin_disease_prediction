import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isAnalyzing = false;
  
  // ⚡ Animation controllers for futuristic laser scan lines
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true, // Forces bytes loading on mobile/desktop
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;

        // Fallback for mobile/desktop if bytes is null but path exists
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
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  Future<void> _runAIAnalysis() async {
    if (_selectedImageBytes == null || _selectedImageName == null) return;

    setState(() {
      _isAnalyzing = true;
    });
    
    // Start glowing laser scanner looping animation
    _scanController.repeat(reverse: true);

    try {
      // Connect directly to the Flask Backend via ApiService
      final result = await ApiService.predict(_selectedImageBytes!, _selectedImageName!);

      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
      });
      _scanController.stop();

      // Route directly to ResultScreen with analysis metadata
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            prediction: result,
            originalImageBytes: _selectedImageBytes!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      _scanController.stop();

      // Show Retry dialog or SnackBar on API error as specified
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.accentColor),
            SizedBox(width: 10),
            Text('Diagnostics Failure'),
          ],
        ),
        content: Text(
          'DermaScan AI was unable to establish a secure connection to the Flask server.\n\n'
          'Error details: $errorMessage',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textLightColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runAIAnalysis(); // Retry the API call
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Retry Connection'),
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
    final cardColor = isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Scanner'),
      ),
      body: _isAnalyzing
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🎆 Gorgeous Glowing Laser Scan Box
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Base original image
                          Positioned.fill(
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Frosted medical glass layer overlay
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.12),
                            ),
                          ),
                          
                          // Animated Glowing Laser Scan line
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimation.value * 256, // Scan from top to bottom
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.1),
                                        primaryColor,
                                        primaryColor.withOpacity(0.1),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing Skin Lesion...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mapping textures via EfficientNetB2 feature layer...',
                      style: TextStyle(color: AppTheme.textLightColor, fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Guideline Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: secondaryColor.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: secondaryColor, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Please select a clear close-up image of the skin lesion. '
                            'Ensure good lighting and focus.',
                            style: TextStyle(
                              color: AppTheme.textDarkColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Large Image Preview Box (tap to pick image)
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? primaryColor.withOpacity(0.1) : Colors.grey.shade200, 
                              width: 1.5
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handlePickImage,
                              child: _selectedImageBytes != null
                                  ? Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: primaryColor.withOpacity(0.06),
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: primaryColor,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tap to Select Image',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textDarkColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Supports JPEG, PNG file uploads',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textLightColor,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Primary Action Buttons
                  Row(
                    children: [
                      if (_selectedImageBytes != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImageBytes = null;
                                _selectedImageName = null;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor, width: 1.5),
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedImageBytes == null ? _handlePickImage : _runAIAnalysis,
                          icon: Icon(_selectedImageBytes == null ? Icons.photo_library : Icons.biotech),
                          label: Text(_selectedImageBytes == null ? 'Choose Photo' : 'Analyze with AI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}
