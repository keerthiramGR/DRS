import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
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

  void _triggerSampleDelivery() {
    setState(() {
      _isRecording = true;
      _frameCount = 0;
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

  @override
  Widget build(BuildContext context) {
    final drsState = ref.watch(drsProvider);

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

          // Header status panels
          SafeArea(
            child: Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
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
            ),
          ),

          // Dynamic tracking HUD
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
                
                // Capture buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Trigger Review
                    FloatingActionButton.extended(
                      heroTag: 'capture',
                      backgroundColor: _isRecording ? AppTheme.neonRed : AppTheme.accentPurple,
                      onPressed: _isRecording ? null : _triggerSampleDelivery,
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
          )
        ],
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
          // Background stadium graphic lines
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

// Painters for simulated views

class StadiumLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF262D4A).withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw cricket stumps
    final stumpWidth = size.width * 0.15;
    final stumpHeight = size.height * 0.3;
    final centerX = size.width / 2;
    final centerY = size.height * 0.65;

    // Draw three stumps
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
    
    // Draw Bails
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY - stumpHeight / 2 - 4),
        width: stumpWidth + 12,
        height: 6,
      ),
      paint,
    );

    // Crease line
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
    final startY = size.height * 0.2; // Bowler release point
    final bounceX = size.width / 2 - 15;
    final bounceY = size.height * 0.72; // Pitching point
    final impactX = size.width / 2 - 5;
    final impactY = size.height * 0.65; // Pads impact point

    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      size.width / 2 - 10,
      size.height * 0.45,
      bounceX,
      bounceY,
    );

    // Draw path up to progress
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
      
      // Impact Target overlay
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
