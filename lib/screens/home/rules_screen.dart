import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_queen/core/theme/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('THE STANDARD FLOW'),
                  _buildRuleStep(
                    '1',
                    'Everyone Checks Their Role',
                    'Players secretly look at their assigned role on their digital chit card.',
                    Icons.lock_outline_rounded,
                  ),
                  _buildRuleStep(
                    '2',
                    'King Reveals Himself',
                    'The King is automatically revealed to everyone. The King gets 1000 points.',
                    Icons.workspace_premium_rounded,
                  ),
                  _buildRuleStep(
                    '3',
                    'King Must Find the Queen',
                    'The King guesses who the Queen is. If correct, Queen gets 900 points. If wrong, they swap identities!',
                    Icons.search_rounded,
                  ),
                  _buildRuleStep(
                    '4',
                    'Queen\'s Turn',
                    'Once found, the Queen guesses who the Minister is. If correct, Minister gets 800 points. If wrong, they swap identities!',
                    Icons.diamond_rounded,
                  ),
                  _buildRuleStep(
                    '5',
                    'Minister Finds the Thief',
                    'The Minister identifies the Thief. If correct, they keep their points. If wrong, they swap with the Thief!',
                    Icons.gavel_rounded,
                  ),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle('POINT SYSTEM'),
                  _buildPointTable(),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle('ADVANCED ROLES (5+ PLAYERS)'),
                  _buildRoleInfo('SPY (5+ Players)', 'Can secretly see one player\'s card.', Icons.visibility),
                  _buildRoleInfo('JOKER (6+ Players)', 'Can lie or change game rules.', Icons.theater_comedy),
                  _buildRoleInfo('GUARD (7+ Players)', 'Protects one player from being guessed.', Icons.shield),
                  _buildRoleInfo('FAKE QUEEN (8+ Players)', 'Misleads the King during his turn.', Icons.face_retouching_natural),
                  _buildRoleInfo('ASSASSIN (9+ Players)', 'Can eliminate a player\'s score for the round.', Icons.person_remove_rounded),
                  _buildRoleInfo('COMMANDER (10+ Players)', 'Supports the military structure of the kingdom.', Icons.military_tech),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle('STRATEGIES'),
                  _buildStrategyBox('AS KING', 'Watch reactions carefully. Don’t guess too fast.'),
                  _buildStrategyBox('AS QUEEN', 'Observe who avoids eye contact or looks nervous.'),
                  _buildStrategyBox('AS THIEF', 'Stay calm and don\'t overact when others are guessing.'),
                  
                  const SizedBox(height: 60),
                  Center(
                    child: Opacity(
                      opacity: 0.3,
                      child: Text(
                        'KING QUEEN - ROYAL RULES',
                        style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 12, letterSpacing: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.gold),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'HOW TO PLAY',
          style: GoogleFonts.cinzel(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.2,
              child: Image.network(
                'https://images.unsplash.com/photo-1589149098258-3e9102ca63d3?auto=format&fit=crop&q=80',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.background.withOpacity(0.8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        children: [
          Container(height: 1, width: 20, color: AppTheme.gold.withOpacity(0.3)),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.cinzel(
              color: AppTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppTheme.gold.withOpacity(0.3))),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRuleStep(String number, String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.gold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP $number: $title',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPointTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _pointRow('KING (RAJA)', '1000 pts', AppTheme.gold),
          const Divider(color: Colors.white10),
          _pointRow('QUEEN (RANI)', '900 pts', Colors.white),
          const Divider(color: Colors.white10),
          _pointRow('MINISTER', '800 pts', Colors.white),
          const Divider(color: Colors.white10),
          _pointRow('SPY', '700 pts', Colors.white60),
          const Divider(color: Colors.white10),
          _pointRow('JOKER', '600 pts', Colors.white60),
          const Divider(color: Colors.white10),
          _pointRow('GUARD', '500 pts', Colors.white60),
          const Divider(color: Colors.white10),
          _pointRow('FAKE QUEEN', '400 pts', Colors.white60),
          const Divider(color: Colors.white10),
          _pointRow('ASSASSIN', '300 pts', Colors.white38),
          const Divider(color: Colors.white10),
          _pointRow('COMMANDER', '200 pts', Colors.white38),
          const Divider(color: Colors.white10),
          _pointRow('THIEF (CHOR)', '0 pts', Colors.white38),
        ],
      ),
    );
  }

  Widget _pointRow(String role, String pts, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(role, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(pts, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildRoleInfo(String name, String desc, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.gold, size: 20),
      title: Text(name, style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: TextStyle(color: Colors.white60, fontSize: 12)),
    );
  }

  Widget _buildStrategyBox(String title, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: const Border(
          left: BorderSide(color: AppTheme.gold, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
