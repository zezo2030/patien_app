import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/doctor.dart';
import 'doctor_details_screen.dart';

class DoctorsScreen extends StatefulWidget {
  final String? departmentId;
  final String? departmentName;
  final String? serviceId;
  final String? serviceName;

  const DoctorsScreen({
    super.key,
    this.departmentId,
    this.departmentName,
    this.serviceId,
    this.serviceName,
  });

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
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

      final doctors = await _apiService.getDoctors(
        departmentId: widget.departmentId,
        serviceId: widget.serviceId,
        status: 'APPROVED',
        token: token,
      );

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _filteredDoctors = doctors;
          _isLoading = false;
        });
        _filterDoctors();
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

  void _filterDoctors() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredDoctors = _doctors;
      });
      return;
    }

    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final nameMatch = doctor.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final departmentMatch = doctor.departmentName?.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ?? false;
        return nameMatch || departmentMatch;
      }).toList();
    });
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white,
            AppColors.backgroundLight.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorDetailsScreen(
                  doctorId: doctor.id,
                  serviceId: widget.serviceId,
                  serviceName: widget.serviceName,
                ),
              ),
            );
            if (result != null && result is Map<String, dynamic> && mounted) {
              Navigator.pop(context, result);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative gradient overlay
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Avatar and Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern Avatar Design
                        Hero(
                          tag: 'doctor-${doctor.id}',
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: doctor.avatar != null && doctor.avatar!.isNotEmpty
                                      ? null
                                      : const LinearGradient(
                                          colors: AppColors.gradientPrimary,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  image: doctor.avatar != null && doctor.avatar!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(doctor.avatar!),
                                          fit: BoxFit.cover,
                                          onError: (_, __) {},
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 0,
                                      offset: const Offset(0, 0),
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: doctor.avatar == null || doctor.avatar!.isEmpty
                                    ? Center(
                                        child: Text(
                                          doctor.name.isNotEmpty
                                              ? doctor.name[0].toUpperCase()
                                              : 'د',
                                          style: AppTextStyles.headline1.copyWith(
                                            fontSize: 42,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              // Verified badge on avatar
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
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
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Doctor Info Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Doctor Name
                              Text(
                                doctor.name,
                                style: AppTextStyles.headline2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Department Badge
                              if (doctor.departmentName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Iconsax.hospital,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          doctor.departmentName!,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Experience Badge
                              if (doctor.yearsOfExperience != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accent.withOpacity(0.15),
                                        AppColors.accent.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Iconsax.award,
                                          size: 14,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${doctor.yearsOfExperience} سنوات خبرة',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: 13,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Bio Section
                    if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                      const SizedBox(height: 18),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.document_text,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                doctor.bio!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary,
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorDetailsScreen(
                                  doctorId: doctor.id,
                                  serviceId: widget.serviceId,
                                  serviceName: widget.serviceName,
                                ),
                              ),
                            );
                            if (result != null && result is Map<String, dynamic> && mounted) {
                              Navigator.pop(context, result);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.eye,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'عرض التفاصيل والحجز',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 16,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _searchQuery.isNotEmpty 
                    ? Iconsax.search_normal 
                    : Iconsax.user_octagon,
                size: 90,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد أطباء متاحين',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'جرب البحث بكلمات أخرى أو مسح البحث'
                  : 'سيتم إضافة الأطباء قريباً',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _filterDoctors();
                },
                icon: const Icon(Iconsax.refresh, size: 18),
                label: const Text('مسح البحث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              'حدث خطأ في تحميل الأطباء',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'يرجى المحاولة مرة أخرى',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDoctors,
              icon: const Icon(Iconsax.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.departmentName ??
        widget.serviceName ??
        'الأطباء';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                    title,
                    style: AppTextStyles.headline3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: AppColors.gradientPrimary,
                      ),
                    ),
                    child: Stack(
                      children: [
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
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              // Modern Search bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طبيب...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.search_normal_1,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.close_circle,
                                color: AppColors.error,
                                size: 18,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              _filterDoctors();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterDoctors();
                  },
                ),
              ),
              // Results count badge
              if (_searchQuery.isNotEmpty && _filteredDoctors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.filter,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_filteredDoctors.length} نتيجة',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Doctors list
              Expanded(
                child: _isLoading
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
                              'جاري تحميل الأطباء...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredDoctors.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadDoctors,
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredDoctors.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: 300 + (index * 50)),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        final clampedValue = value.clamp(0.0, 1.0);
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - clampedValue)),
                                          child: Opacity(
                                            opacity: clampedValue,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildDoctorCard(_filteredDoctors[index]),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

