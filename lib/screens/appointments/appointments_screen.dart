import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';
import 'appointment_details_screen.dart';

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
  final Map<String, String> _doctorNameCache = {};
  
  int _currentTabIndex = 0;
  bool _isLoading = false;
  Future<PaginatedAppointments>? _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _appointmentsFuture = _fetchAppointments();
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
    int hour = dateTime.hour;
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _getArabicMonth(dateTime.month);
    final year = dateTime.year;
    final weekday = _getArabicWeekday(dateTime.weekday);
    return '$weekday، $day $month $year';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'PENDING_CONFIRM':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'مؤكد';
      case 'PENDING_CONFIRM':
        return 'في انتظار التأكيد';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغي';
      case 'PENDING':
        return 'قيد الانتظار';
      default:
        return status;
    }
  }

  IconData _getButtonIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.video:
        return Iconsax.video;
      case AppointmentType.chat:
        return Iconsax.message;
      case AppointmentType.inPerson:
        return Iconsax.location;
      default:
        return Iconsax.info_circle;
    }
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
                  appointment.status == 'PENDING' ||
                  appointment.status == 'PENDING_CONFIRM') && 
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
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'مواعيدي',
                    style: AppTextStyles.headline3.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: AppColors.gradientMedical,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: 20,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          right: -20,
                          child: Container(
                            width: 120,
                            height: 120,
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
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
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Iconsax.calendar_tick, size: 22),
                          text: 'القادمة',
                        ),
                        Tab(
                          icon: Icon(Iconsax.calendar_1, size: 22),
                          text: 'السابقة',
                        ),
                        Tab(
                          icon: Icon(Iconsax.calendar_remove, size: 22),
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
              _buildAppointmentsList(0),
              _buildAppointmentsList(1),
              _buildAppointmentsList(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(int tabIndex) {
    return FutureBuilder<PaginatedAppointments>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'جاري تحميل المواعيد...',
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
                    'حدث خطأ في تحميل المواعيد',
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _appointmentsFuture = _fetchAppointments();
                        });
                      }
                    },
                    icon: const Icon(Iconsax.refresh, size: 20),
                    label: const Text('إعادة المحاولة'),
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

        if (!snapshot.hasData) {
          return _buildEmptyState('لا توجد مواعيد');
        }

        final filteredAppointments = _filterAppointments(
          snapshot.data!.appointments,
          tabIndex,
        );

        if (filteredAppointments.isEmpty) {
          final messages = [
            'لا توجد مواعيد قادمة',
            'لا توجد مواعيد سابقة',
            'لا توجد مواعيد ملغاة',
          ];
          return _buildEmptyState(messages[tabIndex]);
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {
                _appointmentsFuture = _fetchAppointments();
              });
            }
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
    Color iconColor;
    
    switch (_currentTabIndex) {
      case 0:
        icon = Iconsax.calendar_tick;
        subtitle = 'عندما تحجز موعداً جديداً، سيظهر هنا';
        iconColor = AppColors.success;
        break;
      case 1:
        icon = Iconsax.calendar_1;
        subtitle = 'سجل المواعيد السابقة سيظهر هنا';
        iconColor = AppColors.info;
        break;
      case 2:
        icon = Iconsax.calendar_remove;
        subtitle = 'لم يتم إلغاء أي موعد حتى الآن';
        iconColor = AppColors.textSecondary;
        break;
      default:
        icon = Iconsax.calendar;
        subtitle = '';
        iconColor = AppColors.primary;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final clampedValue = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clampedValue,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          iconColor.withOpacity(0.15),
                          iconColor.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 80,
                      color: iconColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              message,
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    // Format date
    final day = appointment.startAt.day;
    final month = _getArabicMonth(appointment.startAt.month);
    final year = appointment.startAt.year;
    final weekday = _getArabicWeekday(appointment.startAt.weekday);
    
    // Format time range
    final startTime = _formatTime(appointment.startAt);
    final endTime = _formatTime(appointment.endAt);
    final timeRange = '$startTime - $endTime';
    
    // Get doctor name
    final knownDoctorName = appointment.doctor?.name;
    
    // Get appointment type
    final appointmentType = AppointmentType.fromString(appointment.type);
    
    // Get button text based on appointment type
    String buttonText;
    VoidCallback? onButtonPressed;
    
    switch (appointmentType) {
      case AppointmentType.video:
        buttonText = 'انضم إلى جلسة الفيديو';
        onButtonPressed = () {
          // TODO: Navigate to video call screen
          _showAppointmentDetails(appointment);
        };
        break;
      case AppointmentType.chat:
        buttonText = 'أرسل رسالة';
        onButtonPressed = () {
          // TODO: Navigate to chat screen
          _showAppointmentDetails(appointment);
        };
        break;
      case AppointmentType.inPerson:
        buttonText = 'حضوري';
        onButtonPressed = () {
          _showAppointmentDetails(appointment);
        };
        break;
      default:
        buttonText = 'عرض التفاصيل';
        onButtonPressed = () {
          _showAppointmentDetails(appointment);
        };
    }

    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showAppointmentDetails(appointment);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture - Modern circular design
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: AppColors.gradientPrimary,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (knownDoctorName != null && knownDoctorName.isNotEmpty)
                              ? knownDoctorName[0].toUpperCase()
                              : 'د',
                          style: AppTextStyles.headline2.copyWith(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Doctor Info and Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Name with status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (knownDoctorName != null && knownDoctorName.isNotEmpty)
                                      RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontSize: 17,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'د. $knownDoctorName',
                                              style: AppTextStyles.bodyLarge.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      FutureBuilder<String?>(
                                        future: _getDoctorName(appointment.doctorId),
                                        builder: (context, snapshot) {
                                          final name = snapshot.data;
                                          return RichText(
                                            text: TextSpan(
                                              style: AppTextStyles.bodyLarge.copyWith(
                                                fontSize: 17,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'د. ${name != null && name.isNotEmpty ? name : 'طبيب غير محدد'}',
                                                  style: AppTextStyles.bodyLarge.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 4),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(appointment.status),
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date and Time in modern cards
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Date
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Iconsax.calendar_1,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '$weekday، $day $month $year',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Time
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Iconsax.clock,
                                        size: 16,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        timeRange,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  ],
                ),
                const SizedBox(height: 16),
                // Action Button - Modern gradient design
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onButtonPressed,
                    icon: Icon(
                      _getButtonIcon(appointmentType ?? AppointmentType.inPerson),
                      size: 20,
                    ),
                    label: Text(
                      buttonText,
                      style: AppTextStyles.button.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _showAppointmentDetails(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(appointment: appointment),
      ),
    ).then((result) {
      // إعادة تحميل البيانات إذا تم إجراء تغيير
      if (result == true && mounted) {
        setState(() {});
      }
    });
  }

  void _cancelAppointment(Appointment appointment) async {
    // التحقق من الحالة
    if (appointment.status != 'PENDING_CONFIRM' && 
        appointment.status != 'CONFIRMED' &&
        appointment.status != 'PENDING') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إلغاء موعد بهذه الحالة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // التحقق من المهلة (24 ساعة)
    final now = DateTime.now();
    final hoursUntil = appointment.startAt.difference(now).inHours;
    if (hoursUntil <= 24) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إلغاء الموعد قبل أقل من 24 ساعة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الموعد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'سبب الإلغاء (اختياري)',
                  hintText: 'مثال: تغير في الخطط',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('رجوع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);

        final token = await _authService.getToken();
        await _apiService.cancelAppointment(
          appointmentId: appointment.id,
          reason: reasonController.text.isNotEmpty 
              ? reasonController.text 
              : null,
          token: token,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _appointmentsFuture = _fetchAppointments();
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الموعد بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _rescheduleAppointment(Appointment appointment) async {
    // التحقق من الحالة
    if (appointment.status != 'PENDING_CONFIRM' && 
        appointment.status != 'CONFIRMED' &&
        appointment.status != 'PENDING') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إعادة جدولة موعد بهذه الحالة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // التحقق من المهلة (24 ساعة)
    final now = DateTime.now();
    final hoursUntil = appointment.startAt.difference(now).inHours;
    if (hoursUntil <= 24) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إعادة جدولة الموعد قبل أقل من 24 ساعة'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // اختيار التاريخ الجديد
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: appointment.startAt.add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
      helpText: 'اختر تاريخاً جديداً',
    );

    if (selectedDate == null || !mounted) return;

    // اختيار الوقت الجديد
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.startAt),
      helpText: 'اختر وقتاً جديداً',
    );

    if (selectedTime == null || !mounted) return;

    final newStartAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // التأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إعادة جدولة الموعد'),
          content: Text(
            'هل تريد تغيير الموعد إلى:\n'
            '${_formatDate(newStartAt)}\n'
            '${_formatTime(newStartAt)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('رجوع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);

        final token = await _authService.getToken();
        await _apiService.rescheduleAppointment(
          appointmentId: appointment.id,
          newStartAt: newStartAt,
          token: token,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _appointmentsFuture = _fetchAppointments();
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة جدولة الموعد بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
