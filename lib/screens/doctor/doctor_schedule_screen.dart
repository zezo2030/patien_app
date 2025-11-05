import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/text_styles.dart';
import '../../config/colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _schedule;
  late List<_DayItem> _days = List.generate(7, (i) => _DayItem(dayOfWeek: i));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authService.getToken() ?? '';
      final data = await _apiService.getDoctorSchedule(token: token);
      setState(() {
        _schedule = data;
        _loading = false;
        _initEditorFromSchedule();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.bodyLarge))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_isEmptySchedule()) ...[
                        _buildSectionHeader('الجدول الأسبوعي', Iconsax.calendar_1),
                        const SizedBox(height: 12),
                        _buildEmptyBox('لا يوجد جدول بعد'),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: AppColors.gradientSecondary,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _createDefaultSchedule,
                            icon: const Icon(Iconsax.add_circle, size: 22),
                            label: const Text(
                              'إنشاء جدول افتراضي',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('محرر الجدول', Iconsax.edit),
                      const SizedBox(height: 12),
                      _buildScheduleEditor(),
                      const SizedBox(height: 16),
                      _buildSaveRow(),
                    ] else ...[
                        _buildSectionHeader('الجدول الأسبوعي', Iconsax.calendar_1),
                        const SizedBox(height: 12),
                        _buildSchedulePreview(),
                        const SizedBox(height: 24),
                      _buildSectionHeader('محرر الجدول', Iconsax.edit),
                      const SizedBox(height: 12),
                      _buildScheduleEditor(),
                      const SizedBox(height: 16),
                      _buildSaveRow(),
                      const SizedBox(height: 24),
                        _buildSectionHeader('الاستثناءات', Iconsax.close_square),
                        const SizedBox(height: 12),
                        _buildEmptyBox('لا توجد استثناءات'),
                        const SizedBox(height: 24),
                        _buildSectionHeader('العطلات', Iconsax.sun_1),
                        const SizedBox(height: 12),
                        _buildEmptyBox('لا توجد عطلات'),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showAddExceptionDialog,
                                icon: const Icon(Iconsax.minus_cirlce, size: 20),
                                label: const Text('إضافة استثناء'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.warning,
                                  side: const BorderSide(color: AppColors.warning, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showAddHolidayDialog,
                                icon: const Icon(Iconsax.sun_1, size: 20),
                                label: const Text('إضافة عطلة'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.info,
                                  side: const BorderSide(color: AppColors.info, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: AppColors.gradientPrimary,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headline2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePreview() {
    if (_schedule == null || _schedule!['weeklyTemplate'] == null) {
      return _buildEmptyBox('لا يوجد جدول بعد');
    }
    
    final weekly = (_schedule!['weeklyTemplate'] as List?) ?? [];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: AppColors.gradientPrimary,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.calendar_2,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'جدول العمل الأسبوعي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${weekly.length} أيام',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Days Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(7, (i) {
                final dayData = weekly.firstWhere(
                  (d) => d['dayOfWeek'] == i,
                  orElse: () => null,
                );
                final isAvailable = dayData?['isAvailable'] == true;
                final slots = (dayData?['slots'] as List?) ?? [];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable 
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isAvailable 
                            ? AppColors.success
                            : AppColors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          isAvailable ? Iconsax.tick_circle : Iconsax.close_circle,
                          color: isAvailable 
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      _dayName(i),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAvailable 
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: isAvailable && slots.isNotEmpty
                        ? Text(
                            slots.map((s) => '${s['startTime']} - ${s['endTime']}').join(' • '),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            'يوم عطلة',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                    trailing: isAvailable
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${slots.length} فترة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.background,
          ],
        ),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Iconsax.calendar_search,
              size: 48,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isEmptySchedule() {
    final weekly = (_schedule?['weeklyTemplate'] as List?) ?? [];
    return weekly.isEmpty;
  }

  void _initEditorFromSchedule() {
    final weekly = (_schedule?['weeklyTemplate'] as List?) ?? [];
    // default days
    _days = List.generate(7, (i) => _DayItem(dayOfWeek: i));
    for (final item in weekly) {
      final d = int.tryParse('${item['dayOfWeek']}') ?? 0;
      final isAvailable = item['isAvailable'] == true;
      final slotsList = (item['slots'] as List?) ?? [];
      final slots = slotsList.map((s) => _DaySlot(
        startTime: '${s['startTime']}',
        endTime: '${s['endTime']}',
      )).toList();
      _days[d] = _DayItem(dayOfWeek: d, isAvailable: isAvailable, slots: slots);
    }
  }

  Widget _buildScheduleEditor() {
    return Column(
      children: List.generate(7, (i) {
        final day = _days[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: day.isAvailable 
                ? LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.success.withOpacity(0.05),
                      AppColors.info.withOpacity(0.05),
                    ],
                  )
                : null,
            color: day.isAvailable ? null : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: day.isAvailable 
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.border,
              width: 1.5,
            ),
            boxShadow: day.isAvailable ? [
              BoxShadow(
                color: AppColors.success.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: day.isAvailable 
                            ? AppColors.success
                            : AppColors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        day.isAvailable ? Iconsax.calendar_tick : Iconsax.calendar,
                        color: day.isAvailable 
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dayName(day.dayOfWeek),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: day.isAvailable 
                            ? AppColors.success.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Switch(
                        value: day.isAvailable,
                        activeColor: AppColors.success,
                        onChanged: (v) => setState(() {
                          day.isAvailable = v;
                          if (v && day.slots.isEmpty) {
                            day.slots.add(_DaySlot(startTime: '09:00', endTime: '17:00'));
                          }
                        }),
                      ),
                    ),
                  ],
                ),
                if (day.isAvailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الفترات الزمنية',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${day.slots.length}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (int si = 0; si < day.slots.length; si++)
                          _buildSlotRow(day, si),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              day.slots.add(_DaySlot(startTime: '09:00', endTime: '17:00'));
                            }),
                            icon: const Icon(Iconsax.add_circle, size: 20),
                            label: const Text('إضافة فترة جديدة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
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
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlotRow(_DayItem day, int si) {
    final slot = day.slots[si];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Start Time
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await _pickTime(slot.startTime);
                if (picked != null) setState(() => slot.startTime = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slot.startTime,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Iconsax.arrow_left,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          // End Time
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await _pickTime(slot.endTime);
                if (picked != null) setState(() => slot.endTime = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slot.endTime,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          InkWell(
            onTap: () => setState(() {
              day.slots.removeAt(si);
            }),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.trash,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickTime(String initial) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final res = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.ltr, child: child!);
      },
    );
    if (res == null) return null;
    return _fmt2(res.hour) + ':' + _fmt2(res.minute);
  }

  String _fmt2(int v) => v.toString().padLeft(2, '0');

  String _dayName(int d) {
    const names = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
    return names[d % 7];
  }

  Widget _buildSaveRow() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: AppColors.gradientPrimary,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _saveSchedule,
        icon: const Icon(Iconsax.tick_circle, size: 22),
        label: const Text(
          'حفظ الجدول',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSchedule() async {
    // Build weeklyTemplate
    final weekly = <Map<String, dynamic>>[];
    for (final d in _days) {
      if (d.isAvailable && d.slots.isNotEmpty) {
        final validSlots = d.slots.where((s) => _isValidSlot(s)).map((s) => {
          'startTime': s.startTime,
          'endTime': s.endTime,
        }).toList();
        if (validSlots.isNotEmpty) {
          weekly.add({
            'dayOfWeek': d.dayOfWeek,
            'isAvailable': true,
            'slots': validSlots,
          });
        }
      }
    }
    if (weekly.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد فترات العمل قبل الحفظ')),
      );
      return;
    }
    try {
      final token = await _authService.getToken() ?? '';
      await _apiService.createOrUpdateSchedule(
        scheduleData: {
          'weeklyTemplate': weekly,
          'defaultBufferBefore': 5,
          'defaultBufferAfter': 5,
        },
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الجدول')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الجدول: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  bool _isValidSlot(_DaySlot s) {
    int toMin(String t) {
      final p = t.split(':');
      return (int.tryParse(p.first) ?? 0) * 60 + (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
    }
    return toMin(s.endTime) > toMin(s.startTime);
  }

  Future<void> _createDefaultSchedule() async {
    try {
      final token = await _authService.getToken() ?? '';

      final scheduleData = {
        'weeklyTemplate': [
          {'dayOfWeek': 0, 'isAvailable': true, 'slots': [{'startTime': '09:00', 'endTime': '17:00'}]},
          {'dayOfWeek': 1, 'isAvailable': true, 'slots': [{'startTime': '09:00', 'endTime': '17:00'}]},
          {'dayOfWeek': 2, 'isAvailable': true, 'slots': [{'startTime': '09:00', 'endTime': '17:00'}]},
          {'dayOfWeek': 3, 'isAvailable': true, 'slots': [{'startTime': '09:00', 'endTime': '17:00'}]},
          {'dayOfWeek': 4, 'isAvailable': true, 'slots': [{'startTime': '09:00', 'endTime': '17:00'}]},
        ],
        'defaultBufferBefore': 5,
        'defaultBufferAfter': 5,
      };

      await _apiService.createOrUpdateSchedule(
        scheduleData: scheduleData,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الجدول بنجاح')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء الجدول: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _showAddExceptionDialog() async {
    final dateController = TextEditingController();
    bool isAvailable = false;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة استثناء'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(hintText: 'التاريخ (YYYY-MM-DD)'),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('متاح في هذا اليوم'),
                  const Spacer(),
                  Switch(
                    value: isAvailable,
                    onChanged: (v) {
                      isAvailable = v;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(hintText: 'السبب (اختياري)'),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final token = await _authService.getToken() ?? '';
        await _apiService.addScheduleException(
          date: dateController.text.trim(),
          isAvailable: isAvailable,
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          token: token,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الاستثناء')),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إضافة الاستثناء: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    }
  }

  Future<void> _showAddHolidayDialog() async {
    final startController = TextFieldControllerPair();
    final endController = TextFieldControllerPair();
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة عطلة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController.controller,
                decoration: const InputDecoration(hintText: 'تاريخ البداية (YYYY-MM-DD)'),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: endController.controller,
                decoration: const InputDecoration(hintText: 'تاريخ النهاية (YYYY-MM-DD)'),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(hintText: 'السبب (اختياري)'),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final token = await _authService.getToken() ?? '';
        await _apiService.addHoliday(
          startDate: startController.controller.text.trim(),
          endDate: endController.controller.text.trim(),
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          token: token,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة العطلة')),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إضافة العطلة: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    }
  }
}

class TextFieldControllerPair {
  final TextEditingController controller = TextEditingController();
}



class _DaySlot {
  String startTime;
  String endTime;
  _DaySlot({required this.startTime, required this.endTime});
}

class _DayItem {
  final int dayOfWeek;
  bool isAvailable;
  List<_DaySlot> slots;
  _DayItem({required this.dayOfWeek, this.isAvailable = false, List<_DaySlot>? slots})
      : slots = slots ?? <_DaySlot>[];
}
