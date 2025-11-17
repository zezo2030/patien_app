import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Widget to display local video
class LocalVideoView extends StatelessWidget {
  final VideoViewController controller;
  final bool isMuted;
  final bool isVideoEnabled;

  const LocalVideoView({
    super.key,
    required this.controller,
    this.isMuted = false,
    this.isVideoEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AgoraVideoView(
              controller: controller,
            ),
          ),
        ),
        if (!isVideoEnabled)
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMuted)
                  const Icon(
                    Icons.mic_off,
                    color: Colors.white,
                    size: 16,
                  ),
                const SizedBox(width: 4),
                const Text(
                  'أنت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget to display remote video
class RemoteVideoView extends StatelessWidget {
  final VideoViewController controller;
  final bool isVideoEnabled;
  final String? userName;

  const RemoteVideoView({
    super.key,
    required this.controller,
    this.isVideoEnabled = false,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: isVideoEnabled
                ? AgoraVideoView(
                    controller: controller,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white24,
                            child: Text(
                              userName?.isNotEmpty == true
                                  ? userName![0].toUpperCase()
                                  : '؟',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        if (isVideoEnabled)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userName ?? 'الطرف الآخر',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty video view placeholder
class EmptyVideoView extends StatelessWidget {
  final String label;
  final IconData icon;

  const EmptyVideoView({
    super.key,
    required this.label,
    this.icon = Icons.person_off,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}







