import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, int>? badges;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_1,
                label: 'الرئيسية',
                index: 0,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.hospital,
                activeIcon: Iconsax.hospital,
                label: 'التخصصات',
                index: 1,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.calendar_1,
                activeIcon: Iconsax.calendar_tick,
                label: 'المواعيد',
                index: 2,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.user,
                activeIcon: Iconsax.profile_circle,
                label: 'الملف الشخصي',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    final badgeCount = badges?[label] ?? 0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: isActive ? 32 : 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(isActive ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.primary.withOpacity(0.15) 
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedScale(
                          scale: isActive ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Icon(
                            isActive ? activeIcon : icon,
                            color: isActive 
                                ? AppColors.primary 
                                : AppColors.textSecondary.withOpacity(0.7),
                            size: isActive ? 22 : 20,
                          ),
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: badgeCount > 9 
                                ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                                : const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error,
                                  AppColors.error.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                badgeCount > 9 ? '9+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: isActive ? 6 : 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isActive 
                        ? AppColors.primary 
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: isActive ? 11 : 10,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

