import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../models/medical_record.dart';

class MedicalRecordDetailsScreen extends StatelessWidget {
  final MedicalRecord record;

  const MedicalRecordDetailsScreen({
    super.key,
    required this.record,
  });

  String _getArabicMonth(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _getArabicMonth(dateTime.month);
    final year = dateTime.year;
    return '$day $month $year';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$date - $displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = record.doctor?.name ?? 'طبيب غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'تفاصيل السجل الطبي',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة معلومات الطبيب
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.15),
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
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.info,
                              AppColors.info.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.user,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'د. $doctorName',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة التاريخ
              _buildInfoCard(
                icon: Iconsax.calendar_1,
                title: 'تاريخ الزيارة',
                value: _formatDateTime(record.createdAt),
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // بطاقة التشخيص
              _buildInfoCard(
                icon: Iconsax.health,
                title: 'التشخيص',
                value: record.diagnosis,
                color: AppColors.info,
                isLarge: true,
              ),
              const SizedBox(height: 16),

              // بطاقة الوصفة الطبية
              if (record.prescription != null && record.prescription!.isNotEmpty)
                _buildInfoCard(
                  icon: Iconsax.document_text,
                  title: 'الوصفة الطبية',
                  value: record.prescription!,
                  color: AppColors.success,
                  isLarge: true,
                ),
              if (record.prescription != null && record.prescription!.isNotEmpty)
                const SizedBox(height: 16),

              // بطاقة العلامات الحيوية
              if (record.vitalSigns != null) ...[
                _buildVitalSignsCard(record.vitalSigns!),
                const SizedBox(height: 16),
              ],

              // بطاقة الملاحظات
              if (record.notes != null && record.notes!.isNotEmpty)
                _buildInfoCard(
                  icon: Iconsax.note_text,
                  title: 'ملاحظات',
                  value: record.notes!,
                  color: AppColors.accent,
                  isLarge: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: isLarge
                  ? AppTextStyles.bodyLarge.copyWith(
                      fontSize: 15,
                      height: 1.6,
                    )
                  : AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard(VitalSigns vitalSigns) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.heart,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'العلامات الحيوية',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (vitalSigns.bloodPressure != null)
                  _buildVitalSignItem(
                    'ضغط الدم',
                    '${vitalSigns.bloodPressure}',
                    'mmHg',
                    Iconsax.heart,
                  ),
                if (vitalSigns.heartRate != null)
                  _buildVitalSignItem(
                    'معدل النبض',
                    '${vitalSigns.heartRate}',
                    'bpm',
                    Iconsax.heart_circle,
                  ),
                if (vitalSigns.temperature != null)
                  _buildVitalSignItem(
                    'درجة الحرارة',
                    '${vitalSigns.temperature}',
                    '°C',
                    Iconsax.sun_1,
                  ),
                if (vitalSigns.weight != null)
                  _buildVitalSignItem(
                    'الوزن',
                    '${vitalSigns.weight}',
                    'kg',
                    Iconsax.weight_1,
                  ),
                if (vitalSigns.height != null)
                  _buildVitalSignItem(
                    'الطول',
                    '${vitalSigns.height}',
                    'cm',
                    Iconsax.rulerpen,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignItem(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

