import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardChart extends StatelessWidget {
  const DashboardChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'النشاط الميداني الأسبوعي',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'معدل توريد وتسليم الأجهزة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'آخر 7 أيام',
                    style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _NeonLineChartPainter(
                  data: [15, 28, 18, 42, 35, 55, 48],
                  labels: ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('تسجيل توريد', AppColors.primary),
                _buildLegendItem('تسليم أجهزة', const Color(0xFF6366F1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NeonLineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  _NeonLineChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // Draw background grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    
    const int gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final double y = height - (i * (height / gridRows));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (data.isEmpty) return;

    final double maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    final double minVal = 0;
    final double range = maxVal - minVal;

    final double xStep = width / (data.length - 1);
    
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double normY = (data[i] - minVal) / range;
      final double y = height - (normY * height * 0.8) - 10;
      points.add(Offset(x, y));
    }

    // Generate smooth path (Bezier Curve)
    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final double controlX1 = p1.dx + (xStep / 2);
      final double controlY1 = p1.dy;
      final double controlX2 = p2.dx - (xStep / 2);
      final double controlY2 = p2.dy;
      
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p2.dx, p2.dy);
    }

    // 1. Draw glowing gradient area below line
    final Path areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, height);
    areaPath.lineTo(points.first.dx, height);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.35),
          AppColors.primary.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, width, height));
    
    canvas.drawPath(areaPath, areaPaint);

    // 2. Draw neon glowing line
    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Add simple shadow/glow
    final Paint shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);

    // 3. Draw active dots and value text
    final Paint dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final Paint innerDotPaint = Paint()
      ..color = AppColors.surfaceDark
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final Offset p = points[i];
      // Draw outer circle
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 2.5, innerDotPaint);

      // Draw values for top days
      if (i == 3 || i == 5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: data[i].toInt().toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(
          canvas, 
          Offset(p.dx - (textPainter.width / 2), p.dy - 18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
