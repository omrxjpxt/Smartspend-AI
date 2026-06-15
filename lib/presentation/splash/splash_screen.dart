import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    
    // Phase 3: Smooth opacity fade from 1.0 to 0.0 over 350ms
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      // Precache the logo asset before animation starts
      precacheImage(const AssetImage('assets/images/logo.png'), context).then((_) {
        _startSequence();
      });
    }
  }

  void _startSequence() async {
    // Phase 2: Hold for 700ms
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    // Phase 3: Fade out
    await _fadeController.forward();

    if (!mounted) return;

    // Phase 4: Navigate directly to app
    context.go('/home');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Extremely subtle purple ambient glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4CA6).withValues(alpha: 0.04), // Barely noticeable
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
