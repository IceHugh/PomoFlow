import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'services/stats_service.dart';
import 'models/focus_session.dart';
import 'widgets/glass_container.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<FocusSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = StatsService().getSessions();
  }

  Map<DateTime, int> _processDailyStats(List<FocusSession> sessions) {
    final Map<DateTime, int> dailyStats = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      dailyStats[date] = 0;
    }

    for (var session in sessions) {
      final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      if (dailyStats.containsKey(date)) {
        dailyStats[date] = (dailyStats[date] ?? 0) + session.durationMinutes;
      }
    }
    return dailyStats;
  }

  int _calculateTotalMinutes(List<FocusSession> sessions) {
    return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Background Gradient (Same as SettingsPage)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode ? [
                  const Color(0xFF1a1a1a),
                  const Color(0xFF2d2d2d),
                ] : [
                  const Color(0xFFf5f5f7),
                  const Color(0xFFe5e5ea),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.back, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: '.SF Pro Display',
                          color: isDarkMode ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<FocusSession>>(
                    future: _sessionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CupertinoActivityIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No sessions yet.\nStart focusing!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        );
                      }

                      final sessions = snapshot.data!;
                      final dailyStats = _processDailyStats(sessions);
                      final totalMinutes = _calculateTotalMinutes(sessions);
                      final totalSessions = sessions.length;
                      
                      // Sort dates for chart (oldest to newest)
                      final sortedDates = dailyStats.keys.toList()..sort();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context: context,
                                  title: 'Total Focus',
                                  value: '${(totalMinutes / 60).toStringAsFixed(1)}h',
                                  icon: CupertinoIcons.time,
                                  color: CupertinoColors.systemIndigo,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  context: context,
                                  title: 'Sessions',
                                  value: '$totalSessions',
                                  icon: CupertinoIcons.checkmark_circle,
                                  color: CupertinoColors.systemGreen,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Chart Section Header
                          Text(
                            'LAST 7 DAYS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Chart Container
                          GlassContainer(
                            opacity: isDarkMode ? 0.15 : 0.05,
                            color: isDarkMode ? Colors.black : Colors.white,
                            blur: 20,
                            padding: const EdgeInsets.all(16),
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (dailyStats.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => isDarkMode ? const Color(0xFF404040) : Colors.white,
                                    tooltipPadding: const EdgeInsets.all(8),
                                    tooltipMargin: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.toInt()} min',
                                        TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value >= 0 && value < sortedDates.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              DateFormat('E').format(sortedDates[value.toInt()]),
                                              style: TextStyle(
                                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: sortedDates.asMap().entries.map((entry) {
                                  final double value = dailyStats[entry.value]?.toDouble() ?? 0;
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: value,
                                        color: isDarkMode ? const Color(0xFFAAAAAA) : Colors.black, // Monochrome bars
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: (dailyStats.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                                          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return GlassContainer(
      opacity: isDarkMode ? 0.15 : 0.05,
      color: isDarkMode ? Colors.black : Colors.white,
      blur: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: '.SF Pro Display',
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
