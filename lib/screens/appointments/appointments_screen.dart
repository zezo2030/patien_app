import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();
  final _authService = AuthService();
  
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  String _getArabicWeekday(int weekday) {
    const weekdays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    return weekdays[weekday - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'مساءً' : 'صباحاً';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<PaginatedAppointments> _fetchAppointments({String? status}) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    return await _apiService.getPatientAppointments(
      status: status,
      token: token,
      limit: 100,
    );
  }

  List<Appointment> _filterAppointments(
    List<Appointment> allAppointments,
    int tabIndex,
  ) {
    final now = DateTime.now();
    
    switch (tabIndex) {
      case 0: // القادمة
        return allAppointments.where((appointment) {
          final isUpcoming = appointment.startAt.isAfter(now);
          return (appointment.status == 'CONFIRMED' || 
                  appointment.status == 'PENDING') && 
                 isUpcoming;
        }).toList();
      case 1: // السابقة
        return allAppointments.where((appointment) {
          return appointment.status == 'COMPLETED' ||
                 (appointment.startAt.isBefore(now) && 
                  appointment.status != 'CANCELLED');
        }).toList();
      case 2: // الملغاة
        return allAppointments.where((appointment) {
          return appointment.status == 'CANCELLED';
        }).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'مواعيدي',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: AppColors.gradientPrimary,
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        setState(() {
                          _currentTabIndex = index;
                        });
                      },
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Iconsax.calendar_tick, size: 20),
                          text: 'القادمة',
                        ),
                        Tab(
                          icon: Icon(Iconsax.calendar_1, size: 20),
                          text: 'السابقة',
                        ),
                        Tab(
                          icon: Icon(Iconsax.calendar_remove, size: 20),
                          text: 'الملغاة',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList(),
              _buildAppointmentsList(),
              _buildAppointmentsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return FutureBuilder<PaginatedAppointments>(
      future: _fetchAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل المواعيد',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyState('لا توجد مواعيد');
        }

        final filteredAppointments = _filterAppointments(
          snapshot.data!.appointments,
          _currentTabIndex,
        );

        if (filteredAppointments.isEmpty) {
          final messages = [
            'لا توجد مواعيد قادمة',
            'لا توجد مواعيد سابقة',
            'لا توجد مواعيد ملغاة',
          ];
          return _buildEmptyState(messages[_currentTabIndex]);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(filteredAppointments[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    IconData icon;
    String subtitle;
    
    switch (_currentTabIndex) {
      case 0:
        icon = Iconsax.calendar_tick;
        subtitle = 'عندما تحجز موعداً جديداً، سيظهر هنا';
        break;
      case 1:
        icon = Iconsax.calendar_1;
        subtitle = 'سجل المواعيد السابقة سيظهر هنا';
        break;
      case 2:
        icon = Iconsax.calendar_remove;
        subtitle = 'لم يتم إلغاء أي موعد حتى الآن';
        break;
      default:
        icon = Iconsax.calendar;
        subtitle = '';
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
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final status = appointment.status;
    Color statusColor = AppColors.info;
    String statusText = 'مؤكد';
    IconData statusIcon = Iconsax.tick_circle;
    
    if (status == 'PENDING' || status == 'PENDING_CONFIRM') {
      statusColor = AppColors.warning;
      statusText = 'قيد الانتظار';
      statusIcon = Iconsax.clock;
    } else if (status == 'CANCELLED') {
      statusColor = AppColors.error;
      statusText = 'ملغى';
      statusIcon = Iconsax.close_circle;
    } else if (status == 'COMPLETED') {
      statusColor = AppColors.success;
      statusText = 'مكتمل';
      statusIcon = Iconsax.tick_circle;
    } else if (status == 'CONFIRMED') {
      statusColor = AppColors.info;
      statusText = 'مؤكد';
      statusIcon = Iconsax.verify;
    }

    // Format date
    final day = appointment.startAt.day;
    final month = _getArabicMonth(appointment.startAt.month);
    final year = appointment.startAt.year;
    final weekday = _getArabicWeekday(appointment.startAt.weekday);
    final time = _formatTime(appointment.startAt);
    
    // Get doctor name
    final doctorName = appointment.doctor?.name ?? 'طبيب غير محدد';
    
    // Get service/department name
    final serviceName = appointment.service?.name ?? 'خدمة غير محددة';

    // Calculate time until appointment
    final now = DateTime.now();
    final difference = appointment.startAt.difference(now);
    String timeUntil = '';
    
    if (difference.isNegative && status != 'COMPLETED' && status != 'CANCELLED') {
      timeUntil = 'منتهي';
    } else if (status == 'CONFIRMED' || status == 'PENDING') {
      if (difference.inDays > 0) {
        timeUntil = 'بعد ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        timeUntil = 'بعد ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        timeUntil = 'بعد ${difference.inMinutes} دقيقة';
      } else {
        timeUntil = 'الآن';
      }
    }

    final canCancel = (status == 'CONFIRMED' || status == 'PENDING') && 
                      difference.inHours > 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showAppointmentDetails(appointment);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    statusColor.withOpacity(0.1),
                    statusColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Doctor Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AppColors.gradientPrimary,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'د',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Doctor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'د. $doctorName',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Iconsax.health,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                serviceName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date and Time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Date Section
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Iconsax.calendar_1,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weekday,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '$day $month $year',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Time Section
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Iconsax.clock,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الوقت',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time Until / Price Section
                  if (timeUntil.isNotEmpty || appointment.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (timeUntil.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.timer_1,
                                    size: 16,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeUntil,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (appointment.price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.money,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${appointment.price} ريال',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Action Buttons
                  if (canCancel)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _cancelAppointment(appointment),
                              icon: const Icon(Iconsax.close_square, size: 18),
                              label: const Text('إلغاء الموعد'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rescheduleAppointment(appointment),
                              icon: const Icon(Iconsax.refresh, size: 18),
                              label: const Text('إعادة جدولة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
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

  void _showAppointmentDetails(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تفاصيل الموعد - سيتم تطوير هذه الصفحة قريباً'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الموعد'),
          content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم تطوير هذه الميزة قريباً'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إعادة جدولة الموعد - سيتم تطوير هذه الميزة قريباً'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
