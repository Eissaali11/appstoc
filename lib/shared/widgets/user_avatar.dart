import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avatar that shows profile photo, or RASSCO logo fallback.
class UserAvatar extends StatelessWidget {
  final String? profileImage;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final bool showLogoPadding;

  const UserAvatar({
    super.key,
    this.profileImage,
    this.size = 64,
    this.borderWidth = 2,
    this.borderColor,
    this.showLogoPadding = true,
  });

  bool get _hasPhoto {
    final v = profileImage?.trim() ?? '';
    return v.isNotEmpty &&
        (v.startsWith('data:image') ||
            v.startsWith('http://') ||
            v.startsWith('https://') ||
            v.startsWith('blob:'));
  }

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withOpacity(0.2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundDark,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _hasPhoto ? _buildPhoto(profileImage!) : _buildLogoFallback(),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Padding(
      padding: EdgeInsets.all(showLogoPadding ? size * 0.12 : 0),
      child: Image.asset(
        'assets/images/logo-1.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person,
          size: size * 0.45,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPhoto(String src) {
    if (src.startsWith('data:image')) {
      try {
        final comma = src.indexOf(',');
        final b64 = comma >= 0 ? src.substring(comma + 1) : src;
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        return _buildLogoFallback();
      }
    }
    return Image.network(
      src,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => _buildLogoFallback(),
    );
  }
}
