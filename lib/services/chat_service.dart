import 'dart:async';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Service for managing chat sessions and messages
class ChatService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  String? _currentAppointmentId;
  ChatSessionInfo? _currentSession;
  List<ChatMessage> _messages = [];
  Timer? _refreshTimer;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;

  // Callbacks
  Function(List<ChatMessage>)? onMessagesUpdated;
  Function(ChatSessionInfo)? onSessionUpdated;
  Function(String)? onError;

  /// Initialize chat session
  Future<void> initializeSession(String appointmentId) async {
    try {
      _currentAppointmentId = appointmentId;
      _isLoading = true;

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      // Get session info
      _currentSession = await _apiService.getChatSession(
        appointmentId: appointmentId,
        token: token,
      );

      // Load initial messages
      await _loadMessages();

      // Mark messages as read
      await markAsRead();

      // Start auto-refresh
      _startAutoRefresh();

      _isLoading = false;

      onSessionUpdated?.call(_currentSession!);
    } catch (e) {
      _isLoading = false;
      print('❌ Error initializing chat session: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Load messages
  Future<void> _loadMessages({bool append = false}) async {
    if (_isLoading || _currentAppointmentId == null) return;

    try {
      _isLoading = true;

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await _apiService.getChatMessages(
        appointmentId: _currentAppointmentId!,
        page: _currentPage,
        limit: 50,
        token: token,
      );

      if (append) {
        _messages.addAll(response.messages);
      } else {
        _messages = response.messages;
      }

      _hasMore = response.hasMore;
      _isLoading = false;

      onMessagesUpdated?.call(_messages);
    } catch (e) {
      _isLoading = false;
      print('❌ Error loading messages: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await _loadMessages(append: true);
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadMessages();
  }

  /// Send a message
  Future<ChatMessage> sendMessage(String content, {String? replyTo}) async {
    if (_currentAppointmentId == null) {
      throw Exception('الجلسة غير مهيأة');
    }

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final message = await _apiService.sendChatMessage(
        appointmentId: _currentAppointmentId!,
        content: content,
        type: 'text',
        replyTo: replyTo,
        token: token,
      );

      // Add message to local list
      _messages.add(message);
      onMessagesUpdated?.call(_messages);

      // Refresh session info to update message count
      await _refreshSessionInfo();

      return message;
    } catch (e) {
      print('❌ Error sending message: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead() async {
    if (_currentAppointmentId == null) return;

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      await _apiService.markChatAsRead(
        appointmentId: _currentAppointmentId!,
        token: token,
      );

      // Update local messages - refresh to get updated read status

      // Refresh messages to get updated read status
      await refreshMessages();
    } catch (e) {
      print('⚠️ Error marking messages as read: $e');
      // Don't throw, this is not critical
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    if (_currentAppointmentId == null) return 0;

    try {
      final token = await _authService.getToken();
      if (token == null) return 0;

      return await _apiService.getChatUnreadCount(
        appointmentId: _currentAppointmentId!,
        token: token,
      );
    } catch (e) {
      print('⚠️ Error getting unread count: $e');
      return 0;
    }
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentAppointmentId != null && !_isLoading) {
        refreshMessages();
      }
    });
  }

  /// Stop auto-refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Refresh session info
  Future<void> _refreshSessionInfo() async {
    if (_currentAppointmentId == null) return;

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      _currentSession = await _apiService.getChatSession(
        appointmentId: _currentAppointmentId!,
        token: token,
      );

      onSessionUpdated?.call(_currentSession!);
    } catch (e) {
      print('⚠️ Error refreshing session info: $e');
    }
  }

  /// Get current user role
  Future<String> getCurrentUserRole() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return 'patient';
      return user.role == 'DOCTOR' ? 'doctor' : 'patient';
    } catch (e) {
      return 'patient';
    }
  }

  /// Get current messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Get current session
  ChatSessionInfo? get session => _currentSession;

  /// Check if session is active
  bool get isSessionActive {
    if (_currentSession == null) return false;
    return _currentSession!.status == 'active' &&
        DateTime.now().isBefore(_currentSession!.expiresAt);
  }

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if has more messages
  bool get hasMore => _hasMore;

  /// Dispose and cleanup
  Future<void> dispose() async {
    _stopAutoRefresh();
    _currentAppointmentId = null;
    _currentSession = null;
    _messages = [];
    _currentPage = 1;
    _hasMore = true;
    _isLoading = false;
    print('✅ ChatService disposed');
  }
}

