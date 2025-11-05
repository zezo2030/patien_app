import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../departments/departments_screen.dart';
import '../appointments/appointments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  late final Future _userFuture = _authService.getCurrentUser();
  final Map<String, String> _doctorNameCache = {};

  Future<void> _refreshData() async {
    setState(() {});
  }
  Future<String?> _getDoctorName(String doctorId) async {
    if (doctorId.isEmpty) return null;
    if (_doctorNameCache.containsKey(doctorId)) return _doctorNameCache[doctorId];
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      final doctor = await _apiService.getDoctorById(doctorId: doctorId, token: token);
      final name = doctor.name;
      _doctorNameCache[doctorId] = name;
      return name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: FutureBuilder(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'مرحباً، ${snapshot.data!.name}',
                      style: AppTextStyles.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'كيف يمكننا مساعدتك اليوم؟',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                );
              }
              return const Text('VirClinc');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الإشعارات - قريباً')),
                );
              },
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildUpcomingAppointments(),
                const SizedBox(height: 24),
                _buildHealthStats(),
                const SizedBox(height: 24),
                _buildRecentRecords(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إجراءات سريعة', style: AppTextStyles.headline3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.calendar_add,
                  title: 'حجز موعد',
                  color: AppColors.primary,
                  onTap: () {
                    // Navigate to departments to book appointment
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DepartmentsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.health,
                  title: 'التخصصات',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DepartmentsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.video_circle,
                  title: 'جلسة افتراضية',
                  color: AppColors.success,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الجلسات الافتراضية - قريباً'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.hospital,
                  title: 'طوارئ',
                  color: AppColors.error,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الطوارئ - قريباً')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المواعيد القادمة', style: AppTextStyles.headline3),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(),
                    ),
                  );
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<PaginatedAppointments>(
            future: _getUpcomingAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: AppColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'حدث خطأ في تحميل المواعيد',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final appointments = snapshot.data?.appointments ?? [];
              final upcomingAppointments = appointments.where((apt) {
                final now = DateTime.now();
                return (apt.status == 'CONFIRMED' || apt.status == 'PENDING' || apt.status == 'PENDING_CONFIRM') &&
                    apt.startAt.isAfter(now);
              }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

              if (upcomingAppointments.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Iconsax.calendar,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'لا توجد مواعيد قادمة',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'احجز موعدك الأول',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DepartmentsScreen(),
                                ),
                              );
                            },
                            child: const Text('احجز موعد'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show first 3 appointments
              final displayAppointments = upcomingAppointments.take(3).toList();

              return Column(
                children: [
                  ...displayAppointments.map((appointment) {
                    return _buildAppointmentCard(appointment);
                  }),
                  if (upcomingAppointments.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppointmentsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'عرض ${upcomingAppointments.length - 3} موعد إضافي',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<PaginatedAppointments> _getUpcomingAppointments() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return PaginatedAppointments(
          appointments: [],
          total: 0,
          page: 1,
          limit: 100,
          totalPages: 0,
        );
      }
      return await _apiService.getPatientAppointments(
        status: null,
        token: token,
        limit: 100,
      );
    } catch (e) {
      return PaginatedAppointments(
        appointments: [],
        total: 0,
        page: 1,
        limit: 100,
        totalPages: 0,
      );
    }
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final knownDoctorName = appointment.doctor?.name;
    final serviceName = appointment.service?.name ?? 'خدمة غير محددة';
    final dateStr =
        '${appointment.startAt.day}/${appointment.startAt.month}/${appointment.startAt.year}';
    final timeStr =
        '${appointment.startAt.hour.toString().padLeft(2, '0')}:${appointment.startAt.minute.toString().padLeft(2, '0')}';

    Color statusColor = AppColors.info;
    String statusText = 'مؤكد';

    if (appointment.status == 'PENDING' ||
        appointment.status == 'PENDING_CONFIRM') {
      statusColor = AppColors.warning;
      statusText = 'قيد الانتظار';
    } else if (appointment.status == 'CONFIRMED') {
      statusColor = AppColors.info;
      statusText = 'مؤكد';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.calendar_tick,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (knownDoctorName != null && knownDoctorName.isNotEmpty)
                      Text(
                        'د. $knownDoctorName',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      FutureBuilder<String?>(
                        future: _getDoctorName(appointment.doctorId),
                        builder: (context, snapshot) {
                          final name = snapshot.data;
                          return Text(
                            'د. ${name != null && name.isNotEmpty ? name : 'طبيب غير محدد'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 4),
                    Text(
                      serviceName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(dateStr, style: AppTextStyles.bodySmall),
                        const SizedBox(width: 16),
                        Icon(
                          Iconsax.clock,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(timeStr, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إحصائيات صحية', style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _getHealthStats(),
            builder: (context, snapshot) {
              int appointmentsCount = 0;
              int recordsCount = 0;
              int sessionsCount = 0;

              if (snapshot.hasData) {
                appointmentsCount = snapshot.data!['appointments'] ?? 0;
                recordsCount = snapshot.data!['records'] ?? 0;
                sessionsCount = snapshot.data!['sessions'] ?? 0;
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border),
                ),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'المواعيد',
                                appointmentsCount.toString(),
                                Iconsax.calendar,
                                AppColors.primary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'السجلات',
                                recordsCount.toString(),
                                Iconsax.health,
                                AppColors.secondary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'الجلسات',
                                sessionsCount.toString(),
                                Iconsax.video_circle,
                                AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getHealthStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'appointments': 0, 'records': 0, 'sessions': 0};
      }

      // Get appointments count
      final appointments = await _apiService.getPatientAppointments(
        status: null,
        token: token,
        limit: 100,
      );

      // Get medical records count
      final records = await _apiService.getPatientMedicalRecords(
        token: token,
        limit: 100,
      );

      return {
        'appointments': appointments.total,
        'records': records.total,
        'sessions': 0, // TODO: Add sessions count when API is available
      };
    } catch (e) {
      return {'appointments': 0, 'records': 0, 'sessions': 0};
    }
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline3),
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecords() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('السجلات الطبية الأخيرة', style: AppTextStyles.headline3),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'السجلات الطبية - سيتم تطوير هذه الصفحة قريباً',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<PaginatedMedicalRecords>(
            future: _getRecentRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل السجلات',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final records = snapshot.data?.records ?? [];
              if (records.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.health,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد سجلات طبية',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ستظهر السجلات هنا بعد زياراتك الطبية',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show first 3 records
              final displayRecords = records.take(3).toList();

              return Column(
                children: [
                  ...displayRecords.map((record) {
                    return _buildRecordCard(record);
                  }),
                  if (records.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'السجلات الطبية - سيتم تطوير هذه الصفحة قريباً',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            'عرض ${records.length - 3} سجل إضافي',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<PaginatedMedicalRecords> _getRecentRecords() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return PaginatedMedicalRecords(
          records: [],
          total: 0,
          page: 1,
          limit: 100,
          totalPages: 0,
        );
      }
      final result = await _apiService.getPatientMedicalRecords(
        token: token,
        limit: 100,
      );
      // Sort by date, newest first
      final sortedRecords = result.records.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return PaginatedMedicalRecords(
        records: sortedRecords,
        total: result.total,
        page: result.page,
        limit: result.limit,
        totalPages: result.totalPages,
      );
    } catch (e) {
      return PaginatedMedicalRecords(
        records: [],
        total: 0,
        page: 1,
        limit: 100,
        totalPages: 0,
      );
    }
  }

  Widget _buildRecordCard(MedicalRecord record) {
    final doctorName = record.doctor?.name ?? 'طبيب غير محدد';
    final dateStr =
        '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تفاصيل السجل - ${record.diagnosis}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.health,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.diagnosis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'د. $doctorName',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(dateStr, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_left_2,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
