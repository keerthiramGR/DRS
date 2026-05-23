import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _roomController = TextEditingController(text: 'DRS-7700');
  String _selectedRole = 'umpire_dashboard';

  final List<Map<String, String>> _mockMatches = [
    {'id': 'M-001', 'title': 'IPL Final: MI vs CSK', 'venue': 'Wankhede Stadium', 'date': '2026-05-23'},
    {'id': 'M-002', 'title': 'Qualifier 1: RCB vs KKR', 'venue': 'M. Chinnaswamy Stadium', 'date': '2026-05-21'},
    {'id': 'M-003', 'title': 'Match 70: GT vs RR', 'venue': 'Narendra Modi Stadium', 'date': '2026-05-19'},
  ];

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drsState = ref.watch(drsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POCKET DRS DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.iplGold),
            onPressed: () => context.push('/admin'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar connection indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: drsState.isConnected 
                    ? AppTheme.neonGreen.withOpacity(0.1) 
                    : AppTheme.neonRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: drsState.isConnected ? AppTheme.neonGreen : AppTheme.neonRed,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    drsState.isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: drsState.isConnected ? AppTheme.neonGreen : AppTheme.neonRed,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    drsState.isConnected 
                        ? 'CONNECTED TO COORDINATOR SERVER (NTP Offset: ${drsState.ntpOffset}ms)'
                        : 'OFFLINE / STANDALONE SIMULATOR MODE ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: drsState.isConnected ? AppTheme.neonGreen : AppTheme.neonRed,
                    ),
                  ),
                ],
              ),
            ),

            // Telemetry highlights
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Matches Analyzed', '14', Icons.sports_cricket, AppTheme.iplGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total Balls', '524', Icons.radar, AppTheme.neonCyan),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Avg Speed', '133.4 km/h', Icons.speed, AppTheme.neonGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Decisions Checked', '38', Icons.check_circle_outline, AppTheme.accentPurple),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Device pairing configuration
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Multi-Camera Hardware Synchronization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pair multiple smartphones surrounding the stumps using Room Sync codes to link cameras and capture synchronized edge/trajectory data.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          decoration: InputDecoration(
                            labelText: 'Room Sync Code',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.sync_lock),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: AppTheme.surfaceCard,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'primary_stumps', child: Text('Primary (Stumps)')),
                          DropdownMenuItem(value: 'secondary_side', child: Text('Secondary (Side)')),
                          DropdownMenuItem(value: 'umpire_dashboard', child: Text('Dashboard Monitor')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('PAIR CAMERA ARRAYS'),
                      onPressed: () {
                        ref.read(drsProvider.notifier).joinPairingRoom(
                          _roomController.text,
                          _selectedRole,
                          'Smartphone Device #${(10 + (20 * Math.random())).round()}',
                          'M-001'
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Joined Room ${_roomController.text} as ${_selectedRole.replaceAll('_', ' ').toUpperCase()}'),
                            backgroundColor: AppTheme.accentPurple,
                          ),
                        );
                      },
                    ),
                  ),
                  if (drsState.roomMembers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2E375E)),
                    const SizedBox(height: 8),
                    const Text('Synchronized Devices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: drsState.roomMembers.map((member) {
                        final String role = member['role'] ?? '';
                        final String name = member['deviceName'] ?? '';
                        return Chip(
                          label: Text('$name ($role)'),
                          backgroundColor: AppTheme.accentPurple.withOpacity(0.3),
                          avatar: const Icon(Icons.phone_iphone, size: 14, color: AppTheme.neonCyan),
                        );
                      }).toList(),
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Speed distribution chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bowler Speed Spread (km/h)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 48, color: AppTheme.iplGold)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 185, color: AppTheme.neonCyan)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 242, color: AppTheme.accentPurple)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 49, color: AppTheme.neonGreen)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Live Match to Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('CREATE MATCH', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppTheme.accentPurple,
                  ),
                  onPressed: () => context.push('/matches/create'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockMatches.length,
              itemBuilder: (context, idx) {
                final match = _mockMatches[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentPurple.withOpacity(0.2),
                      child: const Icon(Icons.sports_cricket, color: AppTheme.neonCyan),
                    ),
                    title: Text(
                      match['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(match['venue']!),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(match['date']!),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_camera, color: AppTheme.neonCyan),
                          onPressed: () {
                            context.push('/matches/${match['id']}/camera');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.analytics, color: AppTheme.iplGold),
                          onPressed: () {
                            context.push('/matches/${match['id']}/analytics');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline, color: AppTheme.neonGreen),
                          onPressed: () {
                            context.push('/matches/${match['id']}/drs');
                          },
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
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBox(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

// Simple Math helper
class Math {
  static double random() {
    return (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;
  }
}
