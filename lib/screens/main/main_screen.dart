import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../departments/departments_screen.dart';
import '../appointments/appointments_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _appointmentsReloadKey = 0;
  final Map<String, int> _badges = {
    'المواعيد': 2, // Example badge count
  };

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
              }
            });
          },
          badges: _badges,
        ),
      ),
    );
  }
}

