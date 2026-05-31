import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/diary_entry.dart';
import '../services/api_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries();
  }

  Future<void> _fetchDiaryEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await ApiService.getDiary();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return const Color(0xFFE53935);
      case 'medium':
      case 'moderate':
        return const Color(0xFFFB8C00);
      case 'low':
      case 'benign':
      default:
        return const Color(0xFF43A047);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.06),
              child: const Icon(
                Icons.collections_bookmark_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Skin Diary is Empty',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chronicle your dermatological diagnostics, monitor changes, and log AI classification predictions here. Scan a lesion to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to the scanning tab in home or trigger scanning
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Initiate First Scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartHeader() {
    if (_entries.length < 2) return const SizedBox.shrink();

    // Sort entries chronologically for correct graph display
    final sortedEntries = List<DiaryEntry>.from(_entries).reversed.toList();
    
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].confidence * 100));
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnostic Confidence Timeline',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppTheme.textDarkColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Longitudinal prediction score monitoring across saved scans',
              style: TextStyle(color: AppTheme.textLightColor, fontSize: 11.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 130,
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(color: AppTheme.textLightColor, fontSize: 9.5),
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
                                style: const TextStyle(color: AppTheme.textLightColor, fontSize: 9),
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
                      color: AppTheme.primaryColor,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Diary & Longitudinal Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDiaryEntries,
            tooltip: 'Reload entries',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.accentColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Connection Error',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not retrieve diary database entries.\nError: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textLightColor, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchDiaryEntries,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                )
              : _entries.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchDiaryEntries,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _entries.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildLineChartHeader();
                          }
                          
                          final entry = _entries[index - 1];
                          final severityColor = _getSeverityColor(entry.severity);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Base64 Image thumbnail
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey.shade100,
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: entry.imageBase64.isNotEmpty
                                          ? Image.memory(
                                              base64Decode(entry.imageBase64),
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.image, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // Lesion diagnostic metrics details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.disease,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppTheme.textDarkColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('yMMMd').add_jm().format(entry.date),
                                            style: const TextStyle(
                                              color: AppTheme.textLightColor,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // Confidence chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${(entry.confidence * 100).toStringAsFixed(1)}% Match',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Severity chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: severityColor.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: severityColor.withOpacity(0.2)),
                                                ),
                                                child: Text(
                                                  entry.severity.toUpperCase(),
                                                  style: TextStyle(
                                                    color: severityColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
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
    );
  }
}
