import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/dimensions.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../../models/department.dart';
import '../departments/departments_screen.dart';
import '../appointments/appointments_screen.dart';
import '../../config/api_config.dart';

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
  
  late Future<List<Department>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _apiService.getPublicDepartments();
  }

  Future<void> _refreshData() async {
    setState(() {
      _departmentsFuture = _apiService.getPublicDepartments();
    });
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
        body: CustomScrollView(
          slivers: [
            // App Bar with Gradient
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: FutureBuilder(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(
                        'مرحباً، ${snapshot.data!.name}',
                        style: AppTextStyles.headline3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const Text('مرحباً');
                  },
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: AppColors.gradientPrimary,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.notification),
                  color: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الإشعارات - قريباً')),
                    );
                  },
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Popular Departments Section
                    _buildPopularDepartments(),
                    
                    const SizedBox(height: 24),
                    
                    // Upcoming Appointments
                    _buildUpcomingAppointments(),
                    
                    const SizedBox(height: 24),
                    
                    // Health Stats
                    _buildHealthStats(),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Records
                    _buildRecentRecords(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(
                  Iconsax.flash,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: AppDimensions.spacingMD),
              Text(
                'إجراءات سريعة',
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingLG),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.calendar_add,
                  title: 'حجز موعد',
                  subtitle: 'احجز موعدك الآن',
                  color: AppColors.primary,
                  gradient: AppColors.gradientPrimary,
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
              SizedBox(width: AppDimensions.spacingMD),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Iconsax.health,
                  title: 'التخصصات',
                  subtitle: 'استكشف الأقسام',
                  color: AppColors.secondary,
                  gradient: AppColors.gradientSecondary,
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
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.spacingSM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(height: AppDimensions.spacingMD),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularDepartments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Icon(
                      Iconsax.health,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingMD),
                  Text(
                    'الأقسام الشائعة',
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DepartmentsScreen(),
                    ),
                  );
                },
                child: Text(
                  'عرض الكل',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.spacingMD),
        FutureBuilder<List<Department>>(
          future: _departmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'لا توجد أقسام متاحة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            final departments = snapshot.data!.take(6).toList();
            
            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  return _buildDepartmentCard(department, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDepartmentCard(Department department, int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.info,
      AppColors.medicalTeal,
    ];
    final color = colors[index % colors.length];
    final logoUrl = department.logoUrl != null && department.logoUrl!.isNotEmpty
        ? ApiConfig.buildFullUrl(department.logoUrl)
        : null;

    return Container(
      width: 120,
      margin: EdgeInsets.only(left: AppDimensions.spacingMD),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DepartmentsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: logoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Iconsax.health,
                              color: color,
                              size: 32,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Iconsax.health,
                        color: color,
                        size: 32,
                      ),
              ),
              SizedBox(height: AppDimensions.spacingSM),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingXS),
                child: Text(
                  department.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Icon(
                      Iconsax.calendar,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingMD),
                  Text(
                    'المواعيد القادمة',
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(),
                    ),
                  );
                },
                child: Text(
                  'عرض الكل',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingMD),
          FutureBuilder<PaginatedAppointments>(
            future: _getUpcomingAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  ),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  ),
                  child: Column(
                    children: [
                      Icon(Iconsax.info_circle, color: AppColors.error, size: 32),
                      SizedBox(height: AppDimensions.spacingMD),
                      Text(
                        'حدث خطأ في تحميل المواعيد',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.border.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppDimensions.spacingLG),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.calendar,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingMD),
                      Text(
                        'لا توجد مواعيد قادمة',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'احجز موعدك الأول',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingLG),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientPrimary,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DepartmentsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingLG,
                                vertical: AppDimensions.spacingMD,
                              ),
                              child: Text(
                                'احجز موعد',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final displayAppointments = upcomingAppointments.take(2).toList();

              return Column(
                children: [
                  ...displayAppointments.map((appointment) {
                    return _buildAppointmentCard(appointment);
                  }),
                  if (upcomingAppointments.length > 2)
                    Padding(
                      padding: EdgeInsets.only(top: AppDimensions.spacingMD),
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
                            'عرض ${upcomingAppointments.length - 2} موعد إضافي',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
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
      statusColor = AppColors.success;
      statusText = 'مؤكد';
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingLG),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Icon(
                    Iconsax.calendar_tick,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppDimensions.spacingMD),
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
                      SizedBox(height: 4),
                      Text(
                        serviceName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(dateStr, style: AppTextStyles.bodySmall),
                          SizedBox(width: 16),
                          Icon(
                            Iconsax.clock,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(timeStr, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingSM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
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
      ),
    );
  }

  Widget _buildHealthStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(
                  Iconsax.chart,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              SizedBox(width: AppDimensions.spacingMD),
              Text(
                'إحصائيات صحية',
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingMD),
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

              return Container(
                padding: EdgeInsets.all(AppDimensions.spacingLG),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppColors.backgroundLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : Row(
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
                            height: 50,
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
                            height: 50,
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

      final appointments = await _apiService.getPatientAppointments(
        status: null,
        token: token,
        limit: 100,
      );

      final records = await _apiService.getPatientMedicalRecords(
        token: token,
        limit: 100,
      );

      return {
        'appointments': appointments.total,
        'records': records.total,
        'sessions': 0,
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
        Container(
          padding: EdgeInsets.all(AppDimensions.spacingSM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: AppDimensions.spacingSM),
        Text(
          value,
          style: AppTextStyles.headline2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
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
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Icon(
                      Iconsax.document_text,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingMD),
                  Text(
                    'السجلات الطبية الأخيرة',
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                child: Text(
                  'عرض الكل',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingMD),
          FutureBuilder<PaginatedMedicalRecords>(
            future: _getRecentRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  ),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  ),
                  child: Column(
                    children: [
                      Icon(Iconsax.info_circle, color: AppColors.error, size: 32),
                      SizedBox(height: AppDimensions.spacingMD),
                      Text(
                        'حدث خطأ في تحميل السجلات',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final records = snapshot.data?.records ?? [];
              if (records.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.border.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppDimensions.spacingLG),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.health,
                          size: 32,
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingMD),
                      Text(
                        'لا توجد سجلات طبية',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ستظهر السجلات هنا بعد زياراتك الطبية',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final displayRecords = records.take(2).toList();

              return Column(
                children: [
                  ...displayRecords.map((record) {
                    return _buildRecordCard(record);
                  }),
                  if (records.length > 2)
                    Padding(
                      padding: EdgeInsets.only(top: AppDimensions.spacingMD),
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
                            'عرض ${records.length - 2} سجل إضافي',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
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

    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تفاصيل السجل - ${record.diagnosis}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacingLG),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Icon(
                    Iconsax.health,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppDimensions.spacingMD),
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
                      SizedBox(height: 4),
                      Text(
                        'د. $doctorName',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(dateStr, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
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
  }
}
