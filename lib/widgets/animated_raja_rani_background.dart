import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:king_queen/core/theme/app_theme.dart';

class AnimatedRajaRaniBackground extends StatelessWidget {
  final Widget child;

  const AnimatedRajaRaniBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Rich dark background with gold radial glow (removed water wave image)
        Positioned.fill(
          child: Container(
            color: AppTheme.background,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    AppTheme.gold.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Group of animated 3D white idols moving in zig-zag & jumping patterns
        
        // RAJA (King Crown) - Bouncing and moving left-to-right on the left-center side
        Animated3DIdol(
          icon: FontAwesomeIcons.crown,
          color: Colors.white.withOpacity(0.65),
          size: 80,
          startX: size.width * 0.15,
          startY: size.height * 0.4,
          amplitudeX: 60,
          amplitudeY: 80,
          duration: const Duration(seconds: 6),
        ),

        // RANI (Queen Crown) - Bouncing and moving in a wider offset on the right-center side
        Animated3DIdol(
          icon: FontAwesomeIcons.crown,
          color: Colors.white.withOpacity(0.55),
          size: 80,
          startX: size.width * 0.72,
          startY: size.height * 0.45,
          amplitudeX: 70,
          amplitudeY: 95,
          duration: const Duration(seconds: 7),
        ),

        // MANTRI (Minister/Police Shield) - Floating in a wide horizontal zig-zag at the top
        Animated3DIdol(
          icon: FontAwesomeIcons.shieldHalved,
          color: Colors.white.withOpacity(0.45),
          size: 60,
          startX: size.width * 0.45,
          startY: size.height * 0.22,
          amplitudeX: 120,
          amplitudeY: 40,
          duration: const Duration(seconds: 9),
        ),

        // CHOR (Thief/Spy) - Moving in a quick zig-zag at the bottom
        Animated3DIdol(
          icon: FontAwesomeIcons.userSecret,
          color: Colors.white.withOpacity(0.5),
          size: 65,
          startX: size.width * 0.38,
          startY: size.height * 0.75,
          amplitudeX: 100,
          amplitudeY: 60,
          duration: const Duration(seconds: 5),
        ),

        // 3. Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}

class Animated3DIdol extends StatefulWidget {
  final dynamic icon;
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double amplitudeX;
  final double amplitudeY;
  final Duration duration;

  const Animated3DIdol({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.amplitudeX,
    required this.amplitudeY,
    required this.duration,
  });

  @override
  State<Animated3DIdol> createState() => _Animated3DIdolState();
}

class _Animated3DIdolState extends State<Animated3DIdol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
      builder: (context, child) {
        final val = _controller.value;

        // 1. Zig-zag horizontal movement (sine wave)
        final double xOffset = math.sin(val * 2 * math.pi) * widget.amplitudeX;
        
        // 2. Jumping vertical movement (absolute value of sine wave to create bouncing jumps)
        final double yOffset = (math.sin(val * 4 * math.pi).abs() * -widget.amplitudeY);

        // 3. 3D Rotation along X, Y, and Z axes
        final double angleX = val * 2 * math.pi;
        final double angleY = val * 2 * math.pi * 1.5;
        final double angleZ = val * 2 * math.pi * 0.5;

        return Positioned(
          left: widget.startX + xOffset,
          top: widget.startY + yOffset,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective entry
              ..rotateX(angleX)
              ..rotateY(angleY)
              ..rotateZ(angleZ),
            child: FaIcon(
              widget.icon,
              size: widget.size,
              color: widget.color,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
                Shadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
