import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Compact RASSCO mark for AppBars — used across the technician app.
class RasscoAppBarLogo extends StatelessWidget {
  final double height;

  const RasscoAppBarLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + 8,
      width: height + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Image.asset(
        'assets/images/logo-1.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.business,
          size: height * 0.7,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Wraps any AppBar title with the RASSCO logo on the start side.
class RasscoBrandTitle extends StatelessWidget {
  final Widget child;
  final double logoHeight;

  const RasscoBrandTitle({
    super.key,
    required this.child,
    this.logoHeight = 28,
  });

  /// Convenience for plain string titles.
  factory RasscoBrandTitle.text(
    String text, {
    Key? key,
    TextStyle? style,
    double logoHeight = 28,
  }) {
    return RasscoBrandTitle(
      key: key,
      logoHeight: logoHeight,
      child: Text(
        text,
        style: style ??
            const TextStyle(
              fontFamily: 'BeIN',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RasscoAppBarLogo(height: logoHeight),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

/// Drop-in AppBar with branded logo on every page.
class RasscoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double? titleSpacing;
  final IconThemeData? iconTheme;

  const RasscoAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
    this.iconTheme,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final Widget? resolvedTitle = titleText != null
        ? RasscoBrandTitle.text(titleText!)
        : title != null
            ? RasscoBrandTitle(child: title!)
            : const RasscoBrandTitle(
                child: SizedBox.shrink(),
              );

    return AppBar(
      title: resolvedTitle,
      actions: actions,
      leading: leading,
      bottom: bottom,
      backgroundColor: backgroundColor ?? AppColors.surfaceDark,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing ?? 12,
      iconTheme: iconTheme ?? const IconThemeData(color: Colors.white),
    );
  }
}
