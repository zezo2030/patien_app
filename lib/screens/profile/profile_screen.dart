import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late final Future _userFuture = _authService.getCurrentUser();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          elevation: 0,
        ),
        body: FutureBuilder(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Text(
                  'حدث خطأ في تحميل البيانات',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            }

            final user = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),
                  _buildStatistics(),
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('المواعيد', '12', Icons.event)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('السجلات', '8', Icons.medical_services)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('الجلسات', '5', Icons.video_call)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headline2.copyWith(
                fontSize: 24,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.person_outline,
        'title': 'تعديل الملف الشخصي',
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Icons.medical_services_outlined,
        'title': 'السجلات الطبية',
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'المدفوعات',
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'الإعدادات',
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Icons.help_outline,
        'title': 'المساعدة',
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Icons.logout,
        'title': 'تسجيل الخروج',
        'color': AppColors.error,
        'onTap': () async {
          await _authService.logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
      },
    ];

    return Column(
      children: menuItems.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: item.containsKey('color') ? item['color'] as Color : AppColors.primary,
            ),
            title: Text(
              item['title'] as String,
              style: AppTextStyles.bodyLarge,
            ),
            trailing: Icon(
              Icons.chevron_left,
              color: AppColors.textSecondary,
            ),
            onTap: item['onTap'] as VoidCallback,
          ),
        );
      }).toList(),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير هذه الميزة قريباً')),
    );
  }
}

