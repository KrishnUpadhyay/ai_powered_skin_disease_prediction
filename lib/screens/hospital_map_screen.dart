import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> with SingleTickerProviderStateMixin {
  bool _isDoctorFilter = true;
  int _selectedPlaceIndex = 0;
  bool _showDirections = false;
  late AnimationController _pulseController;

  final List<PlaceInfo> _doctors = [
    PlaceInfo(
      name: "Dr. Sarah Chen, MD",
      specialty: "Clinical Derm-Oncologist (Melanoma Specialist)",
      rating: 4.9,
      reviews: 142,
      distance: "0.8 km",
      duration: "3 mins drive",
      phone: "+1 (555) 382-9901",
      address: "Suite 405, Teal Medical Center",
      availableTime: "Available Today, 3:30 PM",
      coordinate: const Offset(120, 240),
    ),
    PlaceInfo(
      name: "Dr. David Miller, MD",
      specialty: "Pediatric & General Dermatologist",
      rating: 4.8,
      reviews: 98,
      distance: "1.5 km",
      duration: "6 mins drive",
      phone: "+1 (555) 890-4422",
      address: "1024 Obsidian Health Plaza",
      availableTime: "Available Tomorrow, 9:00 AM",
      coordinate: const Offset(280, 150),
    ),
    PlaceInfo(
      name: "Dr. Elena Rostova, PhD",
      specialty: "Dermatopathologist (Inflammatory Diseases)",
      rating: 4.7,
      reviews: 114,
      distance: "2.4 km",
      duration: "10 mins drive",
      phone: "+1 (555) 723-5599",
      address: "Building B, Neon Science Park",
      availableTime: "Available Today, 4:45 PM",
      coordinate: const Offset(80, 110),
    ),
  ];

  final List<PlaceInfo> _hospitals = [
    PlaceInfo(
      name: "DermaScan Memorial Hospital",
      specialty: "Grade-A Skin Diagnostics Center & ER",
      rating: 4.9,
      reviews: 580,
      distance: "1.2 km",
      duration: "5 mins drive",
      phone: "+1 (555) 911-DERM",
      address: "500 Clinical Circle Drive",
      availableTime: "ER Open 24/7",
      coordinate: const Offset(200, 280),
    ),
    PlaceInfo(
      name: "Metro Dermatology Clinic",
      specialty: "Outpatient Laser & Phototherapy Center",
      rating: 4.6,
      reviews: 210,
      distance: "3.1 km",
      duration: "12 mins drive",
      phone: "+1 (555) 234-8800",
      address: "78 Psoriasis Care Parkway",
      availableTime: "Open until 8:00 PM",
      coordinate: const Offset(310, 80),
    ),
  ];

  List<PlaceInfo> get _currentPlaces => _isDoctorFilter ? _doctors : _hospitals;
  PlaceInfo get _selectedPlace => _currentPlaces[_selectedPlaceIndex];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerCall() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Initiate Call', style: AppTextStyles.heading3(isDark: isDark)),
            ],
          ),
          content: Text(
            'Would you like to dial ${_selectedPlace.name} directly?\n\nPhone: ${_selectedPlace.phone}',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling ${_selectedPlace.phone}...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: isDark ? AppColors.background : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Clinical Locator Map',
          style: AppTextStyles.title(isDark: isDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _showDirections = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centered to your location (obsidian grid)'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🗺️ CUSTOM NEON obsidian VECTOR MAP CANVAS
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) {
                // Check if user tapped near any of the place coordinates
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                // Compensate for App bar offset roughly
                final mapPos = Offset(localPos.dx, localPos.dy - 80);
                
                for (int i = 0; i < _currentPlaces.length; i++) {
                  final place = _currentPlaces[i];
                  final distance = (place.coordinate - mapPos).distance;
                  if (distance < 30) {
                    setState(() {
                      _selectedPlaceIndex = i;
                      _showDirections = false;
                    });
                    break;
                  }
                }
              },
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _VectorMapPainter(
                        isDark: isDark,
                        places: _currentPlaces,
                        selectedIndex: _selectedPlaceIndex,
                        pulseValue: _pulseController.value,
                        drawRoute: _showDirections,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 🎛️ FILTER TABS OVERLAY
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isDoctorFilter = true;
                          _selectedPlaceIndex = 0;
                          _showDirections = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isDoctorFilter 
                              ? (isDark ? Colors.white10 : Colors.white) 
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_pin_rounded,
                              color: _isDoctorFilter ? AppColors.primary : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Find Doctors',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isDoctorFilter 
                                    ? (isDark ? Colors.white : AppColors.lightTextPrimary) 
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isDoctorFilter = false;
                          _selectedPlaceIndex = 0;
                          _showDirections = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: !_isDoctorFilter 
                              ? (isDark ? Colors.white10 : Colors.white) 
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_rounded,
                              color: !_isDoctorFilter ? AppColors.primary : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Near Hospitals',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isDoctorFilter 
                                    ? (isDark ? Colors.white : AppColors.lightTextPrimary) 
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📇 PLACES INFO SLATE (Bottom Card overlay)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Hero(
              tag: "place_${_selectedPlace.name}",
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: AppColors.heroGradient,
                            ),
                          ),
                          child: Icon(
                            _isDoctorFilter ? Icons.medical_services_rounded : Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPlace.name,
                                style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selectedPlace.specialty,
                                style: AppTextStyles.label(isDark: isDark).copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _selectedPlace.rating.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${_selectedPlace.reviews} reviews)',
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.directions_walk_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_selectedPlace.distance} (${_selectedPlace.duration})',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedPlace.address,
                            style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _selectedPlace.availableTime,
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _triggerCall,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.call_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Call Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GradientButton(
                            text: _showDirections ? 'Close Route' : 'Get Directions',
                            icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                            onPressed: () {
                              setState(() {
                                _showDirections = !_showDirections;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic).fade(),
        ],
      ),
    );
  }
}

