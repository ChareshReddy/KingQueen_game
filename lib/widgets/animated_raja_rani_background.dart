import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:king_queen/core/theme/app_theme.dart';

class AnimatedRajaRaniBackground extends StatelessWidget {
  final Widget child;

  const AnimatedRajaRaniBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Rich dark background with gold radial glow
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

        // 3. Floating, animated Raja-Rani-Mantri-Chor idols (Hide & Seek / Fighting)

        // RAJA (King Crown) - White, jumping/bouncing on the left
        Positioned(
          left: 40,
          top: MediaQuery.of(context).size.height * 0.38,
          child: FaIcon(
            FontAwesomeIcons.crown,
            size: 90,
            color: Colors.white.withOpacity(0.18),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(end: -40, duration: 1.5.seconds, curve: Curves.easeInOut)
              .rotate(end: 0.08, duration: 2.seconds, curve: Curves.easeInOut),
        ),

        // RANI (Queen Crown) - White, jumping & clashing/facing Raja
        Positioned(
          right: 40,
          top: MediaQuery.of(context).size.height * 0.4,
          child: FaIcon(
            FontAwesomeIcons.crown,
            size: 90,
            color: Colors.white.withOpacity(0.15),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(end: -45, duration: 1.6.seconds, curve: Curves.easeInOut)
              .moveX(end: -40, duration: 3.seconds, curve: Curves.easeInOut) // Shifts left towards Raja
              .rotate(end: -0.08, duration: 2.2.seconds, curve: Curves.easeInOut),
        ),

        // MANTRI (Minister/Police Shield) - White, guarding the top-right
        Positioned(
          right: 80,
          top: MediaQuery.of(context).size.height * 0.15,
          child: FaIcon(
            FontAwesomeIcons.shieldHalved,
            size: 70,
            color: Colors.white.withOpacity(0.12),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(end: 25, duration: 2.5.seconds, curve: Curves.easeInOut)
              .rotate(end: 0.12, duration: 3.5.seconds, curve: Curves.easeInOut),
        ),

        // CHOR (Thief Secret Agent) - White, playing HIDE & SEEK at the bottom
        Positioned(
          left: 80,
          bottom: MediaQuery.of(context).size.height * 0.15,
          child: FaIcon(
            FontAwesomeIcons.userSecret,
            size: 70,
            color: Colors.white.withOpacity(0.15),
          )
              .animate(onPlay: (controller) => controller.repeat())
              // Hide and Seek Loop
              .fadeOut(duration: 1.8.seconds, curve: Curves.easeIn)
              .then(delay: 400.ms)
              .moveX(end: 60, duration: 100.ms) // Move while invisible (hiding)
              .fadeIn(duration: 1.8.seconds, curve: Curves.easeOut) // Re-appear (seeking)
              .then(delay: 2.seconds)
              .fadeOut(duration: 1.8.seconds, curve: Curves.easeIn)
              .then(delay: 400.ms)
              .moveX(end: -60, duration: 100.ms) // Move back
              .fadeIn(duration: 1.8.seconds, curve: Curves.easeOut)
              .then(delay: 2.seconds),
        ),

        // 4. Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}
