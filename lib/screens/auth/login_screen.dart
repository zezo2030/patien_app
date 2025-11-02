import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/dimensions.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_card.dart';
import '../../services/auth_service.dart';
import '../../models/login_request.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate fields
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);

    if (emailError != null || passwordError != null) {
      setState(() {
        _errorMessage = emailError ?? passwordError;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _authService.login(request);

      if (mounted) {
        print('✅ Login successful, navigating to home');
        // Navigate to home screen after successful login
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('❌ Login error in UI: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.spacingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppDimensions.spacingXXL),

                  // Logo or Title
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLG,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'VirClinc',
                        style: AppTextStyles.headline1.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingXXL),

                  // Card
                  AppCard(
                    padding: EdgeInsets.all(AppDimensions.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: AppTextStyles.headline2,
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: AppDimensions.spacingLG),

                        // Email Field
                        Builder(
                          builder: (context) {
                            String? emailError;
                            if (_emailController.text.isNotEmpty) {
                              emailError = Validators.validateEmail(
                                _emailController.text,
                              );
                            }
                            return AppInputField(
                              label: 'البريد الإلكتروني',
                              hint: 'أدخل بريدك الإلكتروني',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                              errorText:
                                  emailError ??
                                  (_errorMessage?.contains('email') == true
                                      ? _errorMessage
                                      : null),
                              onChanged: (_) {
                                setState(() {
                                  if (_errorMessage != null) {
                                    _errorMessage = null;
                                  }
                                });
                              },
                              textInputAction: TextInputAction.next,
                            );
                          },
                        ),

                        SizedBox(height: AppDimensions.spacingMD),

                        // Password Field
                        Builder(
                          builder: (context) {
                            String? passwordError;
                            if (_passwordController.text.isNotEmpty) {
                              passwordError = Validators.validatePassword(
                                _passwordController.text,
                              );
                            }
                            return AppInputField(
                              label: 'كلمة المرور',
                              hint: 'أدخل كلمة المرور',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              icon: Icons.lock_outlined,
                              errorText:
                                  passwordError ??
                                  (_errorMessage?.contains('password') == true
                                      ? _errorMessage
                                      : null),
                              onChanged: (_) {
                                setState(() {
                                  if (_errorMessage != null) {
                                    _errorMessage = null;
                                  }
                                });
                              },
                              textInputAction: TextInputAction.done,
                              onSubmitted: _handleLogin,
                            );
                          },
                        ),

                        SizedBox(height: AppDimensions.spacingXS),

                        // Error Message
                        if (_errorMessage != null &&
                            !_errorMessage!.contains('email') &&
                            !_errorMessage!.contains('password'))
                          Padding(
                            padding: EdgeInsets.only(
                              top: AppDimensions.spacingSM,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: AppDimensions.spacingLG),

                        // Login Button
                        PrimaryButton(
                          text: 'تسجيل الدخول',
                          isLoading: _isLoading,
                          icon: Icons.login,
                          onPressed: _handleLogin,
                        ),

                        SizedBox(height: AppDimensions.spacingMD),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟ ',
                              style: AppTextStyles.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'سجل الآن',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingLG),

                  // Test Data Info
                  AppCard(
                    backgroundColor: AppColors.info.withOpacity(0.1),
                    padding: EdgeInsets.all(AppDimensions.spacingMD),
                    child: Column(
                      children: [
                        Text(
                          'بيانات الاختبار',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          'البريد: admin@clinic.com',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          'كلمة المرور: password123',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
