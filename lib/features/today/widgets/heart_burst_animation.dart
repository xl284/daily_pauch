import 'dart:math';
import 'package:flutter/material.dart';

/// 抖音点赞式爱心爆炸动画：中心大爱心脉冲 + 18 个心形/小圆粒子向外飞散。
class HeartBurstAnimation extends StatefulWidget {
  final Color color;
  final VoidCallback? onComplete;
  final double size;

  const HeartBurstAnimation({
    super.key,
    this.color = const Color(0xFFFF3B5C),
    this.onComplete,
    this.size = 200,
  });

  @override
  State<HeartBurstAnimation> createState() => _HeartBurstAnimationState();
}

class _HeartBurstAnimationState extends State<HeartBurstAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final rng = Random();
    _particles = List.generate(18, (i) {
      final baseAngle = (2 * pi) * (i / 18);
      return _Particle(
        angle: baseAngle + rng.nextDouble() * 0.4,
        speed: 60 + rng.nextDouble() * 80,
        scale: 0.5 + rng.nextDouble() * 0.7,
        gravity: 120 + rng.nextDouble() * 60,
        spin: (rng.nextDouble() - 0.5) * 4,
        isHeart: rng.nextBool(),
      );
    });
    _ctrl.forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BurstPainter(
            progress: _ctrl.value,
            particles: _particles,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double scale;
  final double gravity;
  final double spin;
  final bool isHeart;
  _Particle({
    required this.angle,
    required this.speed,
    required this.scale,
    required this.gravity,
    required this.spin,
    required this.isHeart,
  });
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color color;

  _BurstPainter({
    required this.progress,
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = progress;
    final maxR = size.width * 0.42;

    // 中心脉冲大爱心
    final pulseScale = t < 0.3
        ? 1.0 + (t / 0.3) * 0.4
        : 1.4 - ((t - 0.3) / 0.7) * 1.4;
    if (pulseScale > 0) {
      final heartSize = size.width * 0.22 * pulseScale;
      _drawHeart(canvas, center, heartSize,
          color.withValues(alpha: (1 - t).clamp(0.0, 1.0)));
    }

    // 粒子
    for (final p in particles) {
      final dist = p.speed * t * 2.2;
      if (dist > maxR) continue;
      final dx = cos(p.angle) * dist;
      final dy = sin(p.angle) * dist + p.gravity * t * t * 0.5;
      final pos = center + Offset(dx, dy);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final scale = p.scale * (1 - t * 0.3);
      if (p.isHeart) {
        _drawHeart(canvas, pos, 14 * scale, color.withValues(alpha: alpha));
      } else {
        final paint = Paint()..color = color.withValues(alpha: alpha);
        canvas.drawCircle(pos, 5 * scale, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size;
    final h = size * 0.9;
    path.moveTo(center.dx, center.dy + h * 0.45);
    path.cubicTo(
      center.dx - w * 0.9, center.dy - h * 0.1,
      center.dx - w * 0.5, center.dy - h * 0.9,
      center.dx, center.dy - h * 0.35,
    );
    path.cubicTo(
      center.dx + w * 0.5, center.dy - h * 0.9,
      center.dx + w * 0.9, center.dy - h * 0.1,
      center.dx, center.dy + h * 0.45,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}

/// 在指定屏幕位置弹出爱心爆炸动画的辅助函数
void showHeartBurst(BuildContext context, Offset position, {Color? color}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: position.dx - 100,
      top: position.dy - 100,
      child: IgnorePointer(
        child: HeartBurstAnimation(
          color: color ?? const Color(0xFFFF3B5C),
          onComplete: () => entry.remove(),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}