class PlaceInfo {
  final String name;
  final String specialty;
  final double rating;
  final int reviews;
  final String distance;
  final String duration;
  final String phone;
  final String address;
  final String availableTime;
  final Offset coordinate;

  PlaceInfo({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.duration,
    required this.phone,
    required this.address,
    required this.availableTime,
    required this.coordinate,
  });
}

// 🎨 HIGH-TECH NEON obsidian MAP CUSTOM PAINTER
class _VectorMapPainter extends CustomPainter {
  final bool isDark;
  final List<PlaceInfo> places;
  final int selectedIndex;
  final double pulseValue;
  final bool drawRoute;

  _VectorMapPainter({
    required this.isDark,
    required this.places,
    required this.selectedIndex,
    required this.pulseValue,
    required this.drawRoute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)
      ..strokeWidth = 1.0;
      
    final roadPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadOverlayPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withOpacity(0.03)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 1. Draw grid lines (obsidian vector display style)
    double gridStep = 40.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw mock green/teal parks
    final parkPaint = Paint()
      ..color = isDark ? AppColors.success.withOpacity(0.05) : AppColors.success.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 40, 90, 80), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(260, 200, 110, 120), const Radius.circular(16)), parkPaint);

    // 3. Draw mock cyan water river
    final waterPaint = Paint()
      ..color = isDark ? AppColors.accent.withOpacity(0.06) : AppColors.accent.withOpacity(0.12)
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.45);
    waterPath.quadraticBezierTo(size.width * 0.4, size.height * 0.35, size.width * 0.6, size.height * 0.65);
    waterPath.quadraticBezierTo(size.width * 0.8, size.height * 0.85, size.width, size.height * 0.8);
    canvas.drawPath(waterPath, waterPaint);

    // 4. Draw roads layout
    final roadPaths = [
      Path()..moveTo(0, 180)..lineTo(size.width, 180),
      Path()..moveTo(150, 0)..lineTo(150, size.height),
      Path()..moveTo(0, 320)..lineTo(size.width, 320),
      Path()..moveTo(270, 0)..lineTo(270, size.height),
      Path()..moveTo(30, 0)..lineTo(240, size.height),
    ];

    for (var rp in roadPaths) {
      canvas.drawPath(rp, roadPaint);
      canvas.drawPath(rp, roadOverlayPaint);
    }

    // 🔬 USER PIN (Centered blue glowing node)
    final userLoc = Offset(150, 180); // intersection of main roads
    final userRingPaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.15 * (1.0 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userLoc, 15 + (18 * pulseValue), userRingPaint);
    
    final userCorePaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userLoc, 7, userCorePaint);

    final userCoreOutline = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userLoc, 7, userCoreOutline);

    // 📍 PLACES PINS (Neon teal nodes)
    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      final coordinate = place.coordinate;
      final isSelected = i == selectedIndex;

      // Draw route path if requested and selected
      if (drawRoute && isSelected) {
        final routePaint = Paint()
          ..color = AppColors.accent
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final routeOverlay = Paint()
          ..color = AppColors.accent.withOpacity(0.15)
          ..strokeWidth = 12.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final routePath = Path();
        routePath.moveTo(userLoc.dx, userLoc.dy);
        
        // Draw L-shaped road routing
        routePath.lineTo(coordinate.dx, userLoc.dy);
        routePath.lineTo(coordinate.dx, coordinate.dy);
        
        canvas.drawPath(routePath, routeOverlay);
        canvas.drawPath(routePath, routePaint);
      }

      // Pin Glow
      final pinGlow = Paint()
        ..color = (isSelected ? AppColors.accent : AppColors.primary).withOpacity(isSelected ? 0.35 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(coordinate, isSelected ? 20 + (5 * sin(pulseValue * 2 * pi)) : 14, pinGlow);

      // Pin Core
      final pinPaint = Paint()
        ..color = isSelected ? AppColors.accent : AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(coordinate, isSelected ? 8 : 6, pinPaint);

      final pinBorder = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(coordinate, isSelected ? 8 : 6, pinBorder);

      // Text label for rating or description
      if (isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: "診",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(coordinate.dx - 5, coordinate.dy - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VectorMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.drawRoute != drawRoute ||
        oldDelegate.places != places;
  }
}
