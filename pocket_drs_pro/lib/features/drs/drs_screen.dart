import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class DrsScreen extends ConsumerStatefulWidget {
  final String matchId;
  const DrsScreen({super.key, required this.matchId});

  @override
  ConsumerState<DrsScreen> createState() => _DrsScreenState();
}

class _DrsScreenState extends ConsumerState<DrsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  double _frameIndex = 40.0;
  bool _isPlayingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runSimulationPipeline(String type) {
    ref.read(drsProvider.notifier).triggerReview(type);
    setState(() {
      _isPlayingReview = true;
    });
    // Autoplay frame slider simulation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted || !_isPlayingReview) return false;
      setState(() {
        _frameIndex = (_frameIndex + 1) % 100;
      });
      return _isPlayingReview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final drsState = ref.watch(drsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DRS REVIEW ROOM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _isPlayingReview = false);
            context.pop();
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.radar), text: 'Hawk-Eye'),
            Tab(icon: Icon(Icons.audiotrack), text: 'UltraEdge'),
            Tab(icon: Icon(Icons.wb_sunny), text: 'Hot Spot'),
            Tab(icon: Icon(Icons.linear_scale), text: 'Crease Sync'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Review Pipeline trigger bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF13182E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTriggerButton('LBW', 'LBW'),
                _buildTriggerButton('UltraEdge', 'EDGE'),
                _buildTriggerButton('Run Out', 'RUNOUT'),
                _buildTriggerButton('Stumping', 'STUMPING'),
              ],
            ),
          ),

          // Main Interactive visual screen
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHawkEyePanel(drsState),
                _buildUltraEdgePanel(drsState),
                _buildHotSpotPanel(drsState),
                _buildCreasePanel(drsState),
              ],
            ),
          ),

          // Frame slider control timeline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFF13182E),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlayingReview ? Icons.pause : Icons.play_arrow, color: AppTheme.iplGold),
                  onPressed: () {
                    setState(() => _isPlayingReview = !_isPlayingReview);
                  },
                ),
                Expanded(
                  child: Slider(
                    value: _frameIndex,
                    min: 0,
                    max: 100,
                    activeColor: AppTheme.neonCyan,
                    inactiveColor: const Color(0xFF262D4A),
                    onChanged: (val) {
                      setState(() {
                        _isPlayingReview = false;
                        _frameIndex = val;
                      });
                    },
                  ),
                ),
                Text(
                  'FRAME: ${_frameIndex.round().toString().padLeft(3, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                )
              ],
            ),
          ),

          // AI Commentary / Decision outcome banner
          _buildCommentaryBanner(drsState),
        ],
      ),
    );
  }

  Widget _buildTriggerButton(String type, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1D2447),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: () => _runSimulationPipeline(type),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.neonCyan)),
    );
  }

  // 1. Hawk-Eye Panel
  Widget _buildHawkEyePanel(DrsState state) {
    final hasTrajectory = state.xCoords.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262D4A)),
              ),
              child: CustomPaint(
                painter: HawkEye3DPainter(
                  x: state.xCoords,
                  y: state.yCoords,
                  z: state.zCoords,
                  progress: _frameIndex / 100.0,
                  decision: state.lbwDecision,
                ),
              ),
            ),
          ),
          
          // LBW parameters Overlay
          if (hasTrajectory)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassBox(radius: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDecisionRow('Pitching', state.lbwPitching.replaceAll('_', ' ').toUpperCase(), _getColorForValue(state.lbwPitching)),
                    const SizedBox(height: 6),
                    _buildDecisionRow('Impact', state.lbwImpact.replaceAll('_', ' ').toUpperCase(), _getColorForValue(state.lbwImpact)),
                    const SizedBox(height: 6),
                    _buildDecisionRow('Wickets', state.lbwWickets.replaceAll('_', ' ').toUpperCase(), _getColorForValue(state.lbwWickets)),
                  ],
                ),
              ),
            ),

          // Speed Overlay
          if (hasTrajectory)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassBox(radius: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('RELEASE: ${state.releaseSpeed.toStringAsFixed(1)} kph', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('BOUNCE: ${state.pitchSpeed.toStringAsFixed(1)} kph', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.iplGold)),
                    const SizedBox(height: 4),
                    Text('IMPACT: ${state.impactSpeed.toStringAsFixed(1)} kph', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  // 2. UltraEdge Panel
  Widget _buildUltraEdgePanel(DrsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Synchronized Frame Card
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262D4A)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grayscale bats-ball graphic representation
                  CustomPaint(
                    size: Size.infinite,
                    painter: BatBallFramePainter(frameIndex: _frameIndex),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Text(
                      'STUMP MICROPHONE SYNCED FEED',
                      style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Waveform Oscilloscope view
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SNICKOMETER WAVEFORM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        'EDGE PROBABILITY: ${state.edgeProbability.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: state.edgeProbability > 50 ? AppTheme.neonRed : AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SnickoWavePainter(
                        wave: state.audioWaveform,
                        frameProgress: _frameIndex / 100.0,
                        edgeDetected: state.edgeProbability > 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 3. Hot Spot Panel
  Widget _buildHotSpotPanel(DrsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262D4A)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: HotSpotThermalPainter(frameIndex: _frameIndex),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  'HOT SPOT INFRARED THERMAL CAPTURE',
                  style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Crease sync panel (Run Out / Stumping)
  Widget _buildCreasePanel(DrsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262D4A)),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: CreaseSyncPainter(
                  frameIndex: _frameIndex,
                  decisionType: state.runoutDecision != 'not_applicable' ? 'RUNOUT' : 'STUMPING',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassBox(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VERDICT', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      state.runoutDecision != 'not_applicable' 
                          ? state.runoutDecision.toUpperCase() 
                          : state.stumpingDecision.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (state.runoutDecision == 'out' || state.stumpingDecision == 'out') ? AppTheme.neonRed : AppTheme.neonGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('CREASE THRESHOLD', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      state.runoutDecision != 'not_applicable'
                          ? '${state.runoutDistanceCm.toStringAsFixed(1)} cm'
                          : (state.stumpingFootSafe ? 'FOOT SAFE' : 'FOOT OUT'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Commentary Panel helper
  Widget _buildCommentaryBanner(DrsState state) {
    final isPlumb = state.finalDecision == 'out';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1224),
        border: Border(top: BorderSide(color: Color(0xFF262D4A), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI DECISION ENGINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: state.finalDecision == 'pending'
                      ? Colors.orange.withOpacity(0.2)
                      : isPlumb ? AppTheme.neonRed.withOpacity(0.2) : AppTheme.neonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: state.finalDecision == 'pending'
                        ? Colors.orange
                        : isPlumb ? AppTheme.neonRed : AppTheme.neonGreen,
                  ),
                ),
                child: Text(
                  state.finalDecision.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: state.finalDecision == 'pending'
                        ? Colors.orange
                        : isPlumb ? AppTheme.neonRed : AppTheme.neonGreen,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.commentary.isEmpty 
                ? 'Select a decision model (LBW, Edge, Run Out) above and slide the frame controller to trigger synchronised reviews.'
                : state.commentary,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionRow(String label, String val, Color valColor) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
        Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Color _getColorForValue(String val) {
    if (val.contains('inside') || val.contains('in_line') || val.contains('hitting')) {
      return AppTheme.neonGreen;
    }
    if (val.contains('missing') || val.contains('outside') || val.contains('not_out')) {
      return AppTheme.neonRed;
    }
    return Colors.orange;
  }
}

// DRS CUSTOM PAINTERS

class HawkEye3DPainter extends CustomPainter {
  final List<double> x;
  final List<double> y;
  final List<double> z;
  final double progress;
  final String decision;

  HawkEye3DPainter({
    required this.x,
    required this.y,
    required this.z,
    required this.progress,
    required this.decision,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F111E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pitchPaint = Paint()
      ..color = const Color(0xFF285430)
      ..style = PaintingStyle.fill;
    
    // Draw 3D-perspective pitch grid
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.85); // bottom-left
    path.lineTo(size.width * 0.9, size.height * 0.85); // bottom-right
    path.lineTo(size.width * 0.65, size.height * 0.35); // top-right
    path.lineTo(size.width * 0.35, size.height * 0.35); // top-left
    path.close();
    canvas.drawPath(path, pitchPaint);

    // Draw wicket outlines in perspective (top stumps at y=0.35)
    final stumpPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final sH = size.height * 0.18; // stump height
    final sW = size.width * 0.08;  // stump width
    final centerStumpX = size.width / 2.0;
    final topStumpY = size.height * 0.35;

    // Draw 3 vertical stumps
    canvas.drawLine(Offset(centerStumpX - sW/2, topStumpY), Offset(centerStumpX - sW/2, topStumpY - sH), stumpPaint);
    canvas.drawLine(Offset(centerStumpX, topStumpY), Offset(centerStumpX, topStumpY - sH), stumpPaint);
    canvas.drawLine(Offset(centerStumpX + sW/2, topStumpY), Offset(centerStumpX + sW/2, topStumpY - sH), stumpPaint);
    
    // Draw bails
    canvas.drawLine(Offset(centerStumpX - sW/2 - 4, topStumpY - sH), Offset(centerStumpX + sW/2 + 4, topStumpY - sH), stumpPaint..strokeWidth = 2);

    if (x.isEmpty) return;

    // Transform logic mapping tracking x,y,z into 2D canvas coordinates in perspective
    Offset transformTo2D(double rx, double ry, double rz) {
      // Y is distance down pitch (20m to 0m)
      final normY = (20.0 - ry) / 20.0; // 0 at release, 1 at stumps
      
      final screenY = size.height * 0.85 - (normY * (size.height * 0.5));
      
      // Horizontal width narrows at higher screenY (perspective)
      final scaleFactor = 1.0 - (normY * 0.35);
      final screenX = (size.width / 2.0) + (rx * size.width * 0.85 * scaleFactor);
      
      // Height (Z) maps upwards, also scaled by perspective
      final screenZ = screenY - (rz * size.height * 0.35 * scaleFactor);
      
      return Offset(screenX, screenZ);
    }

    // Paint trajectory line
    final linePaint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.iplGold
      ..style = PaintingStyle.fill;

    final pathTrace = Path();
    final totalPoints = x.length;
    final visibleCount = (totalPoints * progress).clamp(1, totalPoints).toInt();

    final pStart = transformTo2D(x[0], y[0], z[0]);
    pathTrace.moveTo(pStart.dx, pStart.dy);

    for (var i = 1; i < visibleCount; i++) {
      final p = transformTo2D(x[i], y[i], z[i]);
      pathTrace.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(pathTrace, linePaint);

    // Draw active ball dot
    if (visibleCount > 0) {
      final currentPt = transformTo2D(x[visibleCount - 1], y[visibleCount - 1], z[visibleCount - 1]);
      canvas.drawCircle(currentPt, 8, dotPaint);

      // Re-draw ground bounce point if visible
      final bounceIdx = (totalPoints * 0.75).round();
      if (visibleCount > bounceIdx) {
        final bouncePt = transformTo2D(x[bounceIdx], y[bounceIdx], z[bounceIdx]);
        canvas.drawCircle(
          bouncePt,
          16,
          Paint()
            ..color = AppTheme.iplGold.withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Project wickets path after impact (Y < 1.2m)
    if (progress > 0.85) {
      final projectionPaint = Paint()
        ..color = decision == 'out' ? AppTheme.neonRed : AppTheme.neonGreen
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      
      final projPath = Path();
      final lastTrackedPt = transformTo2D(x.last, y.last, z.last);
      projPath.moveTo(lastTrackedPt.dx, lastTrackedPt.dy);
      
      // Project to wickets plane (ry = 0.0)
      final hitX = decision == 'out' ? 0.015 : 0.18; // slide down leg if not out
      final hitZ = decision == 'out' ? 0.28 : 0.88;  // miss high if not out
      final projectedPt = transformTo2D(hitX, 0.0, hitZ);
      projPath.lineTo(projectedPt.dx, projectedPt.dy);
      
      canvas.drawPath(projPath, projectionPaint);
      
      // Projected target hit spot
      canvas.drawCircle(
        projectedPt,
        8,
        Paint()..color = decision == 'out' ? AppTheme.neonRed : AppTheme.neonGreen,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HawkEye3DPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.x.length != x.length;
  }
}

class SnickoWavePainter extends CustomPainter {
  final List<double> wave;
  final double frameProgress;
  final bool edgeDetected;

  SnickoWavePainter({
    required this.wave,
    required this.frameProgress,
    required this.edgeDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wave.isEmpty) return;

    final linePaint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2.0;
    final stepX = size.width / (wave.length - 1);

    path.moveTo(0, midY + wave[0] * size.height * 0.4);

    for (var i = 1; i < wave.length; i++) {
      path.lineTo(i * stepX, midY + wave[i] * size.height * 0.4);
    }
    canvas.drawPath(path, linePaint);

    // Sync bar representing current frame playhead
    final xPlayhead = size.width * frameProgress;
    canvas.drawLine(
      Offset(xPlayhead, 0),
      Offset(xPlayhead, size.height),
      Paint()
        ..color = AppTheme.iplGold
        ..strokeWidth = 2.0,
    );

    // If edge is detected, highlight the peak zone
    if (edgeDetected) {
      final peakX = size.width * 0.53; // index 64 out of 120
      canvas.drawCircle(
        Offset(peakX, midY),
        30,
        Paint()
          ..color = AppTheme.neonRed.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(peakX, midY),
        30,
        Paint()
          ..color = AppTheme.neonRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SnickoWavePainter oldDelegate) {
    return oldDelegate.frameProgress != frameProgress || oldDelegate.wave.length != wave.length;
  }
}

class BatBallFramePainter extends CustomPainter {
  final double frameIndex;
  BatBallFramePainter({required this.frameIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;
    
    // Draw camera scan lines for vintage digital frame look
    for (var i = 0.0; i < size.height; i += 12) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // Draw bat (angled rect)
    final batPaint = Paint()
      ..color = const Color(0xFF6B6E70)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(size.width / 2.0 - 20, size.height / 2.0);
    canvas.rotate(-0.35); // tilt bat
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, 0), width: 35, height: 160),
      batPaint,
    );
    canvas.restore();

    // Draw ball passing by
    // Ball goes from top right to bottom left
    final t = frameIndex / 100.0;
    final ballX = size.width * 0.75 - t * (size.width * 0.5);
    final ballY = size.height * 0.2 + t * (size.height * 0.6);

    canvas.drawCircle(
      Offset(ballX, ballY),
      14,
      Paint()
        ..color = const Color(0xFFBC243C)
        ..style = PaintingStyle.fill,
    );

    // Draw seam line on ball
    canvas.drawCircle(
      Offset(ballX, ballY),
      14,
      Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant BatBallFramePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex;
  }
}

class HotSpotThermalPainter extends CustomPainter {
  final double frameIndex;
  HotSpotThermalPainter({required this.frameIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Thermal screen is pure black background
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw bat silhouette as faint dark gray
    final batPaint = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2.0 - 20, size.height / 2.0);
    canvas.rotate(-0.35);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, 0), width: 45, height: 180),
      batPaint,
    );
    canvas.restore();

    // Draw ball trajectory path as thermal ghost
    final t = frameIndex / 100.0;
    final ballX = size.width * 0.75 - t * (size.width * 0.5);
    final ballY = size.height * 0.2 + t * (size.height * 0.6);

    // Ball thermal signature: dark grey circle
    canvas.drawCircle(
      Offset(ballX, ballY),
      15,
      Paint()
        ..color = const Color(0xFF222222)
        ..style = PaintingStyle.fill,
    );

    // Impact occurs around frameIndex = 53
    // At impact point, draw bright white contact heat zone
    const impactFrame = 53.0;
    if (frameIndex >= impactFrame) {
      final opacity = max(0.0, 1.0 - (frameIndex - impactFrame) / 30.0);
      final impactPt = Offset(size.width / 2.0 - 15, size.height / 2.0 + 8);
      
      // Glow rings
      canvas.drawCircle(
        impactPt,
        25 * opacity,
        Paint()
          ..color = Colors.white.withOpacity(0.2 * opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        impactPt,
        12 * opacity,
        Paint()
          ..color = Colors.white.withOpacity(0.6 * opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        impactPt,
        5 * opacity,
        Paint()
          ..color = Colors.white.withOpacity(1.0 * opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HotSpotThermalPainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex;
  }
}

class CreaseSyncPainter extends CustomPainter {
  final double frameIndex;
  final String decisionType;

  CreaseSyncPainter({required this.frameIndex, required this.decisionType});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark turf bg
    final bgPaint = Paint()..color = const Color(0xFF0F1B11);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0;

    // Draw white Crease Line
    final creaseY = size.height * 0.65;
    canvas.drawLine(Offset(0, creaseY), Offset(size.width, creaseY), paint);

    // Batsman crease label
    const textStyle = TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1);
    final textPainter = TextPainter(
      text: const TextSpan(text: 'CREASE LINE', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(20, creaseY + 8));

    // Player details
    final t = frameIndex / 100.0;
    
    if (decisionType == 'RUNOUT') {
      // Draw batsman sliding bat
      // Y position moves down towards crease line
      final batTipY = size.height * 0.85 - t * (size.height * 0.25);
      
      // Draw bat box
      final batPaint = Paint()
        ..color = const Color(0xFF8B5A2B)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromPoints(Offset(size.width / 2 - 10, batTipY), Offset(size.width / 2 + 10, batTipY + 90)),
        batPaint,
      );

      // Bails fly at frame = 42
      final bailsBroken = frameIndex >= 42;
      _drawStumps(canvas, size, bailsBroken);

      // Draw bounding box label
      final boxColor = batTipY < creaseY ? AppTheme.neonGreen : AppTheme.neonRed;
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2 - 20, batTipY - 5, 40, 100),
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      // Stumping - draw backfoot
      // foot Y moves back and forth slightly
      final footY = size.height * 0.72 - sin(t * pi) * 0.12 * size.height;

      // Draw foot outline
      final footPaint = Paint()
        ..color = const Color(0xFFE2E2E2)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width / 2, footY), width: 30, height: 75),
        footPaint,
      );

      final bailsBroken = frameIndex >= 38;
      _drawStumps(canvas, size, bailsBroken);

      final boxColor = footY <= creaseY ? AppTheme.neonGreen : AppTheme.neonRed;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(size.width / 2, footY), width: 40, height: 90),
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawStumps(Canvas canvas, Size size, bool bailsBroken) {
    final centerX = size.width / 2.0;
    final creaseY = size.height * 0.65;
    
    // Draw stumps in top-center
    final stumpPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 4.0;

    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(centerX + i * 18, creaseY - 100),
        Offset(centerX + i * 18, creaseY - 20),
        stumpPaint,
      );
    }

    // Bails dislodge animation
    if (bailsBroken) {
      canvas.drawLine(
        Offset(centerX - 35, creaseY - 115),
        Offset(centerX - 5, creaseY - 130),
        stumpPaint..color = AppTheme.neonRed..strokeWidth = 3,
      );
      canvas.drawLine(
        Offset(centerX + 5, creaseY - 125),
        Offset(centerX + 35, creaseY - 110),
        stumpPaint..color = AppTheme.neonRed..strokeWidth = 3,
      );
    } else {
      canvas.drawLine(
        Offset(centerX - 24, creaseY - 104),
        Offset(centerX + 24, creaseY - 104),
        stumpPaint..color = Colors.orange..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CreaseSyncPainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex || oldDelegate.decisionType != decisionType;
  }
}
