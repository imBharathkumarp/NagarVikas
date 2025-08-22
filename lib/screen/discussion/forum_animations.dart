import 'dart:math';
import 'package:flutter/material.dart';

class ForumAnimations {
  /// Initialize all animation controllers and animations
  static void initAnimations(
    TickerProviderStateMixin vsync,
    Function(Map<String, AnimationController>) onControllersCreated,
    Function(Map<String, Animation<double>>) onAnimationsCreated,
  ) {
    final sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: vsync,
    );

    final messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    final disclaimerController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: vsync,
    );
    disclaimerController.forward();

    final emojiAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: vsync,
    );

    final sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: sendButtonAnimationController,
      curve: Curves.easeInOut,
    ));

    final messageSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: messageAnimationController,
      curve: Curves.easeOutBack,
    ));

    final emojiScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: emojiAnimationController,
      curve: Curves.elasticOut,
    ));

    // Return controllers
    onControllersCreated({
      'sendButton': sendButtonAnimationController,
      'message': messageAnimationController,
      'disclaimer': disclaimerController,
      'emoji': emojiAnimationController,
    });

    // Return animations
    onAnimationsCreated({
      'sendButtonScale': sendButtonScaleAnimation,
      'messageSlide': messageSlideAnimation,
      'emojiScale': emojiScaleAnimation,
    });
  }
}

/// Enhanced Animated Background Widget
class EnhancedAnimatedBackground extends StatefulWidget {
  const EnhancedAnimatedBackground({super.key});

  @override
  State<EnhancedAnimatedBackground> createState() =>
      _EnhancedAnimatedBackgroundState();
}

class _EnhancedAnimatedBackgroundState extends State<EnhancedAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int bubbleCount = 25;
  late List<_EnhancedBubble> bubbles;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 25))
          ..repeat();

    final random = Random();
    bubbles = List.generate(bubbleCount, (index) {
      final size = random.nextDouble() * 25 + 8;
      return _EnhancedBubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: size,
        speed: random.nextDouble() * 0.15 + 0.03,
        dx: (random.nextDouble() - 0.5) * 0.001,
        opacity: random.nextDouble() * 0.15 + 0.05,
        color: Colors.blue.withOpacity(0.1),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _EnhancedBubblePainter(bubbles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _EnhancedBubble {
  double x, y, radius, speed, dx, opacity;
  Color color;
  _EnhancedBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.dx,
    required this.opacity,
    required this.color,
  });
}

class _EnhancedBubblePainter extends CustomPainter {
  final List<_EnhancedBubble> bubbles;
  final double progress;
  _EnhancedBubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final double dy = (bubble.y + progress * bubble.speed) % 1.2;
      final double dx = (bubble.x + progress * bubble.dx) % 1.0;
      final Offset center = Offset(dx * size.width, dy * size.height);

      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            bubble.color.withOpacity(bubble.opacity * 0.8),
            bubble.color.withOpacity(bubble.opacity * 0.2),
            Colors.transparent,
          ],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: bubble.radius));

      canvas.drawCircle(center, bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}