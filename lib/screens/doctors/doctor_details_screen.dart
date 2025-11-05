import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/doctor.dart';
import '../appointments/book_appointment_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  final String? serviceId;
  final String? serviceName;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    this.serviceId,
    this.serviceName,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();

  Doctor? _doctor;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctorDetails();
  }

  Future<void> _loadDoctorDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final doctor = await _apiService.getDoctorById(
        doctorId: widget.doctorId,
        token: token,
      );

      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_doctor == null) return;

    // تحديد serviceId - أولاً من widget، ثم من خدمات الطبيب، وأخيراً departmentId
    String? serviceId = widget.serviceId;
    String? serviceName = widget.serviceName;

    if (serviceId == null || serviceId.isEmpty) {
      // محاولة استخدام أول خدمة متاحة للطبيب
      if (_doctor!.services != null && _doctor!.services!.isNotEmpty) {
        final firstActiveService = _doctor!.services!.firstWhere(
          (s) => s.isActive,
          orElse: () => _doctor!.services!.first,
        );
        serviceId = firstActiveService.serviceId;
        serviceName = firstActiveService.serviceName;
      }
    }

    if (serviceId == null || serviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد خدمات متاحة لهذا الطبيب. يرجى التحدث مع الإدارة.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          doctorId: _doctor!.id,
          doctorName: _doctor!.name,
          serviceId: serviceId!,
          serviceName: serviceName,
        ),
      ),
    );

    // إذا تم الحجز بنجاح، ارجع بيانات الطبيب للشاشة السابقة
    if (result == true && mounted) {
      // إرجاع بيانات الطبيب للشاشة السابقة إذا كانت شاشة اختيار
      Navigator.pop(context, {
        'doctorId': _doctor!.id,
        'doctorName': _doctor!.name,
      });
    }
  }

  Widget _buildHeader() {
    if (_doctor == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with Enhanced Design
          Hero(
            tag: 'doctor-${_doctor!.id}',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                image: _doctor!.avatar != null && _doctor!.avatar!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_doctor!.avatar!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: _doctor!.avatar == null || _doctor!.avatar!.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          _doctor!.name.isNotEmpty
                              ? _doctor!.name[0].toUpperCase()
                              : 'د',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Name with verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _doctor!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.verify,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
          if (_doctor!.departmentName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.health,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _doctor!.departmentName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_doctor!.yearsOfExperience != null) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.award,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_doctor!.yearsOfExperience} سنوات خبرة',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientPrimary,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_doctor == null || _doctor!.services == null || _doctor!.services!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 40,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد خدمات متاحة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeServices = _doctor!.services!.where((s) => s.isActive).toList();
    if (activeServices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 40,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد خدمات متاحة حالياً',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activeServices.map((service) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
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
                      service.serviceName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (service.customPrice != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.dollar_circle,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.customPrice!.toStringAsFixed(2)} ريال',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (service.customDuration != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.clock,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.customDuration} دقيقة',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'حدث خطأ في تحميل التفاصيل',
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadDoctorDetails,
                            icon: const Icon(Iconsax.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _doctor == null
                    ? const Center(child: Text('لا توجد بيانات'))
                    : CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 220,
                            floating: false,
                            pinned: true,
                            backgroundColor: AppColors.primary,
                            leading: IconButton(
                              icon: const Icon(Iconsax.arrow_right_3),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: _buildHeader(),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Bio - with animation
                                  if (_doctor!.bio != null && _doctor!.bio!.isNotEmpty)
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
                                      child: _buildInfoSection(
                                        'نبذة عن الطبيب',
                                        Text(
                                          _doctor!.bio!,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            height: 1.6,
                                            fontSize: 14,
                                          ),
                                        ),
                                        icon: Iconsax.document_text,
                                      ),
                                    ),

                                  // License Number - with animation
                                  if (_doctor!.licenseNumber != null)
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
                                      child: _buildInfoSection(
                                        'رقم الترخيص',
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.success.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Iconsax.shield_tick,
                                                color: AppColors.success,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _doctor!.licenseNumber!,
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        icon: Iconsax.shield_tick,
                                      ),
                                    ),

                                  // Services - with animation
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
                                    child: _buildInfoSection(
                                      'الخدمات المتاحة',
                                      _buildServicesList(),
                                      icon: Iconsax.health,
                                    ),
                                  ),

                                  // Photos Gallery - with animation
                                  if (_doctor!.photos != null && _doctor!.photos!.isNotEmpty)
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
                                      child: _buildInfoSection(
                                        'معرض الصور',
                                        SizedBox(
                                          height: 130,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            physics: const BouncingScrollPhysics(),
                                            itemCount: _doctor!.photos!.length,
                                            itemBuilder: (context, index) {
                                              return Container(
                                                width: 130,
                                                margin: const EdgeInsets.only(left: 10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _doctor!.photos![index],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: AppColors.background,
                                                        child: Icon(
                                                          Iconsax.gallery,
                                                          size: 40,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        icon: Iconsax.gallery,
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  // Book Button - with animation
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
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: AppColors.gradientPrimary,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _bookAppointment,
                                        icon: const Icon(Iconsax.calendar_add, size: 22),
                                        label: const Text(
                                          'حجز موعد الآن',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
        floatingActionButton: null, // Removed as we have a better button inside
      ),
    );
  }
}

