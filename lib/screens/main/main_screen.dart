import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../departments/departments_screen.dart';
import '../appointments/appointments_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _appointmentsReloadKey = 0;
  final _authService = AuthService();
  final _apiService = ApiService();
  Map<String, int> _badges = {
    'المواعيد': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadAppointmentsCount();
  }

  Future<void> _loadAppointmentsCount() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _badges['المواعيد'] = 0;
        });
        return;
      }

      final appointments = await _apiService.getPatientAppointments(
        status: null,
        token: token,
        limit: 100,
      );

      final now = DateTime.now();
      final upcomingCount = appointments.appointments.where((apt) {
        final isUpcoming = apt.startAt.isAfter(now);
        final isActiveStatus = apt.status == 'CONFIRMED' || 
                               apt.status == 'PENDING' || 
                               apt.status == 'PENDING_CONFIRM';
        return isUpcoming && isActiveStatus;
      }).length;

      if (mounted) {
        setState(() {
          _badges['المواعيد'] = upcomingCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _badges['المواعيد'] = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeScreen(),
            const DepartmentsScreen(),
            AppointmentsScreen(key: ValueKey(_appointmentsReloadKey)),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              if (index == 2) {
                _appointmentsReloadKey++;
                // تحديث عدد المواعيد عند فتح صفحة المواعيد
                _loadAppointmentsCount();
              } else if (index == 0) {
                // تحديث عدد المواعيد عند العودة للشاشة الرئيسية
                _loadAppointmentsCount();
              }
            });
          },
          badges: _badges,
        ),
      ),
    );
  }
}

