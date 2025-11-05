import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  late Future _userFuture = _authService.getCurrentUser();
  bool _isRefreshing = false;
  
  // Statistics
  int _appointmentsCount = 0;
  int _medicalRecordsCount = 0;
  int _completedAppointmentsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
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
        _apiService.getPatientAppointments(token: token, status: 'COMPLETED', limit: 1),
      ]);

      setState(() {
        _appointmentsCount = (results[0] as PaginatedAppointments).total;
        _medicalRecordsCount = (results[1] as PaginatedMedicalRecords).total;
        _completedAppointmentsCount = (results[2] as PaginatedAppointments).total;
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
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          elevation: 0,
          actions: [
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshProfile,
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: FutureBuilder(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                String errorMessage = 'حدث خطأ في تحميل البيانات';
                bool shouldNavigateToLogin = false;

                if (error.toString().contains('انتهت صلاحية') ||
                    error.toString().contains('401') ||
                    error.toString().contains('غير مصرح')) {
                  errorMessage = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
                  shouldNavigateToLogin = true;
                } else if (error.toString().contains('لا يمكن الاتصال')) {
                  errorMessage = 'لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت';
                } else {
                  errorMessage = error.toString().replaceAll('Exception: ', '');
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: shouldNavigateToLogin
                            ? () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              }
                            : () {
                                setState(() {
                                  _userFuture = _authService.getCurrentUser();
                                });
                              },
                        icon: Icon(shouldNavigateToLogin ? Icons.login : Icons.refresh),
                        label: Text(shouldNavigateToLogin ? 'تسجيل الدخول' : 'إعادة المحاولة'),
                      ),
                    ],
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
    if (_isLoadingStats) {
      return Row(
        children: [
          Expanded(child: _buildStatCard('المواعيد', '...', Icons.event)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('السجلات', '...', Icons.medical_services)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('الجلسات', '...', Icons.video_call)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('المواعيد', _appointmentsCount.toString(), Icons.event)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('السجلات', _medicalRecordsCount.toString(), Icons.medical_services)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('الجلسات', _completedAppointmentsCount.toString(), Icons.video_call)),
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

