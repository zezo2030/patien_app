import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('VirClinc'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final authService = AuthService();
                await authService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'مرحباً بك في VirClinc',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 24),
              FutureBuilder(
                future: AuthService().getCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;
                    return Column(
                      children: [
                        Text(
                          'الاسم: ${user.name}',
                          style: AppTextStyles.bodyLarge,
                        ),
                        Text(
                          'البريد: ${user.email}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          'الدور: ${user.role}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

