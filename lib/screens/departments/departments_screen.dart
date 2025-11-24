import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../models/department.dart';
import '../doctors/doctors_screen.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final _apiService = ApiService();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late Future<List<Department>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _apiService.getPublicDepartments();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshDepartments() async {
    setState(() {
      _departmentsFuture = _apiService.getPublicDepartments();
    });
    // انتظار اكتمال الجلب
    await _departmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'التخصصات الطبية',
                    style: AppTextStyles.headline3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: AppColors.gradientMedical,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles with animation
                        Positioned(
                          top: 30,
                          left: -40,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          right: -30,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 100,
                          right: 50,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 2000),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              );
                            },
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
              // Modern Search bar with glassmorphism effect
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
                    hintText: 'ابحث عن تخصص طبي...',
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
                  },
                ),
              ),
              // Results count badge - will be updated dynamically
              if (_searchQuery.isNotEmpty)
                FutureBuilder<List<Department>>(
                  future: _departmentsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final allDepartments = snapshot.data!;
                    final filteredCount = allDepartments
                        .where(
                          (dept) =>
                              dept.name.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ) ||
                              (dept.description?.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ) ??
                                  false),
                        )
                        .length;
                    
                    return Padding(
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
                                  '$filteredCount نتيجة',
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
                    );
                  },
                ),
              // Departments list
              Expanded(
                child: FutureBuilder<List<Department>>(
                  future: _departmentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
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
                              'جاري تحميل التخصصات...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.error.withOpacity(0.15),
                                      AppColors.error.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.error.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Iconsax.info_circle,
                                  size: 64,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'حدث خطأ في تحميل التخصصات',
                                style: AppTextStyles.headline3.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'يرجى المحاولة مرة أخرى',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _refreshDepartments,
                                icon: const Icon(Iconsax.refresh, size: 20),
                                label: Text(
                                  'إعادة المحاولة',
                                  style: AppTextStyles.button.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.15),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Iconsax.health,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'لا توجد تخصصات متاحة',
                                style: AppTextStyles.headline3.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'سيتم إضافة التخصصات قريباً',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final allDepartments = snapshot.data!;
                    final filteredDepartments = _searchQuery.isEmpty
                        ? allDepartments
                        : allDepartments
                              .where(
                                (dept) =>
                                    dept.name.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    (dept.description?.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ??
                                        false),
                              )
                              .toList();

                    return filteredDepartments.isEmpty
                        ? _buildSearchResults()
                        : _buildDepartmentsList(filteredDepartments);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentsList(List<Department> departments) {
    return RefreshIndicator(
      onRefresh: _refreshDepartments,
      color: AppColors.primary,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: departments.length,
          itemBuilder: (context, index) {
            final department = departments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  // ضمان أن القيمة بين 0.0 و 1.0 لتجنب أخطاء Opacity
                  final clampedValue = value.clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: clampedValue,
                    child: Opacity(
                      opacity: clampedValue,
                      child: _buildDepartmentCard(department, index),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                // ضمان أن القيمة بين 0.0 و 1.0 لتجنب أخطاء Transform.scale
                final clampedValue = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clampedValue,
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.textSecondary.withOpacity(0.15),
                          AppColors.textSecondary.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textSecondary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.search_status,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'لا توجد نتائج للبحث',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'جرب البحث بكلمات أخرى',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(Department department, int index) {
    final color = _getDepartmentColor(index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showDepartmentDetails(department);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content section - على الشمال
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Department name
                      Text(
                        department.name,
                        style: AppTextStyles.headline3.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (department.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          department.description!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Modern action button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'عرض التفاصيل',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Iconsax.arrow_left_2,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Logo/Icon section - على اليمين
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _buildDepartmentLogo(
                        department,
                        color,
                        fullWidth: false,
                      ),
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

  Widget _buildDepartmentLogo(
    Department department,
    Color fallbackColor, {
    bool fullWidth = false,
  }) {
    // If logo URL is available, show it
    if (department.logoUrl != null && department.logoUrl!.isNotEmpty) {
      if (fullWidth) {
        // عرض الصورة لتملأ الكونتينر بالكامل
        return Image.network(
          department.logoUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fallbackColor),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white,
              child: Center(
                child: _buildFallbackIcon(department, fallbackColor),
              ),
            );
          },
        );
      } else {
        // Modern circular logo with gradient border
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                fallbackColor.withOpacity(0.2),
                fallbackColor.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: fallbackColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                department.logoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fallbackColor),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon(department, fallbackColor);
                },
              ),
            ),
          ),
        );
      }
    }

    // Otherwise, show icon with modern design
    if (fullWidth) {
      return Container(
        color: Colors.white,
        child: Center(child: _buildFallbackIcon(department, fallbackColor)),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              fallbackColor.withOpacity(0.15),
              fallbackColor.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: fallbackColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: _buildFallbackIcon(department, fallbackColor),
        ),
      );
    }
  }

  Widget _buildFallbackIcon(Department department, Color color) {
    final iconMap = {
      'child': Iconsax.health,
      'heart': Iconsax.heart,
      'eye': Iconsax.eye,
      'tooth': Iconsax.lovely,
      'skin': Iconsax.card,
      'internal': Iconsax.hospital,
      'brain': Iconsax.profile_2user,
      'bone': Iconsax.activity,
    };

    final icon = department.icon != null && iconMap.containsKey(department.icon)
        ? iconMap[department.icon]!
        : Iconsax.hospital;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 40,
      ),
    );
  }

  Color _getDepartmentColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.success,
      AppColors.info,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF00BCD4), // Cyan
    ];
    return colors[index % colors.length];
  }

  void _showDepartmentDetails(Department department) {
    final color = _getDepartmentColor(0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo/Icon with modern design
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _buildDepartmentLogo(
                            department,
                            color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Name with gradient text effect
                      Center(
                        child: Text(
                          department.name,
                          style: AppTextStyles.headline2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Description with modern card design
                      if (department.description != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                AppColors.background,
                                AppColors.backgroundLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Iconsax.document_text,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'نبذة عن التخصص',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                department.description!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  height: 1.8,
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      // Modern action buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorsScreen(
                                  departmentId: department.id,
                                  departmentName: department.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.user_octagon, size: 22),
                          label: Text(
                            'عرض الأطباء المتاحين',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorsScreen(
                                  departmentId: department.id,
                                  departmentName: department.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.calendar_add, size: 22),
                          label: Text(
                            'حجز موعد',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
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

