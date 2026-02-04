import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardHeader extends StatefulWidget {
  final String userName;
  final int notificationCount;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.notificationCount = 0,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  String _currentDateTime = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _startTimer();

    // Pulse animation for notification badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _updateDateTime();
        });
        _startTimer();
      }
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    _currentDateTime = '${dateFormat.format(now)} - ${timeFormat.format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 400;

        Widget buildTopBar() {
          final logoWidget = SizedBox(
            height: isNarrow ? 48 : 64,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset('assets/banr.png'),
            ),
          );

          final controlsRow = Row(
            children: [
              // Side menu button لفتح القائمة الجانبية
              _IconButton(
                icon: Icons.menu,
                onTap: () {
                  final scaffoldState = Scaffold.maybeOf(context);
                  scaffoldState?.openDrawer();
                },
                tooltip: 'القائمة',
              ),
              const SizedBox(width: 8),
              Text(
                'المركز',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              // Notifications with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconButton(
                    icon: Icons.notifications,
                    onTap: () => Get.toNamed('/notifications'),
                    tooltip: 'الإشعارات',
                  ),
                  if (widget.notificationCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentRed.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  widget.notificationCount > 9
                                      ? '9+'
                                      : widget.notificationCount.toString(),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              _IconButton(
                icon: Icons.person,
                onTap: () => Get.toNamed('/profile'),
                tooltip: 'الملف الشخصي',
              ),
            ],
          );

          if (isNarrow) {
            // على الشاشات الصغيرة نعرض الشعار فوق العناصر لنتجنب التداخل
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: controlsRow),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: logoWidget,
                ),
              ],
            );
          } else {
            // على الشاشات الأوسع نستمر باستخدام صف واحد، مع توزيع مرن
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: controlsRow,
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: logoWidget,
                  ),
                ),
              ],
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF020617)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTopBar(),
                  const SizedBox(height: 24),
                  // Welcome and date section
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${widget.userName}!',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentDateTime,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
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
        );
      },
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconButton({required this.icon, required this.onTap, this.tooltip});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (_controller.value * 0.1),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_isPressed ? 0.3 : 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
            );
          },
        ),
      ),
    );
  }
}
