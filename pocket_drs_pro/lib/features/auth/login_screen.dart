import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final TextEditingController _emailController = TextEditingController(text: 'umpire@ipl.drs.com');
  final TextEditingController _passwordController = TextEditingController(text: 'umpire123');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient decoration
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.4, -0.6),
                radius: 1.5,
                colors: [
                  Color(0xFF1F1135),
                  AppTheme.darkBg,
                ],
              ),
            ),
          ),
          // Subtle accent circles
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentPurple.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withOpacity(0.12),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo icon representation
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleCyanGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.radar,
                          size: 44,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'POCKET DRS PRO',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'IPL-STYLE AI UMPIRE SYSTEM',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.iplGold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Glass card for login form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassBox(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Email field
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Umpire Email',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                floatingLabelStyle: const TextStyle(color: AppTheme.neonCyan),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppTheme.neonCyan),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Access Password',
                                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                floatingLabelStyle: const TextStyle(color: AppTheme.neonCyan),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppTheme.neonCyan),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Log In button
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
                                    context.go('/dashboard');
                                  },
                                  child: const Text('AUTHENTICATE'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: AppTheme.textPrimary),
                        label: const Text('Sign in with Google Admin auth'),
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
