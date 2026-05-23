import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class TeamSetupScreen extends ConsumerStatefulWidget {
  final String matchId;
  const TeamSetupScreen({super.key, required this.matchId});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  final _teamAController = TextEditingController(text: 'Warriors');
  final _teamBController = TextEditingController(text: 'Titans');
  final _playerAController = TextEditingController();
  final _playerBController = TextEditingController();

  List<String> _playersA = ['Rohit', 'Virat', 'Surya', 'Hardik', 'Pant', 'Jadeja', 'Bumrah', 'Shami', 'Siraj', 'Chahal', 'Arshdeep'];
  List<String> _playersB = ['Gill', 'Jaiswal', 'Rahul', 'Samson', 'Rinku', 'Dube', 'Axar', 'Rashid', 'Bhuvi', 'Natarajan', 'Mohit'];

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _playerAController.dispose();
    _playerBController.dispose();
    super.dispose();
  }

  void _addPlayerA() {
    if (_playerAController.text.isNotEmpty) {
      setState(() {
        _playersA.add(_playerAController.text);
        _playerAController.clear();
      });
    }
  }

  void _addPlayerB() {
    if (_playerBController.text.isNotEmpty) {
      setState(() {
        _playersB.add(_playerBController.text);
        _playerBController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEAM ROSTERS CONFIG'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Team A block
            _buildTeamCard(
              title: 'Team A (Home)',
              nameController: _teamAController,
              playerController: _playerAController,
              players: _playersA,
              onAdd: _addPlayerA,
              onRemove: (idx) => setState(() => _playersA.removeAt(idx)),
              accentColor: AppTheme.neonCyan,
            ),
            const SizedBox(height: 20),

            // Team B block
            _buildTeamCard(
              title: 'Team B (Away)',
              nameController: _teamBController,
              playerController: _playerBController,
              players: _playersB,
              onAdd: _addPlayerB,
              onRemove: (idx) => setState(() => _playersB.removeAt(idx)),
              accentColor: AppTheme.iplGold,
            ),
            const SizedBox(height: 24),

            // Proceed button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleCyanGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    ref.read(drsProvider.notifier).saveTeamsConfig(
                      teamA: _teamAController.text,
                      teamB: _teamBController.text,
                      playersA: _playersA,
                      playersB: _playersB,
                    );
                    context.push('/matches/${widget.matchId}/toss');
                  },
                  child: const Text('PROCEED TO COIN TOSS'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required String title,
    required TextEditingController nameController,
    required TextEditingController playerController,
    required List<String> players,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBox(border: accentColor.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 12),
          
          // Team Name Input
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Team Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Add player row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: playerController,
                  decoration: InputDecoration(
                    labelText: 'Add Player Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: accentColor),
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('Player List:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          // Wrapped chips representing roster players
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(players.length, (idx) {
              return Chip(
                label: Text(players[idx], style: const TextStyle(fontSize: 11)),
                backgroundColor: const Color(0xFF1D2447),
                deleteIcon: const Icon(Icons.close, size: 12, color: Colors.red),
                onDeleted: () => onRemove(idx),
              );
            }),
          )
        ],
      ),
    );
  }
}
