import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/core/constants/game_constants.dart';

class ChitCard extends StatelessWidget {
  final String role;
  final bool isRevealed;
  final VoidCallback onTap;

  const ChitCard({
    super.key,
    required this.role,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getRoleInfo(role);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isUnder = (ValueKey(isRevealed) != child!.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt *= isUnder ? -1.0 : 1.0;
              final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
              return Transform(
                transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: isRevealed ? _buildFront(info) : _buildBack(),
      ),
    );
  }

  Widget _buildFront(Map<String, dynamic> info) {
    return Container(
      key: const ValueKey(true),
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.gold.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
        ],
        border: Border.all(color: AppTheme.gold, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            info['telugu'],
            style: GoogleFonts.hind(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Icon(info['icon'], size: 50, color: AppTheme.gold),
          const SizedBox(height: 12),
          Text(
            role.toUpperCase(),
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${info['score']} pts',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      key: const ValueKey(false),
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold, Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Center(
        child: Container(
          width: 160,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(Icons.stars_rounded, color: Colors.white70, size: 60),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(String role) {
    final normalizedKey = GameConstants.roleScores.keys.firstWhere(
      (k) => k.toLowerCase() == role.toLowerCase(),
      orElse: () => 'Thief',
    );
    final score = GameConstants.roleScores[normalizedKey] ?? 0;

    switch (role.toLowerCase()) {
      case 'king':
        return {'telugu': 'రాజు', 'score': score, 'icon': Icons.workspace_premium};
      case 'queen':
        return {'telugu': 'రాణి', 'score': score, 'icon': Icons.diamond};
      case 'minister':
        return {'telugu': 'మంత్రి', 'score': score, 'icon': Icons.gavel};
      case 'spy':
        return {'telugu': 'గూఢచారి', 'score': score, 'icon': Icons.visibility};
      case 'joker':
        return {'telugu': 'జోకర్', 'score': score, 'icon': Icons.face};
      case 'guard':
        return {'telugu': 'రక్షకుడు', 'score': score, 'icon': Icons.shield};
      case 'fake queen':
        return {'telugu': 'నకిలీ రాణి', 'score': score, 'icon': Icons.face_retouching_natural};
      case 'assassin':
        return {'telugu': 'హంతకుడు', 'score': score, 'icon': Icons.dangerous};
      case 'commander':
        return {'telugu': 'కమాండర్', 'score': score, 'icon': Icons.military_tech};
      default:
        return {'telugu': 'దొంగ', 'score': score, 'icon': Icons.privacy_tip_outlined};
    }
  }
}
