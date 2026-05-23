import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class MatchCreateScreen extends ConsumerStatefulWidget {
  const MatchCreateScreen({super.key});

  @override
  ConsumerState<MatchCreateScreen> createState() => _MatchCreateScreenState();
}

class _MatchCreateScreenState extends ConsumerState<MatchCreateScreen> {
  final _nameController = TextEditingController(text: 'IPL Final Simulation');
  final _venueController = TextEditingController(text: 'Wankhede Stadium');
  
  String _selectedType = 'Practice Match';
  double _oversLimit = 5.0;
  int _playersCount = 11;
  String _selectedBall = 'Leather Ball';
  String _selectedPitch = 'Turf';

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRE-MATCH SETUP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MATCH SETTINGS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.iplGold)),
                  const SizedBox(height: 20),

                  // Match Title input
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Match Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Venue input
                  TextField(
                    controller: _venueController,
                    decoration: InputDecoration(
                      labelText: 'Venue Stadium',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Match Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      labelText: 'Match Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.emoji_events),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Turf Cricket', child: Text('Turf Cricket')),
                      DropdownMenuItem(value: 'Street Cricket', child: Text('Street Cricket')),
                      DropdownMenuItem(value: 'Practice Match', child: Text('Practice Match')),
                      DropdownMenuItem(value: 'Tournament Match', child: Text('Tournament Match')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Overs slider selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Overs Limit:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_oversLimit.round()} Overs', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                    ],
                  ),
                  Slider(
                    value: _oversLimit,
                    min: 1.0,
                    max: 50.0,
                    activeColor: AppTheme.neonCyan,
                    inactiveColor: const Color(0xFF262D4A),
                    onChanged: (val) {
                      setState(() => _oversLimit = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Players count dropdown
                  DropdownButtonFormField<int>(
                    value: _playersCount,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      labelText: 'Players Per Team',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.groups),
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 Players')),
                      DropdownMenuItem(value: 6, child: Text('6 Players')),
                      DropdownMenuItem(value: 8, child: Text('8 Players')),
                      DropdownMenuItem(value: 11, child: Text('11 Players')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _playersCount = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ball Type selector
                  DropdownButtonFormField<String>(
                    value: _selectedBall,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      labelText: 'Cricket Ball Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.sports_baseball),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tennis Ball', child: Text('Tennis Ball')),
                      DropdownMenuItem(value: 'Leather Ball', child: Text('Leather Ball')),
                      DropdownMenuItem(value: 'Tape Ball', child: Text('Tape Ball')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBall = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pitch Type
                  DropdownButtonFormField<String>(
                    value: _selectedPitch,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      labelText: 'Pitch Surface',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.grass),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Turf', child: Text('Turf Grass')),
                      DropdownMenuItem(value: 'Mat', child: Text('Coir Matting')),
                      DropdownMenuItem(value: 'Concrete', child: Text('Concrete Slab')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPitch = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
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
                    ref.read(drsProvider.notifier).saveMatchConfig(
                      name: _nameController.text,
                      venue: _venueController.text,
                      type: _selectedType,
                      overs: _oversLimit.round(),
                      players: _playersCount,
                      ball: _selectedBall,
                      pitch: _selectedPitch,
                    );
                    context.push('/matches/M-001/team-setup');
                  },
                  child: const Text('PROCEED TO TEAM SETUP'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
