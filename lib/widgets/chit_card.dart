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
    final double width = MediaQuery.of(context).size.width;
    final bool isPhone = width < 480;

    final cardWidth = isPhone ? 150.0 : 200.0;
    final cardHeight = isPhone ? 210.0 : 280.0;

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
        child: isRevealed ? _buildFront(info, isPhone, cardWidth, cardHeight) : _buildBack(isPhone, cardWidth, cardHeight),
      ),
    );
  }

  Widget _buildFront(Map<String, dynamic> info, bool isPhone, double cardWidth, double cardHeight) {
    return Container(
      key: const ValueKey(true),
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isPhone ? 15 : 20),
        boxShadow: [
          BoxShadow(color: AppTheme.gold.withOpacity(0.5), blurRadius: isPhone ? 12 : 20, spreadRadius: isPhone ? 1 : 2),
        ],
        border: Border.all(color: AppTheme.gold, width: isPhone ? 2 : 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            info['telugu'],
            style: GoogleFonts.hind(
              fontSize: isPhone ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isPhone ? 4 : 8),
          Icon(info['icon'], size: isPhone ? 35 : 50, color: AppTheme.gold),
          SizedBox(height: isPhone ? 8 : 12),
          Text(
            role.toUpperCase(),
            style: GoogleFonts.cinzel(
              fontSize: isPhone ? 16 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: isPhone ? 1.2 : 2,
            ),
          ),
          SizedBox(height: isPhone ? 12 : 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 16, vertical: isPhone ? 3 : 4),
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(isPhone ? 8 : 12),
            ),
            child: Text(
              '${info['score']} pts',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(bool isPhone, double cardWidth, double cardHeight) {
    return Container(
      key: const ValueKey(false),
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold, Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(isPhone ? 15 : 20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: isPhone ? 10 : 15, offset: Offset(0, isPhone ? 3 : 5)),
        ],
        border: Border.all(color: Colors.white24, width: isPhone ? 1.5 : 2),
      ),
      child: Center(
        child: Container(
          width: isPhone ? 120 : 160,
          height: isPhone ? 160 : 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 1),
            borderRadius: BorderRadius.circular(isPhone ? 10 : 15),
          ),
          child: Center(
            child: Icon(Icons.stars_rounded, color: Colors.white70, size: isPhone ? 40 : 60),
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
