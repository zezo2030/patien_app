import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/text_styles.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String appointmentId;
  final String? doctorName;
  final String? patientName;

  const ChatScreen({
    super.key,
    required this.appointmentId,
    this.doctorName,
    this.patientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  ChatSessionInfo? _session;
  String? _currentUserRole;
  String? _currentUserName;
  String? _otherUserName;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupListeners();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user info
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      _currentUserRole = user.role == 'DOCTOR' ? 'doctor' : 'patient';
      _currentUserName = user.name;
      _otherUserName = _currentUserRole == 'doctor' 
          ? widget.patientName 
          : widget.doctorName;

      // Setup service callbacks
      _chatService.onMessagesUpdated = (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          _scrollToBottom();
        }
      };

      _chatService.onSessionUpdated = (session) {
        if (mounted) {
          setState(() {
            _session = session;
          });
        }
      };

      _chatService.onError = (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
          _showError(error);
        }
      };

      // Initialize session
      await _chatService.initializeSession(widget.appointmentId);
      
      setState(() {
        _messages = _chatService.messages;
        _session = _chatService.session;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showError(_errorMessage!);
    }
  }

  void _setupListeners() {
    _scrollController.addListener(() {
      // Load more messages when scrolling to top
      if (_scrollController.position.pixels == 0 && _chatService.hasMore) {
        _chatService.loadMoreMessages();
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    try {
      setState(() {
        _isSending = true;
      });

      await _chatService.sendMessage(content);
      
      _messageController.clear();
      
      setState(() {
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'م' : 'ص';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  bool _isCurrentUser(String senderRole) {
    return senderRole == _currentUserRole;
  }

  String _getSenderName(ChatMessage message) {
    if (_isCurrentUser(message.senderRole)) {
      return _currentUserName ?? 'أنت';
    }
    return _otherUserName ?? (message.senderRole == 'doctor' ? 'الطبيب' : 'المريض');
  }

  @override
  void dispose() {
    _chatService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otherUserName ?? 'المحادثة',
                style: AppTextStyles.headline3.copyWith(
                  fontSize: 18,
                ),
              ),
              if (_session != null)
                Text(
                  _session!.status == 'active' ? 'متصل' : 'غير متصل',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : _errorMessage != null && _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.message_remove,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeChat,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: _messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.message,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد رسائل بعد',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ابدأ المحادثة بإرسال رسالة',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isCurrentUser = _isCurrentUser(message.senderRole);
                                  
                                  return _buildMessageBubble(message, isCurrentUser);
                                },
                              ),
                      ),

                      // Input area
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText: 'اكتب رسالتك هنا...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: _isSending ? null : _sendMessage,
                                    icon: _isSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Iconsax.send_1,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    final senderName = _getSenderName(message);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Avatar for other user
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '؟',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.9)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isCurrentUser
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Iconsax.tick_circle
                              : Iconsax.document,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar for current user
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientSecondary,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _currentUserName?.isNotEmpty == true
                      ? _currentUserName![0].toUpperCase()
                      : 'أ',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

