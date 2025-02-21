import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvatarVideoView extends StatelessWidget {
  final MediaStream? stream;

  const AvatarVideoView({
    super.key,
    this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 540, // 1080/2 for reasonable display size
      width: 960,  // 1920/2 maintaining aspect ratio
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: stream == null
            ? const Center(
                child: Text(
                  'Avatar video will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : RTCVideoView(
                RTCVideoRenderer()..srcObject = stream,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
      ),
    );
  }
}