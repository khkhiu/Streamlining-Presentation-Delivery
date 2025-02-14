// lib/widgets/avatar_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvatarView extends StatelessWidget {
  final RTCVideoRenderer renderer;

  const AvatarView({super.key, required this.renderer});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }
}
