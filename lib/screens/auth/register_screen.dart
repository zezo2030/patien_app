import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../config/dimensions.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_card.dart';
import '../../services/auth_service.dart';
import '../../models/register_request.dart';
import '../../utils/validators.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التقاط الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Validate all fields
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final phoneError = Validators.validatePhone(_phoneController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmPasswordError = Validators.validateConfirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );

    if (nameError != null ||
        emailError != null ||
        phoneError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      setState(() {
        _errorMessage =
            nameError ??
            emailError ??
            phoneError ??
            passwordError ??
            confirmPasswordError;
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
      final request = RegisterRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      // Register with avatar file if selected
      final user = await _authService.register(
        request,
        avatarFile: _selectedImage,
      );

      if (mounted) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم التسجيل بنجاح! مرحباً ${user.name}، يمكنك تسجيل الدخول الآن',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.spacingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'إنشاء حساب جديد',
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppDimensions.spacingSM),

                  Text(
                    'املأ البيانات التالية لإنشاء حسابك',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppDimensions.spacingLG),

                  // Card
                  AppCard(
                    padding: EdgeInsets.all(AppDimensions.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture Selection
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                          : null,
                                      child: _selectedImage == null
                                          ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _showImageSourceDialog,
                                child: Text(
                                  _selectedImage == null
                                      ? 'إضافة صورة شخصية'
                                      : 'تغيير الصورة',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppDimensions.spacingLG),

                        // Name Field
                        Builder(
                          builder: (context) {
                            String? nameError;
                            if (_nameController.text.isNotEmpty) {
                              nameError = Validators.validateName(
                                _nameController.text,
                              );
                            }
                            return AppInputField(
                              label: 'الاسم الكامل',
                              hint: 'أدخل اسمك الكامل',
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              icon: Icons.person_outlined,
                              errorText: nameError,
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
                              errorText: emailError,
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

                        // Phone Field
                        Builder(
                          builder: (context) {
                            String? phoneError;
                            if (_phoneController.text.isNotEmpty) {
                              phoneError = Validators.validatePhone(
                                _phoneController.text,
                              );
                            }
                            return AppInputField(
                              label: 'رقم الهاتف',
                              hint: '+966501234567',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                              errorText: phoneError,
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
                              hint: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              icon: Icons.lock_outlined,
                              errorText: passwordError,
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

                        // Confirm Password Field
                        Builder(
                          builder: (context) {
                            String? confirmPasswordError;
                            if (_confirmPasswordController.text.isNotEmpty) {
                              confirmPasswordError =
                                  Validators.validateConfirmPassword(
                                    _confirmPasswordController.text,
                                    _passwordController.text,
                                  );
                            }
                            return AppInputField(
                              label: 'تأكيد كلمة المرور',
                              hint: 'أعد إدخال كلمة المرور',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              icon: Icons.lock_outlined,
                              errorText: confirmPasswordError,
                              onChanged: (_) {
                                setState(() {
                                  if (_errorMessage != null) {
                                    _errorMessage = null;
                                  }
                                });
                              },
                              textInputAction: TextInputAction.done,
                              onSubmitted: _handleRegister,
                            );
                          },
                        ),

                        SizedBox(height: AppDimensions.spacingXS),

                        // Error Message
                        if (_errorMessage != null)
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

                        // Register Button
                        PrimaryButton(
                          text: 'إنشاء الحساب',
                          isLoading: _isLoading,
                          icon: Icons.person_add,
                          onPressed: _handleRegister,
                        ),

                        SizedBox(height: AppDimensions.spacingMD),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟ ',
                              style: AppTextStyles.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'سجل الدخول',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
