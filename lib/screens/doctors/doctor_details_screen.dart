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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Avatar with Enhanced Design
                Hero(
                  tag: 'doctor-${_doctor!.id}',
                  child: Stack(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 0,
                              offset: const Offset(0, 0),
                              spreadRadius: 4,
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
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _doctor!.name.isNotEmpty
                                        ? _doctor!.name[0].toUpperCase()
                                        : 'د',
                                    style: AppTextStyles.headline1.copyWith(
                                      fontSize: 50,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // Verified badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.verify,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Name with modern styling
                Text(
                  _doctor!.name,
                  style: AppTextStyles.headline2.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Info badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (_doctor!.departmentName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.hospital,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _doctor!.departmentName!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_doctor!.yearsOfExperience != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.award,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_doctor!.yearsOfExperience} سنوات خبرة',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
  }

  Widget _buildInfoSection(String title, Widget content, {IconData? icon, Color? iconColor}) {
    final sectionColor = iconColor ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: sectionColor.withOpacity(0.1),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sectionColor,
                          sectionColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: sectionColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_doctor == null || _doctor!.services == null || _doctor!.services!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.info_circle,
                size: 32,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد خدمات متاحة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final activeServices = _doctor!.services!.where((s) => s.isActive).toList();
    if (activeServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.info_circle,
                size: 32,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد خدمات متاحة حالياً',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: activeServices.asMap().entries.map((entry) {
        final index = entry.key;
        final service = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
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
            margin: EdgeInsets.only(bottom: index < activeServices.length - 1 ? 14 : 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Iconsax.health,
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
                        service.serviceName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (service.customPrice != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    AppColors.primary.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.dollar_circle,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${service.customPrice!.toStringAsFixed(2)} ريال',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (service.customDuration != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withOpacity(0.15),
                                    AppColors.accent.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.clock,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${service.customDuration} دقيقة',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
            ? Center(
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
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري تحميل التفاصيل...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.error.withOpacity(0.1),
                            ),
                            child: Icon(
                              Iconsax.info_circle,
                              size: 64,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'حدث خطأ في تحميل التفاصيل',
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error,
                                  AppColors.error.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _loadDoctorDetails,
                              icon: const Icon(Iconsax.refresh, size: 20),
                              label: Text(
                                'إعادة المحاولة',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 16,
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
                  )
                : _doctor == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد بيانات',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 280,
                            floating: false,
                            pinned: true,
                            backgroundColor: AppColors.primary,
                            leading: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Iconsax.arrow_right_3),
                                color: Colors.white,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: _buildHeader(),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Bio - with animation
                                  if (_doctor!.bio != null && _doctor!.bio!.isNotEmpty)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        final clampedValue = value.clamp(0.0, 1.0);
                                        return Transform.translate(
                                          offset: Offset(0, 30 * (1 - clampedValue)),
                                          child: Opacity(
                                            opacity: clampedValue,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildInfoSection(
                                        'نبذة عن الطبيب',
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topRight,
                                              end: Alignment.bottomLeft,
                                              colors: [
                                                AppColors.background,
                                                AppColors.backgroundLight,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors.border.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _doctor!.bio!,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              height: 1.8,
                                              fontSize: 15,
                                              color: AppColors.textSecondary,
                                            ),
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
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        final clampedValue = value.clamp(0.0, 1.0);
                                        return Transform.translate(
                                          offset: Offset(0, 30 * (1 - clampedValue)),
                                          child: Opacity(
                                            opacity: clampedValue,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildInfoSection(
                                        'رقم الترخيص',
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.success.withOpacity(0.15),
                                                AppColors.success.withOpacity(0.08),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors.success.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.success,
                                                      AppColors.success.withOpacity(0.8),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Iconsax.shield_tick,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  _doctor!.licenseNumber!,
                                                  style: AppTextStyles.bodyLarge.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        icon: Iconsax.shield_tick,
                                        iconColor: AppColors.success,
                                      ),
                                    ),

                                  // Services - with animation
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      final clampedValue = value.clamp(0.0, 1.0);
                                      return Transform.translate(
                                        offset: Offset(0, 30 * (1 - clampedValue)),
                                        child: Opacity(
                                          opacity: clampedValue,
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

                                  const SizedBox(height: 24),

                                  // Book Button - with animation
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) {
                                      final clampedValue = value.clamp(0.0, 1.0);
                                      return Transform.scale(
                                        scale: 0.85 + (0.15 * clampedValue),
                                        child: Opacity(
                                          opacity: clampedValue,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: AppColors.gradientPrimary,
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.5),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _bookAppointment,
                                          borderRadius: BorderRadius.circular(18),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Iconsax.calendar_add,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'حجز موعد الآن',
                                                style: AppTextStyles.button.copyWith(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Iconsax.arrow_left_2,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),
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


