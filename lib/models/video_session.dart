/// Models for video session functionality
library;

/// Request model for video token
class VideoTokenRequest {
  final String appointmentId;
  final String role; // 'doctor' or 'patient'

  VideoTokenRequest({
    required this.appointmentId,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'role': role,
    };
  }
}

/// Response model for video token
class VideoTokenResponse {
  final String token;
  final String channelName;
  final int uid;
  final int expirationTime;
  final String appId;
  final String? sessionStatus;
  final bool? canJoin;

  VideoTokenResponse({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.expirationTime,
    required this.appId,
    this.sessionStatus,
    this.canJoin,
  });

  factory VideoTokenResponse.fromJson(Map<String, dynamic> json) {
    return VideoTokenResponse(
      token: json['token'] as String,
      channelName: json['channelName'] as String,
      uid: json['uid'] as int,
      expirationTime: json['expirationTime'] as int,
      appId: json['appId'] as String,
      sessionStatus: json['sessionStatus'] as String?,
      canJoin: json['canJoin'] as bool?,
    );
  }
}

/// Agora App ID response
class AgoraAppIdResponse {
  final String appId;
  final bool isEnabled;

  AgoraAppIdResponse({
    required this.appId,
    required this.isEnabled,
  });

  factory AgoraAppIdResponse.fromJson(Map<String, dynamic> json) {
    return AgoraAppIdResponse(
      appId: json['appId'] as String,
      isEnabled: json['isEnabled'] as bool,
    );
  }
}

/// Video session information
class VideoSessionInfo {
  final String sessionId;
  final String appointmentId;
  final String channelName;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<VideoSessionParticipant> participants;
  final Map<String, dynamic>? metadata;

  VideoSessionInfo({
    required this.sessionId,
    required this.appointmentId,
    required this.channelName,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.participants,
    this.metadata,
  });

  factory VideoSessionInfo.fromJson(Map<String, dynamic> json) {
    return VideoSessionInfo(
      sessionId: json['sessionId'] as String? ?? '',
      appointmentId: json['appointmentId'] as String,
      channelName: json['channelName'] as String,
      status: json['status'] as String,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => VideoSessionParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Video session participant
class VideoSessionParticipant {
  final String userId;
  final String role;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  VideoSessionParticipant({
    required this.userId,
    required this.role,
    this.joinedAt,
    this.leftAt,
  });

  factory VideoSessionParticipant.fromJson(Map<String, dynamic> json) {
    return VideoSessionParticipant(
      userId: json['userId']?.toString() ?? json['_id']?.toString() ?? '',
      role: json['role'] as String,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      leftAt: json['leftAt'] != null
          ? DateTime.parse(json['leftAt'] as String)
          : null,
    );
  }
}







