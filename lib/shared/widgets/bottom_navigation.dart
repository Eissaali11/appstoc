import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'لوحة التحكم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'المخزون الثابت',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.move_to_inbox),
          label: 'المخزون المتحرك',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'الإشعارات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'الملف الشخصي',
        ),
      ],
    );
  }
}
