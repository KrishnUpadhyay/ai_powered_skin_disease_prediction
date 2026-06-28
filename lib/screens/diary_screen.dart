import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/diary_entry.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import 'result_screen.dart';
import 'treatment_progress_screen.dart';

class DiaryScreen extends StatefulWidget {
  final bool isEmbedded;

  const DiaryScreen({super.key, this.isEmbedded = false});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _symptomLogs = [];
  bool _isLoadingSymptoms = true;
  String? _symptomError;

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries();
    _fetchSymptomLogs();
  }

  Future<void> _fetchDiaryEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await ApiService.getDiary();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSymptomLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSymptoms = true;
      _symptomError = null;
    });

    try {
      final logs = await ApiService.getSymptoms();
      if (mounted) {
        setState(() {
          _symptomLogs = logs;
          _isLoadingSymptoms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _symptomError = e.toString();
          _isLoadingSymptoms = false;
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

  double _getSeverityScore(String severity) {
    switch (severity.toUpperCase()) {
      case 'SEVERE':
      case 'HIGH':
        return 3.0;
      case 'MODERATE':
      case 'MEDIUM':
        return 2.0;
      case 'MILD':
      case 'LOW':
      case 'BENIGN':
      default:
        return 1.0;
    }
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: AppTextStyles.heading3(isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not retrieve database entries.\nError: $errorMessage',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted(isDark: isDark),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: Icon(
                Icons.zoom_in_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.5.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'No scans yet',
              style: AppTextStyles.heading3(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first scan to track your skin health over time',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatsBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_entries.isEmpty) return const SizedBox.shrink();

    final totalScans = _entries.length;
    
    final counts = <String, int>{};
    for (var e in _entries) {
      counts[e.disease] = (counts[e.disease] ?? 0) + 1;
    }
    String mostCommon = 'N/A';
    int maxCount = 0;
    counts.forEach((key, val) {
      if (val > maxCount) {
        maxCount = val;
        mostCommon = key;
      }
    });

    final lastScanDate = _entries.isEmpty 
        ? 'N/A' 
        : DateFormat('MMM dd').format(_entries.first.date);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.tag_rounded,
            label: 'Total Scans',
            value: '$totalScans',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.biotech_rounded,
            label: 'Common',
            value: mostCommon,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.calendar_today_rounded,
            label: 'Last Scan',
            value: lastScanDate,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_entries.length < 2) return const SizedBox.shrink();

    final sortedEntries = List<DiaryEntry>.from(_entries).reversed.toList();
    
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), _getSeverityScore(sortedEntries[i].severity)));
    }

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Skin Health Journey',
                style: AppTextStyles.title(isDark: isDark),
              ),
              const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Monitoring severity indexes over logging events',
            style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      getTitlesWidget: (value, meta) {
                        String txt = '';
                        if (value == 1.0) txt = 'MILD';
                        if (value == 2.0) txt = 'MODERATE';
                        if (value == 3.0) txt = 'SEVERE';
                        return Text(
                          txt,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < sortedEntries.length) {
                          final date = sortedEntries[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceLight,
          child: Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanHistoryTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _isLoading
        ? _buildShimmerSkeleton()
        : _errorMessage != null
            ? _buildErrorState(_errorMessage!, _fetchDiaryEntries)
            : _entries.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchDiaryEntries,
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _entries.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeaderStatsBar();
                        }
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            child: _buildChartSection(),
                          );
                        }

                        final entry = _entries[index - 2];
                        final severityColor = _getSeverityColor(entry.severity);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              final result = PredictionResult(
                                disease: entry.disease,
                                confidence: entry.confidence,
                                severity: entry.severity,
                                heatmapBase64: '',
                                allPredictions: [
                                  {'label': entry.disease, 'confidence': entry.confidence},
                                ],
                                recommendation: 'This is a saved diagnosis from your history diary. Recommendation defaults to localized clinic consultation. Please check your physical symptom history if changes occur.',
                                homeRemedies: entry.homeRemedies.isNotEmpty ? [entry.homeRemedies] : [],
                                medicalTreatments: const [],
                                processingLatency: 0.0,
                                cancerRiskAlert: entry.severity.toUpperCase() == 'SEVERE' || 
                                    entry.disease.contains('Melanoma') || 
                                    entry.disease.contains('Carcinoma'),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(
                                    prediction: result,
                                    originalImageBytes: base64Decode(entry.imageBase64),
                                    isFromDiary: true,
                                  ),
                                ),
                              );
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: severityColor,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: isDark ? Colors.white10 : Colors.black12,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: entry.imageBase64.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(entry.imageBase64),
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(Icons.image_rounded, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.disease,
                                          style: AppTextStyles.bodyBold(isDark: isDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy · h:mm a').format(entry.date),
                                          style: AppTextStyles.label(isDark: isDark).copyWith(fontSize: 10),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${(entry.confidence * 100).toStringAsFixed(1)}% Match',
                                          style: AppTextStyles.number(
                                            isDark: isDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ).copyWith(color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: severityColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(100),
                                          border: Border.all(color: severityColor.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          entry.severity.toUpperCase(),
                                          style: TextStyle(
                                            color: severityColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () async {
                                          final updated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TreatmentProgressScreen(initialEntry: entry),
                                            ),
                                          );
                                          if (updated == true) {
                                            _fetchDiaryEntries();
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Progress: ${entry.treatmentProgress}%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate(delay: (index * 50).ms)
                            .fade(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
                  );
  }

  Widget _buildSymptomTrendsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoadingSymptoms) {
      return _buildShimmerSkeleton();
    }
    if (_symptomError != null) {
      return _buildErrorState(_symptomError!, _fetchSymptomLogs);
    }
    if (_symptomLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.08),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 54,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No symptom records',
                style: AppTextStyles.heading3(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Use the 'Symptom Log' action on the Home screen dashboard to submit daily entries.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted(isDark: isDark),
              ),
            ],
          ),
        ),
      );
    }

    final sortedLogs = List<Map<String, dynamic>>.from(_symptomLogs);
    final recentLogs = sortedLogs.length > 7
        ? sortedLogs.sublist(sortedLogs.length - 7)
        : sortedLogs;

    final itchSpots = <FlSpot>[];
    final redSpots = <FlSpot>[];
    final waterSpots = <FlSpot>[];

    double sumItch = 0;
    double sumRed = 0;
    double sumWater = 0;

    for (int i = 0; i < recentLogs.length; i++) {
      final log = recentLogs[i];
      final itch = (log['itchiness'] as num?)?.toDouble() ?? 0.0;
      final red = (log['redness'] as num?)?.toDouble() ?? 0.0;
      final water = (log['hydration'] as num?)?.toDouble() ?? 0.0;

      sumItch += itch;
      sumRed += red;
      sumWater += water;

      itchSpots.add(FlSpot(i.toDouble(), itch));
      redSpots.add(FlSpot(i.toDouble(), red));
      waterSpots.add(FlSpot(i.toDouble(), water / 2.4));
    }

    final avgItch = sumItch / recentLogs.length;
    final avgRed = sumRed / recentLogs.length;
    final avgWater = sumWater / recentLogs.length;

    return RefreshIndicator(
      onRefresh: _fetchSymptomLogs,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStatCard(
                    title: "Avg Itch",
                    value: "${avgItch.toStringAsFixed(1)} / 5",
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryStatCard(
                    title: "Avg Redness",
                    value: "${avgRed.toStringAsFixed(1)} / 5",
                    color: AppColors.danger,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryStatCard(
                    title: "Avg Water",
                    value: "${avgWater.toStringAsFixed(1)} gl",
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Symptom Trends',
                        style: AppTextStyles.title(isDark: isDark),
                      ),
                      const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correlating hydration levels with skin redness and itching',
                    style: AppTextStyles.bodyMuted(isDark: isDark).copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < recentLogs.length) {
                                  final dateStr = recentLogs[idx]['date'] as String? ?? '';
                                  String formatted = dateStr;
                                  try {
                                    final parts = dateStr.split('-');
                                    if (parts.length == 3) {
                                      formatted = "${parts[1]}/${parts[2]}";
                                    }
                                  } catch (_) {}
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      formatted,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 5.5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: itchSpots,
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: redSpots,
                            isCurved: true,
                            color: AppColors.danger,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: waterSpots,
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem("Itching", AppColors.primary),
                      _buildLegendItem("Redness", AppColors.danger),
                      _buildLegendItem("Hydration (Scaled)", AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Clinical Advisory",
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "High water intake promotes cellular skin barrier recovery, reducing structural dryness and hypersensitive pruritus (itching) triggers. Notice how skin flares correlate to days with lower hydration values.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatCard({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: widget.isEmbedded ? Colors.transparent : (isDark ? AppColors.background : AppColors.lightBackground),
        appBar: widget.isEmbedded
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  tabs: const [
                    Tab(text: "Scan History"),
                    Tab(text: "Symptom Trends"),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                  indicatorColor: AppColors.primary,
                  dividerColor: Colors.transparent,
                ),
              )
            : AppBar(
                title: Text(
                  'DermaScan AI',
                  style: AppTextStyles.title(isDark: isDark),
                ),
                bottom: TabBar(
                  tabs: const [
                    Tab(text: "Scan History"),
                    Tab(text: "Symptom Trends"),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                  indicatorColor: AppColors.primary,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      _fetchDiaryEntries();
                      _fetchSymptomLogs();
                    },
                    tooltip: 'Reload data',
                  ),
                ],
              ),
        body: TabBarView(
          children: [
            _buildScanHistoryTab(),
            _buildSymptomTrendsTab(),
          ],
        ),
      ),
    );
  }
}
