import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final String matchId;
  const CameraScreen({super.key, required this.matchId});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  late AnimationController _pulseController;
  
  // Real-time tracking HUD indicators
  double _ballSpeed = 0.0;
  double _lbwProb = 0.0;
  String _decision = 'UNDECIDED';
  double _confidence = 0.0;
  int _frameCount = 0;
  int _latencyMs = 8;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No physical camera devices detected. Initializing software simulation feed.');
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      print('Camera initialization error: $e. Falling back to software simulation.');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _runMockSimulation() {
    setState(() {
      _isRecording = true;
      _frameCount = 0;
      _decision = 'UNDECIDED';
      _confidence = 0.0;
      _ballSpeed = 0.0;
      _lbwProb = 0.0;
    });

    // Simulate real-time tracking progression over 2 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted || !_isRecording) return false;
      
      setState(() {
        _frameCount += 1;
        _latencyMs = 6 + Random().nextInt(5);
        if (_frameCount > 10) {
          _ballSpeed = 138.0 + Random().nextDouble() * 8.0;
        }
        if (_frameCount > 18) {
          _lbwProb = 88.0 + Random().nextDouble() * 10;
          _decision = _lbwProb > 90 ? 'OUT' : 'NOT OUT';
          _confidence = 94.0 + Random().nextDouble() * 5.0;
        }
      });
      return _frameCount < 25;
    }).then((_) {
      if (mounted) {
        setState(() => _isRecording = false);
        // Call drsProvider review simulation
        ref.read(drsProvider.notifier).triggerReview('LBW');
      }
    });
  }

  Future<void> _startRealDeliveryCapture() async {
    if (_cameraController == null || !_isCameraInitialized) {
      _runMockSimulation();
      return;
    }

    if (_cameraController!.value.isRecordingVideo) return;

    try {
      setState(() {
        _isRecording = true;
        _frameCount = 0;
        _decision = 'UNDECIDED';
        _confidence = 0.0;
        _ballSpeed = 0.0;
        _lbwProb = 0.0;
      });

      await _cameraController!.startVideoRecording();
      
      // Simulate frame countdown/meter progression during recording
      int count = 0;
      Timer.periodic(const Duration(milliseconds: 120), (timer) {
        if (!mounted || !_isRecording || count >= 25) {
          timer.cancel();
          return;
        }
        setState(() {
          _frameCount = count;
          _latencyMs = 6 + Random().nextInt(5);
          count++;
        });
      });

      // Record for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      final videoFile = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
      });

      if (!mounted) return;

      // Show uploading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Uploading video to AI server...'),
            ],
          ),
          backgroundColor: AppTheme.surfaceCard,
          duration: Duration(seconds: 2),
        ),
      );

      // Upload the video via multipart
      final uri = Uri.parse('https://drs-production-057d.up.railway.app/api/uploadFrames');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String fileUrl = data['fileUrl'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI processing trajectory & speed...'),
            backgroundColor: AppTheme.neonCyan,
            duration: Duration(seconds: 2),
          ),
        );

        // Run the DRS review with the video path!
        ref.read(drsProvider.notifier).triggerReview('LBW', videoPath: fileUrl);
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during real delivery capture: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed ($e). Using local simulation.'),
          backgroundColor: AppTheme.neonRed,
        ),
      );
      // Fallback
      ref.read(drsProvider.notifier).triggerReview('LBW');
    }
  }

  void _recordScore(int runs) {
    ref.read(drsProvider.notifier).recordDelivery(runsScored: runs);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery scored: $runs run(s)'),
        backgroundColor: runs == 4 || runs == 6 ? AppTheme.neonCyan : AppTheme.accentPurple,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _recordExtra(String type) {
    ref.read(drsProvider.notifier).recordDelivery(runsScored: 0, isExtra: true, extraType: type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery scored: ${type.toUpperCase().replaceAll('_', ' ')} (1 run extra)'),
        backgroundColor: AppTheme.iplGold,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _recordWicket() {
    ref.read(drsProvider.notifier).recordDelivery(runsScored: 0, isWicket: true, wicketType: 'caught');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WICKET! Out.'),
        backgroundColor: AppTheme.neonRed,
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drsState = ref.watch(drsProvider);

    // Compute player stats string for scorecard HUD
    final strikerStats = drsState.batterStatsMap[drsState.currentStriker];
    final strikerText = strikerStats != null 
        ? '${strikerStats.name}* ${strikerStats.runs}(${strikerStats.balls})' 
        : '${drsState.currentStriker}* 0(0)';

    final nonStrikerStats = drsState.batterStatsMap[drsState.currentNonStriker];
    final nonStrikerText = nonStrikerStats != null 
        ? '${nonStrikerStats.name} ${nonStrikerStats.runs}(${nonStrikerStats.balls})' 
        : '${drsState.currentNonStriker} 0(0)';

    final bowlerStats = drsState.bowlerStatsMap[drsState.currentBowler];
    final bowlerText = bowlerStats != null 
        ? '${bowlerStats.name} ${bowlerStats.oversString}-${bowlerStats.wickets}-${bowlerStats.runsConceded}' 
        : '${drsState.currentBowler} 0-0-0';

    // Roster calculation for selection overlays
    bool isTeamABatting = (drsState.tossWinner == drsState.teamAName && drsState.tossDecision == 'bat') ||
                          (drsState.tossWinner == drsState.teamBName && drsState.tossDecision == 'bowl');
    if (drsState.currentInnings == 2) {
      isTeamABatting = !isTeamABatting;
    }
    final battingRoster = isTeamABatting ? drsState.teamAPlayers : drsState.teamBPlayers;
    final bowlingRoster = isTeamABatting ? drsState.teamBPlayers : drsState.teamAPlayers;

    final availableBatsmen = battingRoster.where((p) => p != drsState.currentStriker && p != drsState.currentNonStriker).toList();
    final availableBowlers = bowlingRoster.where((p) => p != drsState.currentBowler).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background - Camera feed or simulation
          _isCameraInitialized && _cameraController != null
              ? SizedBox.expand(child: CameraPreview(_cameraController!))
              : _buildSimulatedStadiumFeed(),

          // Vector graphics overlay (CustomPainter path)
          if (_isRecording)
            Positioned.fill(
              child: CustomPaint(
                painter: BallPathHUDPainter(progress: _frameCount / 25.0),
              ),
            ),

          // Header status panels & scorecard HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      
                      // Device status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: AppTheme.glassBox(border: AppTheme.neonCyan),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.neonRed.withOpacity(_pulseController.value),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE NODE: ${drsState.activeDeviceRole.replaceAll('_', ' ').toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Scorecard HUD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: AppTheme.glassBox(border: AppTheme.neonCyan.withOpacity(0.3), radius: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${drsState.teamAName} vs ${drsState.teamBName}'.toUpperCase(),
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${drsState.runs}/${drsState.wickets}',
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${ (drsState.balls ~/ 6) }.${ drsState.balls % 6 } Ov)',
                                      style: const TextStyle(color: AppTheme.iplGold, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (drsState.currentInnings == 2)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('TARGET', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${drsState.target}',
                                    style: const TextStyle(color: AppTheme.neonGreen, fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF262D4A), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Batsmen
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strikerText,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nonStrikerText,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Bowler
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('BOWLER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  bowlerText,
                                  style: const TextStyle(color: AppTheme.iplGold, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
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

          // Dynamic tracking HUD & Manual Score Controls
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Realtime Overlay Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassBox(
                    border: _decision == 'OUT' ? AppTheme.neonRed : AppTheme.neonCyan,
                    radius: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHudMetric('Speed', '${_ballSpeed.toStringAsFixed(1)} km/h'),
                          _buildHudMetric('LBW Prob', '${_lbwProb.toStringAsFixed(0)}%'),
                          _buildHudMetric('Latency', '${_latencyMs}ms'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF262D4A)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CV DECISION', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                              Text(
                                _decision,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _decision == 'OUT' ? AppTheme.neonRed : AppTheme.neonGreen,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('CONFIDENCE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                              Text(
                                '${_confidence.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Manual Score Input
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: AppTheme.iplGold, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'MANUAL SCORE INPUT',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoringButton('0', () => _recordScore(0)),
                      _buildScoringButton('1', () => _recordScore(1)),
                      _buildScoringButton('2', () => _recordScore(2)),
                      _buildScoringButton('3', () => _recordScore(3)),
                      _buildScoringButton('4', () => _recordScore(4), isBoundary: true),
                      _buildScoringButton('6', () => _recordScore(6), isBoundary: true),
                      _buildScoringButton('Wd', () => _recordExtra('wide')),
                      _buildScoringButton('Nb', () => _recordExtra('no_ball')),
                      _buildScoringButton('Wkt', () => _recordWicket(), isWicket: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Capture buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Trigger Review
                    FloatingActionButton.extended(
                      heroTag: 'capture',
                      backgroundColor: _isRecording ? AppTheme.neonRed : AppTheme.accentPurple,
                      onPressed: _isRecording ? null : _startRealDeliveryCapture,
                      icon: Icon(_isRecording ? Icons.fiber_manual_record : Icons.radar),
                      label: Text(_isRecording ? 'TRACKING BALL...' : 'START DELIVERY CAPTURE'),
                    ),
                    
                    // Route to Review Screen
                    FloatingActionButton(
                      heroTag: 'goDrs',
                      backgroundColor: AppTheme.surfaceCard,
                      child: const Icon(Icons.play_circle_outline, color: AppTheme.iplGold, size: 28),
                      onPressed: () => context.push('/matches/${widget.matchId}/drs'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Select Next Batsman Overlay
          if (drsState.isSelectingNextBatsman)
            _buildSelectionOverlay(
              title: 'SELECT NEXT BATSMAN',
              options: availableBatsmen,
              onSelected: (player) {
                ref.read(drsProvider.notifier).selectNextBatsman(player);
              },
            ),

          // Select Next Bowler Overlay
          if (drsState.isSelectingNextBowler)
            _buildSelectionOverlay(
              title: 'SELECT NEXT BOWLER',
              options: availableBowlers,
              onSelected: (player) {
                ref.read(drsProvider.notifier).selectNextBowler(player);
              },
            ),

          // Match Completed Overlay
          if (drsState.isMatchCompleted)
            _buildMatchCompletedOverlay(drsState),
        ],
      ),
    );
  }

  Widget _buildSelectionOverlay({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassBox(border: AppTheme.iplGold, radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.iplGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Update the scorecard to continue the match',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF262D4A)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final player = options[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: const Color(0xFF262D4A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            player,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.neonCyan, size: 16),
                          onTap: () => onSelected(player),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCompletedOverlay(DrsState drsState) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassBox(border: AppTheme.neonGreen, radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.iplGold, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'MATCH COMPLETED',
                  style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getMatchResultText(drsState),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFF262D4A)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  icon: const Icon(Icons.dashboard, color: Colors.white),
                  label: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMatchResultText(DrsState state) {
    if (state.currentInnings == 1) {
      return 'Innings 1 complete: Total scored ${state.runs}/${state.wickets}';
    }
    if (state.runs >= state.target) {
      final chasingTeam = _getChasingTeamName(state);
      final wicketsLeft = (state.playersPerTeam - 1) - state.wickets;
      return '$chasingTeam won by $wicketsLeft wicket(s)!';
    } else {
      final defendingTeam = _getDefendingTeamName(state);
      final runsDifference = (state.target - 1) - state.runs;
      return '$defendingTeam won by $runsDifference run(s)!';
    }
  }

  String _getChasingTeamName(DrsState state) {
    final bool isTeamABattingFirst = (state.tossWinner == state.teamAName && state.tossDecision == 'bat') || 
                                     (state.tossWinner == state.teamBName && state.tossDecision == 'bowl');
    return isTeamABattingFirst ? state.teamBName : state.teamAName;
  }

  String _getDefendingTeamName(DrsState state) {
    final bool isTeamABattingFirst = (state.tossWinner == state.teamAName && state.tossDecision == 'bat') || 
                                     (state.tossWinner == state.teamBName && state.tossDecision == 'bowl');
    return isTeamABattingFirst ? state.teamAName : state.teamBName;
  }

  Widget _buildScoringButton(String label, VoidCallback onTap, {bool isBoundary = false, bool isWicket = false}) {
    Color btnColor = AppTheme.surfaceCard;
    Color textColor = AppTheme.textPrimary;
    Color borderColor = const Color(0xFF262D4A);

    if (isBoundary) {
      borderColor = AppTheme.neonCyan;
      textColor = AppTheme.neonCyan;
    } else if (isWicket) {
      borderColor = AppTheme.neonRed;
      textColor = AppTheme.neonRed;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: btnColor,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedStadiumFeed() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: StadiumLayoutPainter(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stadium, size: 60, color: AppTheme.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  'STUMP CAMERA FEED SIMULATION',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHudMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class StadiumLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF262D4A).withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final stumpWidth = size.width * 0.15;
    final stumpHeight = size.height * 0.3;
    final centerX = size.width / 2;
    final centerY = size.height * 0.65;

    for (var i = -1; i <= 1; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX + i * (stumpWidth / 2), centerY),
          width: 8,
          height: stumpHeight,
        ),
        paint,
      );
    }
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY - stumpHeight / 2 - 4),
        width: stumpWidth + 12,
        height: 6,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint..color = AppTheme.textSecondary.withOpacity(0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BallPathHUDPainter extends CustomPainter {
  final double progress;
  BallPathHUDPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.iplGold
      ..style = PaintingStyle.fill;

    final path = Path();
    final startX = size.width / 2;
    final startY = size.height * 0.2;
    final bounceX = size.width / 2 - 15;
    final bounceY = size.height * 0.72;
    final impactX = size.width / 2 - 5;
    final impactY = size.height * 0.65;

    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      size.width / 2 - 10,
      size.height * 0.45,
      bounceX,
      bounceY,
    );

    final path2 = Path();
    if (progress < 0.75) {
      final p = progress / 0.75;
      final currentX = startX + (bounceX - startX) * p;
      final currentY = startY + (bounceY - startY) * p;
      path2.moveTo(startX, startY);
      path2.lineTo(currentX, currentY);
      canvas.drawPath(path2, linePaint);
      canvas.drawCircle(Offset(currentX, currentY), 10, dotPaint);
    } else {
      final p = (progress - 0.75) / 0.25;
      final currentX = bounceX + (impactX - bounceX) * p;
      final currentY = bounceY + (impactY - bounceY) * p;
      
      path2.moveTo(startX, startY);
      path2.quadraticBezierTo(
        size.width / 2 - 10,
        size.height * 0.45,
        bounceX,
        bounceY,
      );
      path2.lineTo(currentX, currentY);
      canvas.drawPath(path2, linePaint);
      canvas.drawCircle(Offset(currentX, currentY), 10, dotPaint..color = AppTheme.neonRed);
      
      canvas.drawCircle(
        Offset(impactX, impactY),
        25,
        Paint()
          ..color = AppTheme.neonRed.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(impactX, impactY),
        25,
        Paint()
          ..color = AppTheme.neonRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BallPathHUDPainter oldDelegate) => oldDelegate.progress != progress;
}
