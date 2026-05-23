import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/drs_provider.dart';

class TossScreen extends ConsumerStatefulWidget {
  final String matchId;
  const TossScreen({super.key, required this.matchId});

  @override
  ConsumerState<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends ConsumerState<TossScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  String _selectedCall = 'Heads'; // default choice
  bool _isFlipping = false;
  bool _showWinnerChoice = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 12 * pi).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _flipCoin() {
    if (_isFlipping) return;
    
    setState(() {
      _isFlipping = true;
      _showWinnerChoice = false;
    });

    _spinController.forward(from: 0.0).then((_) {
      ref.read(drsProvider.notifier).performCoinToss(_selectedCall);
      setState(() {
        _isFlipping = false;
        _showWinnerChoice = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final drsState = ref.watch(drsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('COIN TOSS ARENA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background decoration
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF191136), AppTheme.darkBg],
                radius: 1.2,
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spin Coin display
                  AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      final angle = _spinAnimation.value;
                      final isHeads = (angle / (2 * pi)).round() % 2 == 0;
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002) // perspective
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.goldGradient,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.iplGold.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isHeads ? 'H' : 'T',
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  if (!_showWinnerChoice) ...[
                    // Call Choice selectors
                    const Text('MAKE YOUR CALL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCallButton('Heads'),
                        const SizedBox(width: 16),
                        _buildCallButton('Tails'),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Flip trigger button
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.casino),
                        label: const Text('FLIP COIN'),
                        onPressed: _flipCoin,
                      ),
                    ),
                  ],

                  if (_showWinnerChoice && drsState.tossWinner.isNotEmpty) ...[
                    // Toss outcome card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassBox(border: AppTheme.iplGold),
                      child: Column(
                        children: [
                          Icon(Icons.stars, size: 44, color: AppTheme.iplGold),
                          const SizedBox(height: 12),
                          Text(
                            '${drsState.tossWinner.toUpperCase()} WONS TOSS',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Decided to: ${drsState.tossDecision.toUpperCase() == 'BAT' ? 'BAT FIRST' : 'BOWL FIRST'}',
                            style: const TextStyle(fontSize: 14, color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF262D4A)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.sports_cricket),
                                label: const Text('START MATCH'),
                                onPressed: () {
                                  // Direct to camera review dashboard
                                  context.push('/matches/${widget.matchId}/camera');
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCallButton(String name) {
    final bool isSelected = _selectedCall == name;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.black : AppTheme.textPrimary,
        backgroundColor: isSelected ? AppTheme.iplGold : Colors.transparent,
        side: BorderSide(color: isSelected ? AppTheme.iplGold : const Color(0xFF262D4A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      onPressed: _isFlipping ? null : () => setState(() => _selectedCall = name),
      child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
