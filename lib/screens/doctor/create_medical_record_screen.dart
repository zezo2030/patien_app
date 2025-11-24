import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';

class CreateMedicalRecordScreen extends StatefulWidget {
  final Appointment appointment;

  const CreateMedicalRecordScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<CreateMedicalRecordScreen> createState() => _CreateMedicalRecordScreenState();
}

class _CreateMedicalRecordScreenState extends State<CreateMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _authService = AuthService();

  // Controllers
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Vital Signs Controllers
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  bool _isLoading = false;
  bool _showVitalSigns = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      // بناء VitalSigns إذا كانت هناك بيانات
      VitalSigns? vitalSigns;
      if (_showVitalSigns &&
          (_bloodPressureController.text.isNotEmpty ||
              _heartRateController.text.isNotEmpty ||
              _temperatureController.text.isNotEmpty ||
              _weightController.text.isNotEmpty ||
              _heightController.text.isNotEmpty)) {
        vitalSigns = VitalSigns(
          bloodPressure: _bloodPressureController.text.isNotEmpty
              ? double.tryParse(_bloodPressureController.text)
              : null,
          heartRate: _heartRateController.text.isNotEmpty
              ? double.tryParse(_heartRateController.text)
              : null,
          temperature: _temperatureController.text.isNotEmpty
              ? double.tryParse(_temperatureController.text)
              : null,
          weight: _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
          height: _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null,
        );
      }

      await _apiService.createMedicalRecord(
        appointmentId: widget.appointment.id,
        diagnosis: _diagnosisController.text.trim(),
        prescription: _prescriptionController.text.trim().isNotEmpty
            ? _prescriptionController.text.trim()
            : null,
        vitalSigns: vitalSigns,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء السجل الطبي بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى نجاح الإنشاء
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          title: Text(
            'إنشاء سجل طبي',
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
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات الموعد
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.calendar_1, color: AppColors.info, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'معلومات الموعد',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'المريض: ${widget.appointment.patientId}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'التاريخ: ${_formatDate(widget.appointment.startAt)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // التشخيص (مطلوب)
                Text(
                  'التشخيص *',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(
                    hintText: 'أدخل التشخيص',
                    prefixIcon: Icon(Iconsax.health, color: AppColors.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال التشخيص';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // الوصفة الطبية
                Text(
                  'الوصفة الطبية',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _prescriptionController,
                  decoration: InputDecoration(
                    hintText: 'أدخل الوصفة الطبية',
                    prefixIcon: Icon(Iconsax.document_text, color: AppColors.success),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                // العلامات الحيوية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'العلامات الحيوية',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _showVitalSigns,
                      onChanged: (value) {
                        setState(() {
                          _showVitalSigns = value;
                        });
                      },
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
                if (_showVitalSigns) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bloodPressureController,
                          decoration: InputDecoration(
                            hintText: 'ضغط الدم',
                            labelText: 'ضغط الدم (mmHg)',
                            prefixIcon: Icon(Iconsax.heart, color: AppColors.secondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heartRateController,
                          decoration: InputDecoration(
                            hintText: 'معدل النبض',
                            labelText: 'معدل النبض (bpm)',
                            prefixIcon: Icon(Iconsax.heart_circle, color: AppColors.secondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _temperatureController,
                          decoration: InputDecoration(
                            hintText: 'درجة الحرارة',
                            labelText: 'درجة الحرارة (°C)',
                            prefixIcon: Icon(Iconsax.sun_1, color: AppColors.secondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            hintText: 'الوزن',
                            labelText: 'الوزن (kg)',
                            prefixIcon: Icon(Iconsax.weight_1, color: AppColors.secondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      hintText: 'الطول',
                      labelText: 'الطول (cm)',
                      prefixIcon: Icon(Iconsax.rulerpen, color: AppColors.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                ],

                // الملاحظات
                Text(
                  'ملاحظات',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'أدخل أي ملاحظات إضافية',
                    prefixIcon: Icon(Iconsax.note_text, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                // زر الحفظ
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitRecord,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Iconsax.tick_circle, size: 26),
                    label: Text(
                      _isLoading ? 'جاري الحفظ...' : 'حفظ السجل الطبي',
                      style: AppTextStyles.buttonLarge.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
}

