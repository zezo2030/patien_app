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
      margin: const EdgeInsets.only(bottom: 16),
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
            color: AppColors.primary.withOpacity(0.08),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with Enhanced Design
                    Hero(
                      tag: 'doctor-${doctor.id}',
                      child: Container(
                        width: 90,
                        height: 90,
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
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: doctor.avatar == null || doctor.avatar!.isEmpty
                            ? Center(
                                child: Text(
                                  doctor.name.isNotEmpty
                                      ? doctor.name[0].toUpperCase()
                                      : 'د',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Doctor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doctor.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.verify,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'معتمد',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (doctor.departmentName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Iconsax.health,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    doctor.departmentName!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (doctor.yearsOfExperience != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Iconsax.award,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${doctor.yearsOfExperience} سنوات خبرة',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      doctor.bio!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPrimary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.eye,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'عرض التفاصيل',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Iconsax.arrow_left_2,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () async {
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن طبيب...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Iconsax.close_circle,
                            color: AppColors.textSecondary,
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
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
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
            // Doctors list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل الأطباء...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
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
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
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
    );
  }
}

