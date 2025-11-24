/// Models for chat functionality
library;

/// Chat message attachment
class ChatAttachment {
  final String type;
  final String url;
  final String? name;
  final int? size;

  ChatAttachment({
    required this.type,
    required this.url,
    this.name,
    this.size,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      type: json['type'] as String,
      url: json['url'] as String,
      name: json['name'] as String?,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      if (name != null) 'name': name,
      if (size != null) 'size': size,
    };
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderRole; // 'doctor' or 'patient'
  final String content;
  final String type; // 'text' or 'system'
  final bool isRead;
  final DateTime createdAt;
  final String? replyTo;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.replyTo,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole'] as String? ?? 'patient',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      replyTo: json['replyTo']?.toString(),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
              .map((a) => ChatAttachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderId': senderId,
      'senderRole': senderRole,
      'content': content,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (replyTo != null) 'replyTo': replyTo,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
    };
  }
}

/// Chat session model
class ChatSession {
  final String sessionId;
  final String appointmentId;
  final String status; // 'active', 'archived', 'expired'
  final DateTime expiresAt;
  final int messageCount;
  final DateTime? lastMessageAt;

  ChatSession({
    required this.sessionId,
    required this.appointmentId,
    required this.status,
    required this.expiresAt,
    required this.messageCount,
    this.lastMessageAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId']?.toString() ?? json['_id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      status: json['status'] as String? ?? 'active',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now(),
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'appointmentId': appointmentId,
      'status': status,
      'expiresAt': expiresAt.toIso8601String(),
      'messageCount': messageCount,
      if (lastMessageAt != null)
        'lastMessageAt': lastMessageAt!.toIso8601String(),
    };
  }
}

/// Request model for sending a message
class SendMessageRequest {
  final String content;
  final String? type; // 'text' or 'system'
  final String? replyTo;
  final List<ChatAttachment>? attachments;

  SendMessageRequest({
    required this.content,
    this.type,
    this.replyTo,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (type != null) 'type': type,
      if (replyTo != null) 'replyTo': replyTo,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
    };
  }
}

/// Response model for messages list
class MessagesResponse {
  final List<ChatMessage> messages;
  final int total;
  final bool hasMore;

  MessagesResponse({
    required this.messages,
    required this.total,
    required this.hasMore,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Chat session info model
class ChatSessionInfo {
  final String sessionId;
  final String appointmentId;
  final String status;
  final DateTime expiresAt;
  final int messageCount;
  final DateTime? lastMessageAt;

  ChatSessionInfo({
    required this.sessionId,
    required this.appointmentId,
    required this.status,
    required this.expiresAt,
    required this.messageCount,
    this.lastMessageAt,
  });

  factory ChatSessionInfo.fromJson(Map<String, dynamic> json) {
    return ChatSessionInfo(
      sessionId: json['sessionId']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      status: json['status'] as String? ?? 'active',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now(),
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }
}

/// Unread count response
class UnreadCountResponse {
  final int unreadCount;

  UnreadCountResponse({
    required this.unreadCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}









