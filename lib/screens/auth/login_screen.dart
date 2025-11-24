import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/dimensions.dart';
import '../../widgets/common/app_input_field.dart';
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

      // Determine user role and navigate accordingly
      final user = await _authService.getCurrentUser();

      if (mounted) {
        if (user?.role == 'DOCTOR') {
          print('✅ Login successful, navigating to doctor dashboard');
          Navigator.of(context).pushReplacementNamed('/doctor-dashboard');
        } else {
          print('✅ Login successful, navigating to home');
          Navigator.of(context).pushReplacementNamed('/home');
        }
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundLight,
                AppColors.background,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppDimensions.spacingXL),

                    // Logo Section with Medical Design
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingLG,
                      ),
                      child: Column(
                        children: [
                          // Logo Image
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(AppDimensions.spacingMD),
                            child: Image.asset(
                              'assets/imgs/medflowlogo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingLG),
                          
                          // Welcome Text
                          Text(
                            'مرحباً بك',
                            style: AppTextStyles.headline1.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacingXS),
                          Text(
                            'في منصة ميدفلو الطبية',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.spacingXXL),

                    // Login Card with Modern Design
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingLG,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(AppDimensions.radiusXXL),
                          topLeft: Radius.circular(AppDimensions.radiusXXL),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.spacingXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title with Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(AppDimensions.spacingSM),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMD,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: AppDimensions.spacingMD),
                                Text(
                                  'تسجيل الدخول',
                                  style: AppTextStyles.headline2.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: AppDimensions.spacingXXL),

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

                            SizedBox(height: AppDimensions.spacingLG),

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
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
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

                            SizedBox(height: AppDimensions.spacingSM),

                            // Error Message
                            if (_errorMessage != null &&
                                !_errorMessage!.contains('email') &&
                                !_errorMessage!.contains('password'))
                              Container(
                                padding: EdgeInsets.all(AppDimensions.spacingMD),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMD,
                                  ),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: AppDimensions.spacingSM),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: AppDimensions.spacingXL),

                            // Login Button with Gradient
                            Container(
                              height: AppDimensions.buttonHeight + 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.gradientPrimary,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMD,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleLogin,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMD,
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.textInverse,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.login_rounded,
                                                color: AppColors.textInverse,
                                                size: 22,
                                              ),
                                              SizedBox(
                                                  width:
                                                      AppDimensions.spacingSM),
                                              Text(
                                                'تسجيل الدخول',
                                                style: AppTextStyles.button
                                                    .copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: AppDimensions.spacingXL),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.divider,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacingMD,
                                  ),
                                  child: Text(
                                    'أو',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.divider,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: AppDimensions.spacingLG),

                            // Register Link with Better Design
                            Container(
                              padding: EdgeInsets.all(AppDimensions.spacingMD),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMD,
                                ),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ليس لديك حساب؟ ',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
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
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: AppDimensions.spacingMD),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
