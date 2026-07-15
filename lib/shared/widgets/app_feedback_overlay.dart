import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// The type of feedback to display.
enum FeedbackType { success, error, warning, loading }

/// Displays a full-screen animated Lottie feedback overlay.
/// Use [AppFeedbackOverlay.show] to trigger it imperatively.
class AppFeedbackOverlay extends StatefulWidget {
  final FeedbackType type;
  final String title;
  final String? subtitle;
  final VoidCallback? onDismiss;
  final Duration autoDismissAfter;

  const AppFeedbackOverlay({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.onDismiss,
    this.autoDismissAfter = const Duration(seconds: 2),
  });

  /// Show the feedback overlay as a dialog on top of the current screen.
  static Future<void> show(
    BuildContext context, {
    required FeedbackType type,
    required String title,
    String? subtitle,
    Duration autoDismissAfter = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => AppFeedbackOverlay(
        type: type,
        title: title,
        subtitle: subtitle,
        autoDismissAfter: autoDismissAfter,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<AppFeedbackOverlay> createState() => _AppFeedbackOverlayState();
}

class _AppFeedbackOverlayState extends State<AppFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Auto-dismiss for non-loading types
    if (widget.type != FeedbackType.loading) {
      Future.delayed(widget.autoDismissAfter, () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _borderColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _borderColor.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation (falls back to icon if animation fails)
            SizedBox(
              width: 130,
              height: 130,
              child: _buildAnimation(),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(fontFamily: 'BeIN', 
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(fontFamily: 'BeIN', 
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    // Uses network Lottie animations from LottieFiles CDN (public assets).
    // In production, replace with bundled assets in assets/lottie/
    switch (widget.type) {
      case FeedbackType.success:
        return Lottie.network(
          'https://assets2.lottiefiles.com/packages/lf20_jbrw3hcz.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          errorBuilder: (_, __, ___) => _FallbackIcon(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
        );
      case FeedbackType.error:
        return Lottie.network(
          'https://assets4.lottiefiles.com/packages/lf20_qpwbiyxf.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          errorBuilder: (_, __, ___) => _FallbackIcon(
            icon: Icons.cancel_rounded,
            color: Colors.redAccent,
          ),
        );
      case FeedbackType.warning:
        return Lottie.network(
          'https://assets9.lottiefiles.com/packages/lf20_owZFlt.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          errorBuilder: (_, __, ___) => _FallbackIcon(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
        );
      case FeedbackType.loading:
        return Lottie.network(
          'https://assets3.lottiefiles.com/packages/lf20_usmfx6bp.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..repeat();
          },
          errorBuilder: (_, __, ___) => const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        );
    }
  }

  Color get _borderColor {
    switch (widget.type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return Colors.redAccent;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.loading:
        return AppColors.primary;
    }
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FallbackIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }
}

/// A compact inline status badge (no overlay, used inside cards).
class AppStatusBadge extends StatelessWidget {
  final String label;
  final FeedbackType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      FeedbackType.success => Colors.green,
      FeedbackType.error => Colors.red,
      FeedbackType.warning => Colors.orange,
      FeedbackType.loading => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'BeIN', 
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
