import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.loginBackground,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background Patterns (في الزوايا العلوية)
              _buildTopCornerPatterns(),
              // Gold curved line separator
              _buildGoldSeparator(),
              // Main Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Logo Circle (Container واحد مع صورة مخفية مغطاة بلون)
                      _buildLogoCircle(),
                      const SizedBox(height: 50),
                      // Title
                      _buildTitle(),
                      const SizedBox(height: 48),
                      // Login Form
                      _buildLoginForm(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCornerPatterns() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _TopCornerPatternPainter(),
      ),
    );
  }

  Widget _buildGoldSeparator() {
    return Builder(
      builder: (context) {
        return Positioned(
          top: 200,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 2),
            painter: _GoldCurvedLinePainter(),
          ),
        );
      },
    );
  }

  Widget _buildLogoCircle() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // خلفية بيضاء
        border: Border.all(
          color: AppColors.loginGold, // حدود ذهبية رفيعة
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // صورة مخفية في الخلفية
            Image.asset(
              'assets/ico1.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // إذا لم توجد الصورة، نستخدم لون خلفية
                return Container(
                  color: Colors.white,
                );
              },
            ),
            // محتوى الشعار فوق الصورة
            _buildLogoContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // شكل S و O ثلاثي الأبعاد (مكعب)
        _build3DCube(),
        // علامة صح خضراء على اليمين (جزئياً خارج الدائرة)
        Positioned(
          right: -8,
          top: 20,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _build3DCube() {
    return Container(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // S Shape (أزرق) - شكل ثلاثي الأبعاد
          CustomPaint(
            size: const Size(70, 70),
            painter: _SShape3DPainter(
              color: AppColors.loginBlue,
            ),
          ),
          // O Shape (ذهبي) - شكل ثلاثي الأبعاد
          CustomPaint(
            size: const Size(70, 70),
            painter: _OShape3DPainter(
              color: AppColors.loginGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'تسجيل الدخول',
      style: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.loginGold,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LoginForm(controller: controller),
    );
  }
}

// Custom Painter للأنماط في الزوايا العلوية
class _TopCornerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.loginBlueLight.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // دوائر في الزاوية اليسرى العلوية
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.08),
      20,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      15,
      paint,
    );

    // دوائر في الزاوية اليمنى العلوية
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.08),
      20,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      15,
      paint,
    );

    // أشكال هندسية إضافية
    final rectPaint = Paint()
      ..color = AppColors.loginBlueLight.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Top left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.25, size.height * 0.15),
        const Radius.circular(20),
      ),
      rectPaint,
    );

    // Top right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, 0, size.width * 0.25, size.height * 0.15),
        const Radius.circular(20),
      ),
      rectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter للخط الذهبي المنحني
class _GoldCurvedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.loginGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2 + 15,
      size.width,
      size.height / 2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter لشكل S ثلاثي الأبعاد
class _SShape3DPainter extends CustomPainter {
  final Color color;

  _SShape3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم شكل S ثلاثي الأبعاد (مكعب)
    final darkColor = Color.lerp(color, Colors.black, 0.3) ?? color;
    final lightColor = Color.lerp(color, Colors.white, 0.3) ?? color;

    // الجزء العلوي من S
    final topPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;
    
    final topPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.05, size.width * 0.75, size.height * 0.15)
      ..lineTo(size.width * 0.75, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.45, size.width * 0.25, size.height * 0.35)
      ..close();
    
    canvas.drawPath(topPath, topPaint);

    // الظل للجزء العلوي
    final shadowPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;
    
    final shadowPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.05, size.width * 0.75, size.height * 0.15)
      ..lineTo(size.width * 0.75, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.45, size.width * 0.25, size.height * 0.35)
      ..close();
    
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // الجزء السفلي من S
    final bottomPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final bottomPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.65, size.width * 0.75, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.85, size.width * 0.25, size.height * 0.75)
      ..close();
    
    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter لشكل O ثلاثي الأبعاد
class _OShape3DPainter extends CustomPainter {
  final Color color;

  _OShape3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = Color.lerp(color, Colors.black, 0.2) ?? color;
    final lightColor = Color.lerp(color, Colors.white, 0.3) ?? color;

    // الظل الخارجي
    final shadowPaint = Paint()
      ..color = darkColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    
    canvas.drawCircle(
      Offset(size.width * 0.5 + 2, size.height * 0.5 + 2),
      size.width * 0.2,
      shadowPaint,
    );

    // الدائرة الرئيسية (O)
    final mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, color, darkColor],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.2,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.2,
      mainPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
