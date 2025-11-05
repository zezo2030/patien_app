import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/test_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../video_call/video_call_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  bool _isLoading = false;
  Doctor? _doctor;

  @override
  void initState() {
    super.initState();
    _ensureDoctorLoaded();
  }

  Future<void> _ensureDoctorLoaded() async {
    // إذا لم تأتِ بيانات الطبيب ضمن الموعد، اجلبها من السيرفر
    if (widget.appointment.doctor == null && widget.appointment.doctorId.isNotEmpty) {
      try {
        final token = await _authService.getToken();
        if (token == null) return;
        final doctor = await _apiService.getDoctorById(
          doctorId: widget.appointment.doctorId,
          token: token,
        );
        if (mounted) {
          setState(() {
            _doctor = doctor;
          });
        }
      } catch (_) {
        // تجاهل الخطأ ونبقي الاسم غير محدد إذا فشل
      }
    }
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

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _getArabicMonth(dateTime.month);
    final year = dateTime.year;
    final weekday = _getArabicWeekday(dateTime.weekday);
    return '$weekday، $day $month $year';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_CONFIRM':
      case 'PENDING':
        return 'في انتظار التأكيد';
      case 'CONFIRMED':
        return 'مؤكد';
      case 'CANCELLED':
        return 'ملغى';
      case 'COMPLETED':
        return 'مكتمل';
      case 'NO_SHOW':
        return 'لم يحضر';
      case 'REJECTED':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING_CONFIRM':
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.success;
      case 'NO_SHOW':
        return AppColors.error;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'IN_PERSON':
        return 'حضور شخصي';
      case 'VIDEO':
        return 'مكالمة فيديو';
      case 'CHAT':
        return 'محادثة نصية';
      default:
        return type;
    }
  }

  bool _canCancel() {
    final status = widget.appointment.status;
    if (status != 'PENDING_CONFIRM' && 
        status != 'CONFIRMED' &&
        status != 'PENDING') {
      return false;
    }

    final now = DateTime.now();
    final hoursUntil = widget.appointment.startAt.difference(now).inHours;
    return hoursUntil > 24;
  }

  bool _canReschedule() {
    final status = widget.appointment.status;
    if (status != 'PENDING_CONFIRM' && 
        status != 'CONFIRMED' &&
        status != 'PENDING') {
      return false;
    }

    final now = DateTime.now();
    final hoursUntil = widget.appointment.startAt.difference(now).inHours;
    return hoursUntil > 24;
  }

  bool _canStartVideoCall() {
    // Check if appointment type is VIDEO
    if (widget.appointment.type != 'VIDEO') {
      return false;
    }

    // Check if appointment is confirmed
    if (widget.appointment.status != 'CONFIRMED') {
      return false;
    }

    // في وضع الاختبار: تجاوز التحقق من الدفع والوقت
    if (TestConfig.shouldBypassPayment) {
      // في وضع الاختبار، نسمح ببدء المكالمة في أي وقت (للمواعيد المؤكدة)
      return true;
    }

    // في الوضع العادي: التحقق من الدفع إذا كان مطلوباً
    if (widget.appointment.requiresPayment == true) {
      // التحقق من حالة الدفع
      if (widget.appointment.paymentStatus != 'PAID' && 
          widget.appointment.paymentStatus != 'COMPLETED') {
        return false;
      }
    }

    final now = DateTime.now();
    final appointmentStart = widget.appointment.startAt;
    final appointmentEnd = widget.appointment.endAt;

    // Check if time is within valid range (T-10 minutes to end)
    final minutesUntilStart = appointmentStart.difference(now).inMinutes;
    final isAfterEnd = now.isAfter(appointmentEnd);

    // Can start if: within 10 minutes before start OR after start but before end
    return (minutesUntilStart <= 10 && !isAfterEnd);
  }

  void _startVideoCall() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Determine role
      final role = user.role == 'DOCTOR' ? 'doctor' : 'patient';

      // Navigate to video call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              appointmentId: widget.appointment.id,
              role: role,
              doctorName: widget.appointment.doctor?.name ?? _doctor?.name,
              patientName: user.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _cancelAppointment() async {
    if (!_canCancel()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إلغاء هذا الموعد'),
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
          appointmentId: widget.appointment.id,
          reason: reasonController.text.isNotEmpty 
              ? reasonController.text 
              : null,
          token: token,
        );

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الموعد بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
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

  void _rescheduleAppointment() async {
    if (!_canReschedule()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إعادة جدولة هذا الموعد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.appointment.startAt.add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
      helpText: 'اختر تاريخاً جديداً',
    );

    if (selectedDate == null || !mounted) return;

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.appointment.startAt),
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
          appointmentId: widget.appointment.id,
          newStartAt: newStartAt,
          token: token,
        );

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة جدولة الموعد بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final statusColor = _getStatusColor(appointment.status);
    final doctorName = appointment.doctor?.name ?? _doctor?.name ?? 'طبيب غير محدد';
    final serviceName = appointment.service?.name ?? 'خدمة غير محددة';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('تفاصيل الموعد'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.1),
                              statusColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.calendar_tick,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الحالة',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusLabel(appointment.status),
                                    style: AppTextStyles.headline3.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Doctor & Service Info
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: AppColors.gradientPrimary,
                                    ),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الطبيب',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'د. $doctorName',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.health,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الخدمة / التخصص',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        serviceName,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.calendar_1,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'التاريخ',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(appointment.startAt),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  color: AppColors.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الوقت',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatTime(appointment.startAt)} - ${_formatTime(appointment.endAt)}',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointment Type
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              appointment.type == 'VIDEO'
                                  ? Iconsax.video
                                  : appointment.type == 'CHAT'
                                      ? Iconsax.message
                                      : Iconsax.location,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نوع الموعد',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTypeLabel(appointment.type),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Price
                    if (appointment.price != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.money,
                                color: AppColors.success,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'السعر',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${appointment.price} ريال',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (appointment.paymentStatus != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: appointment.paymentStatus == 'PAID'
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    appointment.paymentStatus == 'PAID'
                                        ? 'مدفوع'
                                        : 'غير مدفوع',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: appointment.paymentStatus == 'PAID'
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Cancellation Info
                    if (appointment.status == 'CANCELLED' && appointment.cancellationReason != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: AppColors.error.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.info_circle,
                                    color: AppColors.error,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'سبب الإلغاء',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                appointment.cancellationReason!,
                                style: AppTextStyles.bodyMedium,
                              ),
                              if (appointment.cancelledAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'تم الإلغاء في: ${_formatDate(appointment.cancelledAt!)} ${_formatTime(appointment.cancelledAt!)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Notes
                    if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.document_text,
                                    color: AppColors.info,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'ملاحظات',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                appointment.notes!,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Video Call Button
                    if (_canStartVideoCall()) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _startVideoCall,
                          icon: const Icon(Iconsax.video, size: 24),
                          label: const Text(
                            'بدء مكالمة الفيديو',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],

                    // Action Buttons
                    if (_canCancel() || _canReschedule()) ...[
                      const SizedBox(height: 24),
                      if (_canCancel())
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _cancelAppointment,
                            icon: const Icon(Iconsax.close_square, size: 20),
                            label: const Text('إلغاء الموعد'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_canCancel() && _canReschedule())
                        const SizedBox(height: 12),
                      if (_canReschedule())
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _rescheduleAppointment,
                            icon: const Icon(Iconsax.refresh, size: 20),
                            label: const Text('إعادة جدولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

