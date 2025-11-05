import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'doctor_home_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_services_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = <Widget>[
    const DoctorHomeScreen(),
    const DoctorAppointmentsScreen(),
    const DoctorScheduleScreen(),
    const DoctorServicesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الطبيب'),
          elevation: 0,
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'المواعيد',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'الجدول',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'الخدمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'الملف',
            ),
          ],
        ),
      ),
    );
  }
}

// placeholder removed


