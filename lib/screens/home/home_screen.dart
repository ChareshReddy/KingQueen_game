import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/providers/game_provider.dart';
import 'package:king_queen/screens/lobby/lobby_screen.dart';
import 'package:king_queen/screens/home/rules_screen.dart';
import 'package:king_queen/widgets/gold_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameProvider);
    final me = gameData.me;
    return Scaffold(
      appBar: AppBar(
        title: Text('${me?.name.toUpperCase() ?? "PLAYER"} DASHBOARD'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: AppTheme.gold),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileSummary(me?.name ?? 'Player', me?.totalScore ?? 0, me?.wins ?? 0),
            const Spacer(),
            _buildActionCard(
              context,
              title: 'CREATE ROOM',
              subtitle: 'Start a new game with friends',
              icon: Icons.add_box_rounded,
              onTap: () async {
                final roomId = await ref.read(gameProvider.notifier).createRoom();
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LobbyScreen(roomId: roomId, isHost: true)),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              title: 'JOIN ROOM',
              subtitle: 'Enter a code to join friends',
              icon: Icons.group_add_rounded,
              onTap: () {
                _showJoinDialog(context, ref);
              },
            ),
            const Spacer(),
            _buildBottomStats(context),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Developed by -Cherry😉',
                style: TextStyle(
                  color: AppTheme.gold.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(String name, int score, int wins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.gold,
            child: Icon(Icons.person, color: Colors.black, size: 35),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Wins: $wins  |  Score: $score',
                style: TextStyle(color: AppTheme.gold.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.gold, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.gold, size: 16),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('JOIN ROOM', style: TextStyle(color: AppTheme.gold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit Code',
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          GoldButton(
            text: 'JOIN',
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.length == 6) {
                await ref.read(gameProvider.notifier).joinRoom(code);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LobbyScreen(roomId: code)),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem(Icons.emoji_events, 'Rank #4', () {}),
        _statItem(Icons.history, 'History', () {}),
        _statItem(Icons.menu_book_rounded, 'Rules', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RulesScreen()));
        }),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppTheme.gold.withOpacity(0.6)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}
