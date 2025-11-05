import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  String _doctorName = '';
  Map<String, int> _stats = {
    'today': 0,
    'pending': 0,
    'confirmed': 0,
    'completedWeek': 0,
  };

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
      final user = await _authService.getCurrentUser();
      _doctorName = user?.name ?? '';

      final token = await _authService.getToken() ?? '';

      // Load pending and confirmed counts (basic approximation)
      final pendingRes = await _apiService.getDoctorAppointments(
        status: 'PENDING_CONFIRM',
        page: 1,
        limit: 3,
        token: token,
      );
      final confirmedRes = await _apiService.getDoctorAppointments(
        status: 'CONFIRMED',
        page: 1,
        limit: 3,
        token: token,
      );

      setState(() {
        _stats = {
          'today': 0, // placeholder; can be refined by date filter later
          'pending': pendingRes.total,
          'confirmed': confirmedRes.total,
          'completedWeek': 0, // placeholder
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: AppTextStyles.bodyLarge))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 16),
                      _buildStatsCards(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.medical_services, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحبًا د. $_doctorName', style: AppTextStyles.headline2),
                  const SizedBox(height: 6),
                  Text(
                    'يسرنا رؤيتك! إليك ملخص يومك.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStat('اليوم', _stats['today'] ?? 0, Icons.today)),
        const SizedBox(width: 12),
        Expanded(child: _buildStat('في الانتظار', _stats['pending'] ?? 0, Icons.schedule_send)),
        const SizedBox(width: 12),
        Expanded(child: _buildStat('المؤكدة', _stats['confirmed'] ?? 0, Icons.verified)),
      ],
    );
  }

  Widget _buildStat(String title, int value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text('$value', style: AppTextStyles.headline2.copyWith(fontSize: 22)),
            Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}


