import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/auth_controller.dart';

/// Animated splash screen with logo and strong intro animation.
/// Decides whether to go to login or dashboard based on the persisted auth token.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AuthController _authController;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    );

    _glowAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    );

    _animController.forward();
    _init();
  }

  Future<void> _init() async {
    // نسمح للأنيميشن أن يعمل على الأقل 1.5 ثانية مع التحقق من التوكن
    final results = await Future.wait([
      _authController.checkAuth(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    final bool isAuthenticated = results.first as bool;

    if (!mounted) return;

    if (isAuthenticated) {
      Get.offAllNamed('/dashboard');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          // خلفية متدرجة مع دوائر شفافة تعطي عمق
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF020617),
                  Color(0xFF020617),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1.2, -1.2),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.tealAccent.withOpacity(0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1.1, 1.2),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amberAccent.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // محتوى الشعار والكتابة
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final double scale = 0.4 + (_scaleAnim.value * 0.6);
                final double glow = 10 + (_glowAnim.value * 25);

                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.5),
                            blurRadius: glow,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/banr.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // نص أسفل الشعار + مؤشر تقدم بسيط
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'StockPro',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'إدارة مخزون ذكية وسهلة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF40E0D0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

