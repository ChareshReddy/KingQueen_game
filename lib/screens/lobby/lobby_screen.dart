import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/providers/game_provider.dart';
import 'package:king_queen/screens/game/game_screen.dart';
import 'package:king_queen/widgets/gold_button.dart';
import 'package:flutter/services.dart';
import 'package:king_queen/widgets/animated_raja_rani_background.dart';

class LobbyScreen extends ConsumerWidget {
  final String roomId;
  final bool isHost;

  const LobbyScreen({super.key, required this.roomId, this.isHost = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameProvider);
    final players = gameData.players;
    final room = gameData.currentRoom;

    if (room?.status == RoomStatus.playing) {
      Future.microtask(() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ROOM: $roomId'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: AppTheme.gold, size: 20),
              tooltip: 'Copy Room Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room code $roomId copied!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.gold),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedRajaRaniBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _buildInfoBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      return _buildPlayerTile(players[index], gameData.me?.id == players[index].id);
                    },
                  ),
                ),
                _buildBottomPanel(context, ref, isHost, players),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppTheme.gold.withOpacity(0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.gold),
          SizedBox(width: 8),
          Text(
            'Waiting for players (Min: 4, Max: 10)',
            style: TextStyle(color: AppTheme.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(PlayerModel player, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: isMe ? Border.all(color: AppTheme.gold, width: 1.5) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.gold,
            child: Text(player.name[0].toUpperCase()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name} ${isMe ? "(You)" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  player.isReady ? 'READY' : 'WAITING...',
                  style: TextStyle(
                    color: player.isReady ? Colors.green : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (player.isHost)
            const Icon(Icons.stars, color: AppTheme.gold, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, WidgetRef ref, bool isHost, List<PlayerModel> players) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHost)
                  Column(
                    children: [
                      GoldButton(
                        text: 'START GAME',
                        onPressed: players.length >= 4 
                          ? () => ref.read(gameProvider.notifier).startGame()
                          : () {}, // Empty callback instead of null if GoldButton requires non-null
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Logic to add a bot
                            ref.read(gameProvider.notifier).addBot();
                          },
                          icon: const Icon(Icons.android, color: AppTheme.gold),
                          label: const Text('ADD AI PLAYER', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.gold, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GoldButton(
                    text: 'READY',
                    onPressed: () {},
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('LEAVE ROOM', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
