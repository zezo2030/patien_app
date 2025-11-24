import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../../models/user.dart';
import '../medical_records/medical_records_screen.dart';
import '../appointments/appointments_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  late Future<User?> _userFuture;
  bool _isRefreshing = false;

  // Statistics
  int _appointmentsCount = 0;
  int _medicalRecordsCount = 0;
  int _completedAppointmentsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.getCurrentUser();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingStats = false;
        });
        return;
      }

      // Load statistics in parallel
      final results = await Future.wait([
        _apiService.getPatientAppointments(token: token, limit: 1),
        _apiService.getPatientMedicalRecords(token: token, limit: 1),
        _apiService.getPatientAppointments(
          token: token,
          status: 'COMPLETED',
          limit: 1,
        ),
      ]);

      setState(() {
        _appointmentsCount = (results[0] as PaginatedAppointments).total;
        _medicalRecordsCount = (results[1] as PaginatedMedicalRecords).total;
        _completedAppointmentsCount =
            (results[2] as PaginatedAppointments).total;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('⚠️ Error loading statistics: $e');
      setState(() {
        _isLoadingStats = false;
      });
      // Don't show error to user, just use 0 values
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final user = await _authService.refreshCurrentUser();
      await _loadStatistics();
      setState(() {
        _userFuture = Future.value(user);
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البيانات بنجاح'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      if (mounted) {
        String errorMessage = 'فشل تحديث البيانات';
        if (e.toString().contains('انتهت صلاحية')) {
          errorMessage = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
          // Navigate to login if session expired
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        } else if (e.toString().contains('غير مصرح')) {
          errorMessage = 'غير مصرح - يرجى تسجيل الدخول';
        } else if (e.toString().contains('لا يمكن الاتصال')) {
          errorMessage = 'لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: AppColors.primary,
          child: FutureBuilder<User?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isRefreshing) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'جاري تحميل البيانات...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                String errorMessage = 'حدث خطأ في تحميل البيانات';
                bool shouldNavigateToLogin = false;

                if (error.toString().contains('انتهت صلاحية') ||
                    error.toString().contains('401') ||
                    error.toString().contains('غير مصرح')) {
                  errorMessage =
                      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
                  shouldNavigateToLogin = true;
                } else if (error.toString().contains('لا يمكن الاتصال')) {
                  errorMessage =
                      'لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت';
                } else {
                  errorMessage = error.toString().replaceAll('Exception: ', '');
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error.withOpacity(0.15),
                                AppColors.error.withOpacity(0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Iconsax.info_circle,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          errorMessage,
                          style: AppTextStyles.headline3.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: shouldNavigateToLogin
                              ? () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/login');
                                }
                              : () {
                                  setState(() {
                                    _userFuture = _authService.getCurrentUser();
                                  });
                                },
                          icon: Icon(
                            shouldNavigateToLogin
                                ? Iconsax.login
                                : Iconsax.refresh,
                            size: 20,
                          ),
                          label: Text(
                            shouldNavigateToLogin
                                ? 'تسجيل الدخول'
                                : 'إعادة المحاولة',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد بيانات للمستخدم',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('تسجيل الدخول'),
                      ),
                    ],
                  ),
                );
              }

              final user = snapshot.data!;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    // زر التحديث في الأعلى
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الملف الشخصي',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Iconsax.refresh,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                          onPressed: _isRefreshing ? null : _refreshProfile,
                          tooltip: 'تحديث البيانات',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileHeader(user),
                    const SizedBox(height: 20),
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildMenuSection(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar with gradient border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.gradientPrimary),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white,
                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: AppColors.gradientPrimary,
                          ),
                        ),
                        child: Icon(
                          Iconsax.user,
                          size: 56,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.name,
              style: AppTextStyles.headline2.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.sms, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  user.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.15),
                    AppColors.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.verify, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    user.role,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_isLoadingStats) {
      return Row(
        children: [
          Expanded(child: _buildStatCard('المواعيد', '...', Icons.event)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('السجلات', '...', Icons.medical_services),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('الجلسات', '...', Icons.video_call)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'المواعيد',
            _appointmentsCount.toString(),
            Icons.event,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'السجلات',
            _medicalRecordsCount.toString(),
            Icons.medical_services,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'الجلسات',
            _completedAppointmentsCount.toString(),
            Icons.video_call,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    Color cardColor;
    Color iconColor;
    bool isClickable = false;

    // تحديد الألوان حسب نوع البطاقة
    switch (title) {
      case 'المواعيد':
        cardColor = AppColors.primary;
        iconColor = AppColors.primary;
        isClickable = true;
        break;
      case 'السجلات':
        cardColor = AppColors.info;
        iconColor = AppColors.info;
        isClickable = true;
        break;
      case 'الجلسات':
        cardColor = AppColors.success;
        iconColor = AppColors.success;
        break;
      default:
        cardColor = AppColors.primary;
        iconColor = AppColors.primary;
    }

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.headline2.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isClickable) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_left_2,
                    size: 14,
                    color: iconColor.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    // إذا كانت البطاقة قابلة للنقر، نضيف InkWell
    if (isClickable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'السجلات') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicalRecordsScreen(),
                ),
              );
            } else if (title == 'المواعيد') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsScreen(),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Iconsax.profile_circle,
        'title': 'تعديل الملف الشخصي',
        'color': AppColors.primary,
        'onTap': () async {
          // Resolve user before navigation
          final user = await _userFuture;
          if (user != null && context.mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileEditScreen(user: user),
              ),
            );

            if (result == true) {
              _refreshProfile();
            }
          }
        },
      },
      {
        'icon': Iconsax.health,
        'title': 'السجلات الطبية',
        'color': AppColors.info,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MedicalRecordsScreen(),
            ),
          );
        },
      },
      {
        'icon': Iconsax.wallet,
        'title': 'المدفوعات',
        'color': AppColors.success,
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Iconsax.setting_2,
        'title': 'الإعدادات',
        'color': AppColors.textSecondary,
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Iconsax.message_question,
        'title': 'المساعدة والدعم',
        'color': AppColors.accent,
        'onTap': () => _showComingSoon(context),
      },
      {
        'icon': Iconsax.logout,
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
        final itemColor = item['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: itemColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Iconsax.arrow_left_2,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
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
