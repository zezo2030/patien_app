import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/test_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../doctors/doctors_screen.dart';
import '../video_call/video_call_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  final String? doctorName;
  final String serviceId;
  final String? serviceName;

  const BookAppointmentScreen({
    super.key,
    required this.doctorId,
    this.doctorName,
    required this.serviceId,
    this.serviceName,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();

  DateTime? _selectedDate;
  String _selectedType = 'IN_PERSON';
  bool _isLoading = false;
  bool _loadingAvailability = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableSlots = [];
  DateTime? _selectedSlotStartAt;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    if (widget.doctorId.isEmpty || widget.serviceId.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _loadingAvailability = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final weekStartIso = _computeWeekStartSundayUtcIso(_selectedDate ?? DateTime.now());
      final availability = await _apiService.getDoctorAvailability(
        doctorId: widget.doctorId,
        serviceId: widget.serviceId,
        weekStart: weekStartIso,
        token: token,
      );
      final slots = List<Map<String, dynamic>>.from(availability['availableSlots'] ?? []);

      if (mounted) {
        setState(() {
          _loadingAvailability = false;
          _availableSlots = slots;
          // إذا تغيّر التاريخ، ولا يوجد اختيار سابق ضمن اليوم، أزل الاختيار
          if (_selectedSlotStartAt != null && !_isSameDay(_selectedSlotStartAt!, _selectedDate)) {
            _selectedSlotStartAt = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAvailability = false;
          // لا نعرض الخطأ لأن API قد لا يكون متوفراً
        });
      }
    }
  }

  String _computeWeekStartSundayUtcIso(DateTime date) {
    final dUtc = DateTime.utc(date.year, date.month, date.day);
    final weekday = dUtc.weekday; // 1=Mon..7=Sun
    final daysToSubtract = weekday % 7; // Sunday => 0
    final weekStart = dUtc.subtract(Duration(days: daysToSubtract));
    final weekStartMidnightUtc = DateTime.utc(weekStart.year, weekStart.month, weekStart.day, 0, 0, 0);
    return weekStartMidnightUtc.toIso8601String();
  }

  bool _isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    final al = a.toLocal();
    final bl = DateTime(b.year, b.month, b.day);
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  String _formatHm(DateTime dt) {
    final l = dt.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _bookAppointment() async {
    await _bookAppointmentWithConfirmation(confirmImmediately: false);
  }

  Future<void> _bookConfirmedAppointment() async {
    await _bookAppointmentWithConfirmation(confirmImmediately: true);
  }

  Future<void> _bookAppointmentWithConfirmation({required bool confirmImmediately}) async {
    // التحقق من أن الطبيب محدد
    if (widget.doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الطبيب أولاً'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // التحقق من أن الخدمة محددة
    if (widget.serviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الخدمة أولاً'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedDate == null || _selectedSlotStartAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار التاريخ وفتحة زمنية متاحة'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final startAt = _selectedSlotStartAt!; // قيمة من السيرفر (ISO UTC)
    final nowUtc = DateTime.now().toUtc();

    // التحقق من أن الوقت في المستقبل
    if (startAt.isBefore(nowUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار وقت في المستقبل'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // في وضع الاختبار: السماح بالحجز بعد 10 دقائق فقط
    if (TestConfig.shouldAllowQuickBooking) {
      final minutesUntilStart = startAt.difference(nowUtc).inMinutes;
      if (minutesUntilStart < TestConfig.minimumMinutesBeforeAppointment) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يرجى اختيار وقت بعد ${TestConfig.minimumMinutesBeforeAppointment} دقائق على الأقل من الآن',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      // في الوضع العادي: يجب أن يكون الموعد بعد 24 ساعة على الأقل
      final hoursUntilStart = startAt.difference(nowUtc).inHours;
      if (hoursUntilStart < 24) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب حجز الموعد قبل 24 ساعة على الأقل'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      // إنشاء idempotency key لمنع الحجز المكرر
      final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${widget.doctorId}';

      var appointment = await _apiService.createAppointment(
        doctorId: widget.doctorId,
        serviceId: widget.serviceId,
        startAt: startAt,
        type: _selectedType,
        idempotencyKey: idempotencyKey,
        token: token,
      );

      // في وضع الاختبار: تأكيد الموعد مباشرة إذا طُلب ذلك
      // ملاحظة: التأكيد يتطلب صلاحيات طبيب، لذا نتحقق من الدور أولاً
      bool appointmentConfirmed = false;
      if (confirmImmediately && TestConfig.isTestModeEnabled) {
        try {
          final user = await _authService.getCurrentUser();
          if (user?.role == 'DOCTOR') {
            // المستخدم طبيب، يمكنه تأكيد الموعد
            final confirmedAppointment = await _apiService.confirmAppointment(
              appointmentId: appointment.id,
              token: token,
            );
            appointmentConfirmed = true;
            appointment = confirmedAppointment; // تحديث الموعد المؤكد
          } else {
            // المستخدم مريض، لا يمكنه تأكيد الموعد
            // نعرض رسالة توضيحية
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⚠️ تم الحجز بنجاح. يرجى تسجيل الدخول كطبيب لتأكيد الموعد تلقائياً، أو سيتم تأكيده يدوياً من قبل الطبيب.',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        } catch (e) {
          // إذا فشل التأكيد، نعرض رسالة لكن نعتبر الحجز ناجح
          print('⚠️ فشل تأكيد الموعد تلقائياً: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم الحجز بنجاح، لكن فشل التأكيد التلقائي: ${e.toString().replaceAll('Exception: ', '')}',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        // عرض رسالة النجاح المناسبة
        String successMessage = 'تم حجز الموعد بنجاح';
        if (confirmImmediately) {
          final user = await _authService.getCurrentUser();
          if (user?.role == 'DOCTOR') {
            successMessage = 'تم حجز وتأكيد الموعد بنجاح ✓';
          } else {
            successMessage = 'تم حجز الموعد بنجاح. سيتم تأكيده من قبل الطبيب.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // في وضع الاختبار: إذا كان الموعد مؤكد ومن نوع VIDEO، الانتقال مباشرة إلى مكالمة الفيديو
        if (TestConfig.isTestModeEnabled && 
            appointmentConfirmed && 
            _selectedType == 'VIDEO' && 
            appointment.status == 'CONFIRMED') {
          
          final user = await _authService.getCurrentUser();
          if (user != null) {
            // إغلاق شاشة الحجز أولاً
            Navigator.pop(context, true);
            
            // الانتقال مباشرة إلى مكالمة الفيديو
            await Future.delayed(const Duration(milliseconds: 500)); // تأخير بسيط للسماح بإغلاق الشاشة
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    appointmentId: appointment.id,
                    role: user.role == 'DOCTOR' ? 'doctor' : 'patient',
                    doctorName: widget.doctorName,
                    patientName: user.name,
                  ),
                ),
              );
            }
          } else {
            Navigator.pop(context, true);
          }
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $_errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.task_square,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'نوع الموعد',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    'IN_PERSON',
                    'حضور شخصي',
                    Iconsax.location,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeOption(
                    'VIDEO',
                    'مكالمة فيديو',
                    Iconsax.video,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeOption(
                    'CHAT',
                    'محادثة نصية',
                    Iconsax.message,
                    AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : AppColors.background,
          border: Border.all(
            color: isSelected ? color : AppColors.border.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.calendar_1,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'التاريخ',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
              onPressed: () async {
                // في وضع الاختبار: السماح بالحجز بعد 10 دقائق
                // في الوضع العادي: يجب أن يكون بعد 24 ساعة
                final minDate = TestConfig.shouldAllowQuickBooking
                    ? DateTime.now()
                    : DateTime.now().add(const Duration(days: 1));
                
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? minDate,
                  firstDate: minDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ar', 'SA'),
                  helpText: 'اختر تاريخ الموعد',
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadAvailability();
                }
              },
                icon: const Icon(Iconsax.calendar_1, size: 22),
                label: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'اختر التاريخ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.clock,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'اختر وقتاً من الفتحات المتاحة',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingAvailability) ...[
              const SizedBox(height: 8),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else ...[
              Builder(builder: (_) {
                final slotsForDay = _availableSlots.where((slot) {
                  final iso = slot['startTime'] as String?;
                  if (iso == null) return false;
                  final dt = DateTime.tryParse(iso);
                  if (dt == null) return false;
                  return _isSameDay(dt, _selectedDate);
                }).toList();

                if (slotsForDay.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.4)),
                    ),
                    child: Text(
                      'لا توجد فتحات متاحة في هذا اليوم. الرجاء اختيار تاريخ آخر.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final slot in slotsForDay)
                      _SlotChip(
                        label: _formatHm(DateTime.parse(slot['startTime'] as String)),
                        selected: _selectedSlotStartAt != null &&
                            _selectedSlotStartAt!.toUtc().toIso8601String() ==
                                DateTime.parse(slot['startTime'] as String).toUtc().toIso8601String(),
                        onTap: () {
                          final dt = DateTime.parse(slot['startTime'] as String).toUtc();
                          setState(() {
                            _selectedSlotStartAt = dt;
                          });
                        },
                      ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('حجز موعد جديد'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor & Service Info
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Warning if doctor not selected
                            if (widget.doctorId.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.warning.withOpacity(0.15),
                                      AppColors.warning.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.warning.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Iconsax.info_circle,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'يرجى اختيار الطبيب أولاً قبل الحجز',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientPrimary,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorsScreen(
                                          departmentId: null,
                                          serviceId: widget.serviceId.isNotEmpty
                                              ? widget.serviceId
                                              : null,
                                          serviceName: widget.serviceName,
                                        ),
                                      ),
                                    );
                                    if (result != null && result is Map<String, dynamic>) {
                                      // إعادة بناء الشاشة مع بيانات الطبيب الجديد
                                      if (mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookAppointmentScreen(
                                              doctorId: result['doctorId'] ?? '',
                                              doctorName: result['doctorName'],
                                              serviceId: widget.serviceId,
                                              serviceName: widget.serviceName,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Iconsax.user_search, size: 20),
                                  label: const Text(
                                    'اختر طبيب',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: AppColors.gradientPrimary,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      (widget.doctorName ?? 'ط')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 28,
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
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.user_tick,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'الطبيب',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.doctorName != null
                                            ? 'د. ${widget.doctorName}'
                                            : 'طبيب غير محدد',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: widget.doctorId.isEmpty
                                              ? AppColors.error
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Change doctor button
                                if (widget.doctorId.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Iconsax.edit,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      tooltip: 'تغيير الطبيب',
                                      onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DoctorsScreen(
                                            departmentId: null,
                                            serviceId: widget.serviceId.isNotEmpty
                                                ? widget.serviceId
                                                : null,
                                            serviceName: widget.serviceName,
                                          ),
                                        ),
                                      );
                                      if (result != null && result is Map<String, dynamic>) {
                                        // إعادة بناء الشاشة مع بيانات الطبيب الجديد
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BookAppointmentScreen(
                                                doctorId: result['doctorId'] ?? '',
                                                doctorName: result['doctorName'],
                                                serviceId: widget.serviceId,
                                                serviceName: widget.serviceName,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.serviceName != null) ...[
                              const Divider(height: 32, thickness: 1.5),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.08),
                                      AppColors.primary.withOpacity(0.03),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: AppColors.gradientPrimary,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.health,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الخدمة / التخصص',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.serviceName!,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Selector
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildTypeSelector(),
                    ),
                    const SizedBox(height: 16),

                    // Date Selector
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildDateSelector(),
                    ),
                    const SizedBox(height: 16),

                    // Time Selector
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildTimeSelector(),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error.withOpacity(0.15),
                              AppColors.error.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.info_circle,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 16),
                    ],

                    // Book Buttons
                    Column(
                      children: [
                        // زر الحجز العادي
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                ? null
                                : const LinearGradient(
                                    colors: AppColors.gradientPrimary,
                                  ),
                            color: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                ? AppColors.textSecondary.withOpacity(0.5)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: (_isLoading || widget.doctorId.isEmpty || _selectedSlotStartAt == null) 
                                ? null 
                                : _bookAppointment,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Iconsax.calendar_add, size: 24),
                            label: Text(
                              _isLoading
                                  ? 'جاري الحجز...'
                                  : widget.doctorId.isEmpty 
                                      ? 'يرجى اختيار الطبيب أولاً'
                                      : _selectedSlotStartAt == null
                                          ? 'اختر وقتاً متاحاً'
                                          : 'حجز الموعد',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withOpacity(0.7),
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        ),
                        
                        // زر الحجز المؤكد للاختبار (يظهر فقط في وضع الاختبار)
                        if (TestConfig.isTestModeEnabled) ...[
                          const SizedBox(height: 12),
                          FutureBuilder(
                            future: _authService.getCurrentUser(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              final isDoctor = user?.role == 'DOCTOR';
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDoctor 
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDoctor
                                        ? AppColors.success.withOpacity(0.3)
                                        : AppColors.warning.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDoctor ? Iconsax.tick_circle : Iconsax.info_circle,
                                      color: isDoctor ? AppColors.success : AppColors.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isDoctor
                                            ? 'وضع الاختبار: حجز مؤكد مباشرة (كطبيب)'
                                            : 'وضع الاختبار: الحجز سيحتاج تأكيد من الطبيب',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: isDoctor ? AppColors.success : AppColors.warning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        AppColors.success,
                                        AppColors.success.withOpacity(0.8),
                                      ],
                                    ),
                              color: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                  ? AppColors.textSecondary.withOpacity(0.5)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: widget.doctorId.isEmpty || _isLoading || _selectedSlotStartAt == null
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.success.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: (_isLoading || widget.doctorId.isEmpty || _selectedSlotStartAt == null) 
                                  ? null 
                                  : _bookConfirmedAppointment,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Iconsax.tick_circle, size: 24),
                              label: Text(
                                _isLoading
                                    ? 'جاري الحجز والتأكيد...'
                                    : widget.doctorId.isEmpty 
                                        ? 'يرجى اختيار الطبيب أولاً'
                                        : _selectedSlotStartAt == null
                                            ? 'اختر وقتاً متاحاً'
                                            : 'حجز مؤكد للاختبار ✓',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white.withOpacity(0.7),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}


class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? const LinearGradient(colors: AppColors.gradientPrimary)
              : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border.withOpacity(0.4),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

