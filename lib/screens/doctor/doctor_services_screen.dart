import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/doctor_service.dart';
import '../../models/service.dart';

class DoctorServicesScreen extends StatefulWidget {
  const DoctorServicesScreen({super.key});

  @override
  State<DoctorServicesScreen> createState() => _DoctorServicesScreenState();
}

class _DoctorServicesScreenState extends State<DoctorServicesScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  String? _departmentId;
  List<DoctorService> _services = [];
  List<Service> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken() ?? '';
      
      // جلب بيانات الطبيب للحصول على departmentId
      final doctorProfile = await _apiService.getCurrentDoctorProfile(token: token);
      String? departmentId;
      if (doctorProfile['departmentId'] != null) {
        if (doctorProfile['departmentId'] is Map) {
          departmentId = doctorProfile['departmentId']['_id']?.toString() ?? 
                        doctorProfile['departmentId']['id']?.toString();
        } else {
          departmentId = doctorProfile['departmentId']?.toString();
        }
      }

      // جلب خدمات الطبيب
      final services = await _apiService.getDoctorServices(token: token);

      // جلب الخدمات المتاحة في القسم (إذا كان departmentId موجود)
      List<Service> availableServices = [];
      if (departmentId != null && departmentId.isNotEmpty) {
        try {
          availableServices = await _apiService.getDepartmentServices(
            departmentId: departmentId,
            token: token,
          );
        } catch (e) {
          print('Warning: Could not load available services: $e');
        }
      }

      setState(() {
        _departmentId = departmentId;
        _services = services;
        _availableServices = availableServices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _addService() async {
    if (_departmentId == null || _departmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إضافة خدمة: قسم الطبيب غير محدد')),
      );
      return;
    }

    // فلترة الخدمات المتاحة (إزالة الخدمات المضافة بالفعل)
    final addedServiceIds = _services.map((s) => s.serviceId).toSet();
    final servicesToShow = _availableServices
        .where((s) => !addedServiceIds.contains(s.id))
        .toList();

    if (servicesToShow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد خدمات متاحة للإضافة')),
      );
      return;
    }

    final selectedService = await _showSelectServiceDialog(servicesToShow);
    if (selectedService == null) return;

    await _showAddEditServiceDialog(selectedService, isNew: true);
  }

  Future<Service?> _showSelectServiceDialog(List<Service> services) async {
    return showDialog<Service>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر خدمة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ListTile(
                  title: Text(service.name),
                  subtitle: service.description != null
                      ? Text(service.description!)
                      : null,
                  trailing: service.basePrice != null
                      ? Text('${service.basePrice} ر.س', style: AppTextStyles.bodyMedium)
                      : null,
                  onTap: () => Navigator.of(context).pop(service),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditServiceDialog(Service service, {bool isNew = false}) async {
    final doctorService = isNew
        ? null
        : _services.firstWhere((s) => s.serviceId == service.id);

    final customPriceController = TextEditingController(
      text: doctorService?.customPrice?.toString() ?? '',
    );
    final customDurationController = TextEditingController(
      text: doctorService?.customDuration?.toString() ?? '',
    );
    bool isActive = doctorService?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(isNew ? 'إضافة خدمة' : 'تعديل خدمة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الخدمة: ${service.name}', style: AppTextStyles.bodyLarge),
                  if (service.description != null) ...[
                    const SizedBox(height: 8),
                    Text(service.description!, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: customPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر المخصص (ر.س) - اختياري',
                      hintText: 'اتركه فارغاً لاستخدام السعر الافتراضي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المدة المخصصة (بالدقائق) - اختياري',
                      hintText: 'اتركه فارغاً لاستخدام المدة الافتراضية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value ?? true;
                          });
                        },
                      ),
                      const Text('الخدمة مفعلة'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(isNew ? 'إضافة' : 'حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      try {
        final token = await _authService.getToken() ?? '';
        double? customPrice;
        int? customDuration;

        if (customPriceController.text.isNotEmpty) {
          customPrice = double.tryParse(customPriceController.text);
        }
        if (customDurationController.text.isNotEmpty) {
          customDuration = int.tryParse(customDurationController.text);
        }

        await _apiService.updateDoctorService(
          serviceId: service.id,
          customPrice: customPrice,
          customDuration: customDuration,
          isActive: isActive,
          token: token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isNew ? 'تم إضافة الخدمة بنجاح' : 'تم تحديث الخدمة بنجاح')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل ${isNew ? 'إضافة' : 'تحديث'} الخدمة: ${e.toString().replaceAll('Exception: ', '')}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteService(DoctorService doctorService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف خدمة "${doctorService.service?.name ?? 'غير معروف'}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final token = await _authService.getToken() ?? '';
        await _apiService.removeDoctorService(
          serviceId: doctorService.serviceId,
          token: token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الخدمة بنجاح')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف الخدمة: ${e.toString().replaceAll('Exception: ', '')}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الخدمات'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _services.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medical_services_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد خدمات مضافة',
                                  style: AppTextStyles.headline3.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط على زر "إضافة خدمة" لإضافة خدمة جديدة',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _services.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doctorService = _services[index];
                              final service = doctorService.service;
                              final serviceName = service?.name ?? 'خدمة غير معروفة';
                              final price = doctorService.customPrice ?? service?.basePrice;
                              final duration = doctorService.customDuration ?? service?.baseDuration;

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppColors.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  serviceName,
                                                  style: AppTextStyles.headline3,
                                                ),
                                                if (service?.description != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    service!.description!,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (!doctorService.isActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'معطلة',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (price != null) ...[
                                            Icon(
                                              Icons.attach_money,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$price ر.س',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                          if (price != null && duration != null)
                                            const SizedBox(width: 16),
                                          if (duration != null) ...[
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$duration دقيقة',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              if (service != null) {
                                                _showAddEditServiceDialog(service, isNew: false);
                                              }
                                            },
                                            icon: const Icon(Icons.edit, size: 18),
                                            label: const Text('تعديل'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _deleteService(doctorService),
                                            icon: const Icon(Icons.delete, size: 18),
                                            label: const Text('حذف'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addService,
          icon: const Icon(Icons.add),
          label: const Text('إضافة خدمة'),
        ),
      ),
    );
  }
}

