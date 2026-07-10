import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isTabletDevice => screenWidth > 600;
  bool get isSmallPhoneDevice => screenWidth < 360;

  double responsive({
    required double mobile,
    double? tablet,
    double? smallPhone,
  }) {
    if (isTabletDevice) return tablet ?? mobile;
    if (isSmallPhoneDevice) return smallPhone ?? mobile;
    return mobile;
  }

  double fontSize(double baseSize) {
    if (isTabletDevice) return baseSize * 1.15;
    if (isSmallPhoneDevice) return baseSize * 0.9;
    return baseSize;
  }
}
