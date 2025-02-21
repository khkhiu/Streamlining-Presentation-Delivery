import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom loading indicator that shows an animated avatar silhouette
/// while the connection is being established. This provides visual feedback
/// that's thematically appropriate for our avatar application.
class AvatarLoadingIndicator extends StatefulWidget {
  final Color? color;
  final String? message;

  const AvatarLoadingIndicator({
    super.key,
    this.color,
    this.message,
  });

  @override
  State<AvatarLoadingIndicator> createState() => _AvatarLoadingIndicatorState();
}

class _AvatarLoadingIndicatorState extends State<AvatarLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Create a pulsing animation for the avatar silhouette
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Create a rotating animation for the connection indicators
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final message = widget.message ?? 'Connecting to avatar service...';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated avatar silhouette
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating connection indicators
              AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: CustomPaint(
                      painter: ConnectionIndicatorPainter(
                        color: color.withOpacity(0.2),
                      ),
                      size: const Size(120, 120),
                    ),
                  );
                },
              ),
              // Pulsing avatar silhouette
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.face,
                      size: 60,
                      color: color,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Loading message
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws the rotating connection indicators
/// around the avatar silhouette.
class ConnectionIndicatorPainter extends CustomPainter {
  final Color color;

  ConnectionIndicatorPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dashed circle
    final dashCount = 8;
    final dashLength = (2 * math.pi) / (dashCount * 2);
    
    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * 2 * dashLength;
      final sweepAngle = dashLength;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw connection nodes
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dashCount; i++) {
      final angle = i * (2 * math.pi / dashCount);
      final nodePosition = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawCircle(nodePosition, 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(ConnectionIndicatorPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}