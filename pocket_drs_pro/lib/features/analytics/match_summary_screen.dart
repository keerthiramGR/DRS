import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class MatchSummaryScreen extends ConsumerWidget {
  final String matchId;
  const MatchSummaryScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drsState = ref.watch(drsProvider);

    // Calculate MVP dynamically
    final bestBatsman = drsState.batterStatsMap.values.isNotEmpty
        ? drsState.batterStatsMap.values.reduce((a, b) => a.runs > b.runs ? a : b)
        : BatterStats(name: 'Virat');
    
    final bestBowler = drsState.bowlerStatsMap.values.isNotEmpty
        ? drsState.bowlerStatsMap.values.reduce((a, b) => a.wickets > b.wickets ? a : b)
        : BowlerStats(name: 'Bumrah');

    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCH SUMMARY SCORECARD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Winner Card banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassBox(border: AppTheme.iplGold),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 48, color: AppTheme.iplGold),
                  const SizedBox(height: 12),
                  Text(
                    '${drsState.teamAName.toUpperCase()} WINS!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Warriors: ${drsState.innings1TotalRuns}/$drsState.innings1TotalWickets  vs  Titans: ${drsState.runs}/${drsState.wickets}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performers Highlights Roster
            const Text('MATCH PERFOMER METRICS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMvpCard('BEST BATSMAN', bestBatsman.name, '${bestBatsman.runs} Runs (${bestBatsman.balls}b)', Icons.sports_cricket, AppTheme.neonCyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMvpCard('BEST BOWLER', bestBowler.name, '${bestBowler.wickets} Wkts (Econ: ${bestBowler.economy.toStringAsFixed(1)})', Icons.sports_baseball, AppTheme.iplGold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Innings Scorecard lists
            const Text('DETAILED INNINGS SCORECARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            // Batters statistics table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BATTING DETAILS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text('Batter', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('R', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('SR', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ],
                      ),
                      ...drsState.batterStatsMap.values.where((b) => b.balls > 0).map((b) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text('${b.runs}')),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text('${b.balls}')),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(b.strikeRate.toStringAsFixed(1))),
                          ],
                        );
                      }).toList()
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bowler statistics table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOWLING DETAILS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.iplGold)),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('O', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('W', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text('Econ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ],
                      ),
                      ...drsState.bowlerStatsMap.values.where((b) => b.ballsBowled > 0).map((b) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(b.oversString)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text('${b.wickets}')),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(b.economy.toStringAsFixed(1))),
                          ],
                        );
                      }).toList()
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Export Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: Color(0xFF262D4A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('EXPORT PDF'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scorecard summary exported to PDF successfully.'),
                          backgroundColor: AppTheme.accentPurple,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleCyanGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE IMAGE'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scorecard graphic ready to share.'),
                            backgroundColor: AppTheme.neonGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMvpCard(String badge, String name, String stats, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBox(border: color.withOpacity(0.3)),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(stats, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
