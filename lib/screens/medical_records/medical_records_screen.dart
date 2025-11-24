import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/medical_record.dart';
import 'medical_record_details_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  bool _isLoading = false;
  Future<PaginatedMedicalRecords>? _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _fetchRecords();
  }

  Future<PaginatedMedicalRecords> _fetchRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final records = await _apiService.getPatientMedicalRecords(
        token: token,
        page: 1,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return records;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _recordsFuture = _fetchRecords();
    });
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'السجلات الطبية',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Iconsax.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _refreshRecords,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshRecords,
          color: AppColors.info,
          child: FutureBuilder<PaginatedMedicalRecords>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
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
                              AppColors.info.withOpacity(0.1),
                              AppColors.info.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'جاري تحميل السجلات...',
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
                final error = snapshot.error;
                String errorMessage = 'حدث خطأ في تحميل السجلات';

                if (error.toString().contains('انتهت صلاحية') ||
                    error.toString().contains('401') ||
                    error.toString().contains('غير مصرح')) {
                  errorMessage = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
                } else if (error.toString().contains('لا يمكن الاتصال')) {
                  errorMessage = 'لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت';
                } else {
                  errorMessage = error.toString().replaceAll('Exception: ', '');
                }

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
                          errorMessage,
                          style: AppTextStyles.headline3.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refreshRecords,
                          icon: const Icon(Iconsax.refresh, size: 20),
                          label: const Text('إعادة المحاولة'),
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

              if (!snapshot.hasData || snapshot.data!.records.isEmpty) {
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
                                AppColors.info.withOpacity(0.15),
                                AppColors.info.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Icon(
                            Iconsax.health,
                            size: 64,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'لا توجد سجلات طبية',
                          style: AppTextStyles.headline3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ستظهر السجلات الطبية هنا بعد زياراتك الطبية',
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

              final records = snapshot.data!.records;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _buildRecordCard(records[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecord record) {
    final doctorName = record.doctor?.name ?? 'طبيب غير محدد';
    final dateStr = _formatDate(record.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicalRecordDetailsScreen(record: record),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info,
                        AppColors.info.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Iconsax.health,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.diagnosis,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.user,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'د. $doctorName',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar_1,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_left_2,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

