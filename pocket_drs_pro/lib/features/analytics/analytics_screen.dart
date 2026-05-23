import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  final String matchId;
  const AnalyticsScreen({super.key, required this.matchId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCH STATS & ANALYTICS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.blur_circular), text: 'Wagon Wheel'),
            Tab(icon: Icon(Icons.grid_goldenratio), text: 'Pitch Map'),
            Tab(icon: Icon(Icons.show_chart), text: 'Speed Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWagonWheelTab(),
          _buildPitchMapTab(),
          _buildSpeedStatsTab(),
        ],
      ),
    );
  }

  // 1. Wagon Wheel UI
  Widget _buildWagonWheelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 320,
            width: double.infinity,
            decoration: AppTheme.glassBox(),
            child: CustomPaint(
              painter: WagonWheelPainter(),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendCard([
            _buildLegendItem('6 Runs', const Color(0xFFFFCC00)),
            _buildLegendItem('4 Runs', const Color(0xFF39FF14)),
            _buildLegendItem('1-3 Runs', const Color(0xFF00F0FF)),
            _buildLegendItem('Wickets', const Color(0xFFFF3131)),
          ]),
        ],
      ),
    );
  }

  // 2. Pitch Map UI
  Widget _buildPitchMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 350,
            width: double.infinity,
            decoration: AppTheme.glassBox(),
            child: CustomPaint(
              painter: PitchMapPainter(),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendCard([
            _buildLegendItem('Yorker (Red)', const Color(0xFFFF3131)),
            _buildLegendItem('Full (Orange)', const Color(0xFFFFAD60)),
            _buildLegendItem('Good (Green)', const Color(0xFF39FF14)),
            _buildLegendItem('Short (Blue)', const Color(0xFF00F0FF)),
          ]),
        ],
      ),
    );
  }

  // 3. Bowler Speed Timeline UI
  Widget _buildSpeedStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassBox(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BOWLER VELOCITY TREND (KM/H)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(1, 134),
                            FlSpot(2, 142),
                            FlSpot(3, 138),
                            FlSpot(4, 145),
                            FlSpot(5, 140),
                            FlSpot(6, 143),
                          ],
                          isCurved: true,
                          color: AppTheme.neonCyan,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassBox(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bowler Performance Insights', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.iplGold)),
                const SizedBox(height: 8),
                Text(
                  'Average release velocity has increased by 4% over the last 3 overs. Target zone analysis reveals Virat Kohli exhibits a higher defensive block index on yorkers pitching inside-line.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBox(),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: children,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Wagon Wheel Painter
class WagonWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;
    final radius = min(centerX, centerY) - 20;

    final boundaryPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw field boundary outline
    canvas.drawCircle(Offset(centerX, centerY), radius, boundaryPaint);
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.4, boundaryPaint..color = Colors.white12); // inner ring

    // Draw pitch in middle
    final pitchPaint = Paint()..color = const Color(0xFFD2B48C).withOpacity(0.5);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 10, height: 35),
      pitchPaint,
    );

    // Draw random shot vectors
    final shots = [
      {'angle': 45.0, 'dist': radius * 0.95, 'runs': 6},
      {'angle': -30.0, 'dist': radius * 0.9, 'runs': 4},
      {'angle': 120.0, 'dist': radius * 0.65, 'runs': 2},
      {'angle': 180.0, 'dist': radius * 0.88, 'runs': 4},
      {'angle': -140.0, 'dist': radius * 0.55, 'runs': 1},
      {'angle': -80.0, 'dist': radius * 0.42, 'runs': 0}, // Wicket
    ];

    for (final shot in shots) {
      final angleRad = (shot['angle'] as double) * pi / 180.0;
      final targetX = centerX + (shot['dist'] as double) * cos(angleRad);
      final targetY = centerY + (shot['dist'] as double) * sin(angleRad);

      Color strokeColor;
      if (shot['runs'] == 6) {
        strokeColor = const Color(0xFFFFCC00);
      } else if (shot['runs'] == 4) {
        strokeColor = const Color(0xFF39FF14);
      } else if (shot['runs'] == 0) {
        strokeColor = const Color(0xFFFF3131);
      } else {
        strokeColor = const Color(0xFF00F0FF);
      }

      final linePaint = Paint()
        ..color = strokeColor
        ..strokeWidth = shot['runs'] == 0 ? 1.5 : 2.5;

      canvas.drawLine(Offset(centerX, centerY), Offset(targetX, targetY), linePaint);
      canvas.drawCircle(Offset(targetX, targetY), 4, Paint()..color = strokeColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pitch Map Painter
class PitchMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()..color = const Color(0xFF13182E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw wicket outline rectangle representation
    final pitchW = size.width * 0.35;
    final pitchH = size.height * 0.8;
    final leftX = (size.width - pitchW) / 2.0;
    final topY = (size.height - pitchH) / 2.0;

    canvas.drawRect(Rect.fromLTWH(leftX, topY, pitchW, pitchH), linePaint);

    // Stumps line
    canvas.drawLine(Offset(leftX, topY + pitchH * 0.1), Offset(leftX + pitchW, topY + pitchH * 0.1), linePaint..color = Colors.white54);

    // Plot delivery bounce points (random lengths)
    final bouncePoints = [
      {'y': topY + pitchH * 0.15, 'x': leftX + pitchW * 0.48, 'color': const Color(0xFFFF3131)}, // Yorker
      {'y': topY + pitchH * 0.32, 'x': leftX + pitchW * 0.62, 'color': const Color(0xFFFFAD60)}, // Full
      {'y': topY + pitchH * 0.55, 'x': leftX + pitchW * 0.35, 'color': const Color(0xFF39FF14)}, // Good
      {'y': topY + pitchH * 0.58, 'x': leftX + pitchW * 0.55, 'color': const Color(0xFF39FF14)}, // Good
      {'y': topY + pitchH * 0.78, 'x': leftX + pitchW * 0.42, 'color': const Color(0xFF00F0FF)}, // Short
    ];

    for (final pt in bouncePoints) {
      canvas.drawCircle(
        Offset(pt['x'] as double, pt['y'] as double),
        10,
        Paint()..color = pt['color'] as Color,
      );
      canvas.drawCircle(
        Offset(pt['x'] as double, pt['y'] as double),
        10,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
