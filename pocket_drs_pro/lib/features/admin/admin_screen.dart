import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Configurable thresholds variables
  double _stumpHeight = 0.72; // standard stump height (meters)
  double _stumpWidth = 0.23;  // standard stump width (meters)
  double _audioSnickThreshold = 1.4; // signal energy ratio threshold
  double _autoDecisionConfidence = 92.0; // confidence % threshold

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN CALIBRATION SYSTEM'),
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
            // Warning header about calibration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.iplGold.withOpacity(0.1),
                border: Border.all(color: AppTheme.iplGold),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.iplGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'CALIBRATION SETTINGS IMPACT THE YOLOv8 AND FFT DETECTION MODULATOR. ENSURE ACCURATE TAPE MEASUREMENTS BEFORE SAVING.',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.iplGold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stumps calibration card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stump Dimensions (Calibration)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildSlider('Stump Height (meters)', _stumpHeight, 0.6, 0.9, (val) {
                    setState(() => _stumpHeight = val);
                  }),
                  _buildSlider('Stump Width (meters)', _stumpWidth, 0.15, 0.35, (val) {
                    setState(() => _stumpWidth = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // UltraEdge calibration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Snickometer Audio Sensitivity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildSlider('FFT Peak Energy Ratio', _audioSnickThreshold, 1.0, 3.0, (val) {
                    setState(() => _audioSnickThreshold = val);
                  }),
                  const Text(
                    'Higher values require a louder woodwork click vs ambient noise (e.g. gloves/pads) to trigger a peak.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI confidence parameters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Auto-Decision Thresholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildSlider('Confidence Bar (%)', _autoDecisionConfidence, 80.0, 99.0, (val) {
                    setState(() => _autoDecisionConfidence = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Save buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: Color(0xFF262D4A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleCyanGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calibration metrics saved and deployed to AI Core.'),
                            backgroundColor: AppTheme.neonGreen,
                          ),
                        );
                        context.pop();
                      },
                      child: const Text('APPLY SETTINGS'),
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

  Widget _buildSlider(String title, double val, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
          ],
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          activeColor: AppTheme.neonCyan,
          inactiveColor: const Color(0xFF262D4A),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
