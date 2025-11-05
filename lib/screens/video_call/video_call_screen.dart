import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../services/video_session_service.dart';
import '../../services/api_service.dart';
import '../../widgets/video_call/video_view.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String role; // 'doctor' or 'patient'
  final String? doctorName;
  final String? patientName;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.role,
    this.doctorName,
    this.patientName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoSessionService _videoService = VideoSessionService();
  final ApiService _apiService = ApiService();

  VideoViewController? _localVideoController;
  VideoViewController? _remoteVideoController;
  
  bool _isInitializing = true;
  bool _isConnecting = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  String? _errorMessage;
  int? _remoteUid;
  bool _remoteVideoEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
  }

  /// طلب صلاحيات الكاميرا والميكروفون
  Future<bool> _requestPermissions() async {
    try {
      // طلب صلاحية الكاميرا
      final cameraStatus = await Permission.camera.request();
      
      // طلب صلاحية الميكروفون
      final microphoneStatus = await Permission.microphone.request();

      // التحقق من حالة الصلاحيات
      if (cameraStatus.isDenied || microphoneStatus.isDenied) {
        // إذا رُفضت الصلاحيات، عرض رسالة وإرشادات
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return false;
      }

      if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
        // إذا رُفضت الصلاحيات بشكل دائم، عرض رسالة للذهاب إلى الإعدادات
        if (mounted) {
          _showPermissionPermanentlyDeniedDialog();
        }
        return false;
      }

      // الصلاحيات مُنحت
      return cameraStatus.isGranted && microphoneStatus.isGranted;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// عرض حوار عند رفض الصلاحيات
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('صلاحيات مطلوبة'),
          content: const Text(
            'يحتاج التطبيق إلى صلاحيات الكاميرا والميكروفون لاستخدام مكالمة الفيديو.\n\n'
            'يرجى منح الصلاحيات عند السؤال.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeVideoCall(); // إعادة المحاولة
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض حوار عند رفض الصلاحيات بشكل دائم
  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('صلاحيات مطلوبة'),
          content: const Text(
            'تم رفض الصلاحيات بشكل دائم. يرجى تفعيل صلاحيات الكاميرا والميكروفون من إعدادات التطبيق.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings(); // فتح إعدادات التطبيق
              },
              child: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeVideoCall() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // طلب الصلاحيات أولاً
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'يجب منح صلاحيات الكاميرا والميكروفون لاستخدام مكالمة الفيديو';
        });
        return;
      }

      // Get Agora App ID
      final appIdResponse = await _apiService.getAgoraAppId();
      if (!appIdResponse.isEnabled) {
        throw Exception('خدمة Agora غير مفعلة');
      }

      // Initialize engine
      await _videoService.initializeEngine(appIdResponse.appId);

      // Set up callbacks
      _videoService.onUserJoined = (uid) {
        setState(() {
          _remoteUid = uid;
          _remoteVideoEnabled = true;
          final remoteController = _videoService.getRemoteVideoController(uid);
          if (remoteController != null) {
            _remoteVideoController = remoteController;
          }
        });
      };

      _videoService.onUserOffline = (uid) {
        setState(() {
          _remoteUid = null;
          _remoteVideoEnabled = false;
          _remoteVideoController = null;
        });
      };

      _videoService.onUserPublished = (uid, sourceType) {
        if (sourceType == VideoSourceType.videoSourceCamera) {
          setState(() {
            _remoteVideoEnabled = true;
            _remoteUid = uid;
            final remoteController = _videoService.getRemoteVideoController(uid);
            if (remoteController != null) {
              _remoteVideoController = remoteController;
            }
          });
        }
      };

      _videoService.onUserUnpublished = (uid, sourceType) {
        if (sourceType == VideoSourceType.videoSourceCamera) {
          setState(() {
            _remoteVideoEnabled = false;
          });
        }
      };

      // Get local video controller
      final localController = _videoService.getLocalVideoController();
      if (localController != null) {
        setState(() {
          _localVideoController = localController;
        });
      }

      // Request token and join
      setState(() {
        _isInitializing = false;
        _isConnecting = true;
      });

      final tokenResponse = await _videoService.requestToken(
        widget.appointmentId,
        widget.role,
      );

      await _videoService.joinChannel(
        tokenResponse.token,
        tokenResponse.channelName,
        tokenResponse.uid,
      );

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isConnecting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _videoService.toggleMute();
      setState(() {
        _isMuted = _videoService.isMuted;
      });
    } catch (e) {
      _showError('فشل في تغيير حالة الميكروفون: ${e.toString()}');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _videoService.toggleVideo();
      setState(() {
        _isVideoEnabled = _videoService.isVideoEnabled;
      });
    } catch (e) {
      _showError('فشل في تغيير حالة الكاميرا: ${e.toString()}');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _videoService.switchCamera();
    } catch (e) {
      _showError('فشل في تبديل الكاميرا: ${e.toString()}');
    }
  }

  Future<void> _endCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إنهاء المكالمة'),
          content: const Text('هل أنت متأكد من رغبتك في إنهاء المكالمة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('إنهاء'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _leaveCall();
    }
  }

  Future<void> _leaveCall() async {
    try {
      await _videoService.leaveChannel();
      await _videoService.dispose();
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error leaving call: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _videoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _errorMessage != null
              ? _buildErrorView()
              : _isInitializing
                  ? _buildLoadingView()
                  : _isConnecting
                      ? _buildConnectingView()
                      : _buildVideoCallView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'جاري تهيئة المكالمة...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'جاري الاتصال...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCallView() {
    return Stack(
      children: [
        // Remote video (full screen)
        Positioned.fill(
          child: _remoteUid != null && _remoteVideoController != null && _remoteVideoEnabled
              ? RemoteVideoView(
                  controller: _remoteVideoController!,
                  isVideoEnabled: _remoteVideoEnabled,
                  userName: widget.role == 'patient' ? widget.doctorName : widget.patientName,
                )
              : EmptyVideoView(
                  label: 'في انتظار انضمام الطرف الآخر...',
                  icon: Icons.person_off,
                ),
        ),
        
        // Local video (pip)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white24,
                width: 2,
              ),
            ),
            child: _localVideoController != null
                ? LocalVideoView(
                    controller: _localVideoController!,
                    isMuted: _isMuted,
                    isVideoEnabled: _isVideoEnabled,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ),
        
        // Control buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Iconsax.microphone_slash : Iconsax.microphone,
                    label: _isMuted ? 'إلغاء كتم' : 'كتم',
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? AppColors.error : Colors.white24,
                  ),
                  
                  // Video toggle button
                  _buildControlButton(
                    icon: _isVideoEnabled ? Iconsax.video : Icons.videocam_off,
                    label: _isVideoEnabled ? 'إيقاف' : 'تشغيل',
                    onPressed: _toggleVideo,
                    backgroundColor: _isVideoEnabled ? Colors.white24 : AppColors.error,
                  ),
                  
                  // Switch camera button
                  _buildControlButton(
                    icon: Iconsax.rotate_right,
                    label: 'تبديل',
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white24,
                  ),
                  
                  // End call button
                  _buildControlButton(
                    icon: Iconsax.call,
                    label: 'إنهاء',
                    onPressed: _endCall,
                    backgroundColor: AppColors.error,
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color iconColor = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

