import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/video_session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Service for managing Agora video sessions
class VideoSessionService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  
  // Current session data
  String? _currentAppointmentId;
  String? _currentChannelName;
  int? _currentUid;
  
  // Callbacks
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserOffline;
  Function(int uid, VideoSourceType sourceType)? onUserPublished;
  Function(int uid, VideoSourceType sourceType)? onUserUnpublished;
  Function(ConnectionStateType state, ConnectionChangedReasonType reason)? onConnectionStateChanged;
  
  /// Initialize Agora engine
  Future<void> initializeEngine(String appId) async {
    if (_isInitialized) {
      print('⚠️ Engine already initialized');
      return;
    }
    
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();
      
      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('✅ Joined channel successfully');
            _isJoined = true;
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('✅ Left channel');
            _isJoined = false;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('👤 User joined: $remoteUid');
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('👤 User offline: $remoteUid');
            onUserOffline?.call(remoteUid);
          },
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
            if (state == RemoteVideoState.remoteVideoStateStarting) {
              print('📹 Remote video starting: $remoteUid');
              onUserPublished?.call(remoteUid, VideoSourceType.videoSourceCamera);
            } else if (state == RemoteVideoState.remoteVideoStateStopped) {
              print('📹 Remote video stopped: $remoteUid');
              onUserUnpublished?.call(remoteUid, VideoSourceType.videoSourceCamera);
            }
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('🔌 Connection state changed: $state (reason: $reason)');
            onConnectionStateChanged?.call(state, reason);
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ Agora error: $err - $msg');
          },
        ),
      );
      
      _isInitialized = true;
      print('✅ Agora engine initialized successfully');
    } catch (e) {
      print('❌ Error initializing Agora engine: $e');
      throw Exception('فشل في تهيئة محرك الفيديو: ${e.toString()}');
    }
  }
  
  /// Request token from backend
  Future<VideoTokenResponse> requestToken(String appointmentId, String role) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }
      
      final response = await _apiService.getVideoToken(
        appointmentId: appointmentId,
        role: role,
        token: token,
      );
      
      _currentAppointmentId = appointmentId;
      _currentChannelName = response.channelName;
      _currentUid = response.uid;
      
      return response;
    } catch (e) {
      print('❌ Error requesting token: $e');
      rethrow;
    }
  }
  
  /// Join channel with token
  Future<void> joinChannel(String token, String channelName, int uid) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('المحرك غير مهيأ. يرجى تهيئة المحرك أولاً');
    }
    
    if (_isJoined) {
      print('⚠️ Already joined to channel');
      return;
    }
    
    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      
      // Notify backend
      if (_currentAppointmentId != null) {
        try {
          final authToken = await _authService.getToken();
          if (authToken != null) {
            await _apiService.joinVideoSession(
              appointmentId: _currentAppointmentId!,
              token: authToken,
            );
          }
        } catch (e) {
          print('⚠️ Failed to notify backend about join: $e');
        }
      }
    } catch (e) {
      print('❌ Error joining channel: $e');
      throw Exception('فشل في الانضمام للقناة: ${e.toString()}');
    }
  }
  
  /// Leave channel
  Future<void> leaveChannel() async {
    if (!_isJoined || _engine == null) {
      return;
    }
    
    try {
      await _engine!.leaveChannel();
      
      // Notify backend
      if (_currentAppointmentId != null) {
        try {
          final authToken = await _authService.getToken();
          if (authToken != null) {
            await _apiService.leaveVideoSession(
              appointmentId: _currentAppointmentId!,
              token: authToken,
            );
          }
        } catch (e) {
          print('⚠️ Failed to notify backend about leave: $e');
        }
      }
      
      _isJoined = false;
      _currentAppointmentId = null;
      _currentChannelName = null;
      _currentUid = null;
    } catch (e) {
      print('❌ Error leaving channel: $e');
      throw Exception('فشل في مغادرة القناة: ${e.toString()}');
    }
  }
  
  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (_engine == null) {
      throw Exception('المحرك غير مهيأ');
    }
    
    try {
      await _engine!.muteLocalAudioStream(!_isMuted);
      _isMuted = !_isMuted;
      print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      print('❌ Error toggling mute: $e');
      throw Exception('فشل في تغيير حالة الميكروفون: ${e.toString()}');
    }
  }
  
  /// Toggle video
  Future<void> toggleVideo() async {
    if (_engine == null) {
      throw Exception('المحرك غير مهيأ');
    }
    
    try {
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      _isVideoEnabled = !_isVideoEnabled;
      print('📹 Video ${_isVideoEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('❌ Error toggling video: $e');
      throw Exception('فشل في تغيير حالة الكاميرا: ${e.toString()}');
    }
  }
  
  /// Switch camera
  Future<void> switchCamera() async {
    if (_engine == null) {
      throw Exception('المحرك غير مهيأ');
    }
    
    try {
      await _engine!.switchCamera();
      _isFrontCamera = !_isFrontCamera;
      print('📷 Camera switched to ${_isFrontCamera ? "front" : "back"}');
    } catch (e) {
      print('❌ Error switching camera: $e');
      throw Exception('فشل في تبديل الكاميرا: ${e.toString()}');
    }
  }
  
  /// Get local video controller
  VideoViewController? getLocalVideoController() {
    if (_engine == null) {
      return null;
    }
    
    return VideoViewController(
      rtcEngine: _engine!,
      canvas: const VideoCanvas(uid: 0),
    );
  }
  
  /// Get remote video controller
  VideoViewController? getRemoteVideoController(int uid) {
    if (_engine == null || _currentChannelName == null) {
      return null;
    }
    
    return VideoViewController.remote(
      rtcEngine: _engine!,
      canvas: VideoCanvas(uid: uid),
      connection: RtcConnection(channelId: _currentChannelName!),
    );
  }
  
  /// Get current state
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isFrontCamera => _isFrontCamera;
  String? get currentChannelName => _currentChannelName;
  int? get currentUid => _currentUid;
  
  /// Dispose and cleanup
  Future<void> dispose() async {
    try {
      await leaveChannel();
      
      if (_engine != null) {
        await _engine!.stopPreview();
        await _engine!.release();
        _engine = null;
      }
      
      _isInitialized = false;
      _isJoined = false;
      _currentAppointmentId = null;
      _currentChannelName = null;
      _currentUid = null;
      
      print('✅ VideoSessionService disposed');
    } catch (e) {
      print('❌ Error disposing VideoSessionService: $e');
    }
  }
}

