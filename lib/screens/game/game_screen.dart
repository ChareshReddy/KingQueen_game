import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/models/message_model.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/providers/game_provider.dart';
import 'package:king_queen/widgets/chit_card.dart';
import 'package:king_queen/widgets/gold_button.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _selectedPlayerId;
  bool _isMyCardRevealed = false;
  final GlobalKey _myCardKey = GlobalKey();
  final Map<String, GlobalKey> _playerKeys = {};
  
  Offset? _flyStart;
  Offset? _flyEnd;
  bool _isFlying = false;

  void _triggerFlyAnimation(Offset start, Offset end) {
    setState(() {
      _flyStart = start;
      _flyEnd = end;
      _isFlying = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isFlying = false);
    });
  }

  Offset _getWidgetOffset(GlobalKey key) {
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    final gameData = ref.watch(gameProvider);
    final room = gameData.currentRoom;
    final me = gameData.me;
    final players = gameData.players;

    ref.listen(gameProvider, (previous, next) {
      if (previous?.currentRoom == null || next.currentRoom == null) return;
      
      final pRoom = previous!.currentRoom!;
      final nRoom = next.currentRoom!;
      
      // Check for swaps
      String? swappedPlayerId;
      if (pRoom.kingId != nRoom.kingId) swappedPlayerId = pRoom.kingId;
      else if (pRoom.queenId != nRoom.queenId) swappedPlayerId = pRoom.queenId;
      else if (pRoom.ministerId != nRoom.ministerId) swappedPlayerId = pRoom.ministerId;

      if (swappedPlayerId != null && _playerKeys.containsKey(swappedPlayerId)) {
        final start = _getWidgetOffset(_myCardKey);
        final end = _getWidgetOffset(_playerKeys[swappedPlayerId]!);
        if (start != Offset.zero && end != Offset.zero) {
          _triggerFlyAnimation(start, end);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://images.unsplash.com/photo-1605379399642-870262d3d051?auto=format&fit=crop&q=80',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(room),
                Expanded(
                  child: Stack(
                    children: [
                      _buildPlayArea(me, room, players),
                      _buildGuessingGuide(),
                      _buildEmojiReactions(gameData.messages),
                      if (_isFlying && _flyStart != null && _flyEnd != null)
                        _buildFlyingCard(),
                    ],
                  ),
                ),
                _buildBottomControls(me, room),
              ],
            ),
          ),
          _buildEmojiSelector(),
          _buildUserBadge(me),
          _buildScoreboardButton(players),
        ],
      ),
    );
  }

  Widget _buildFlyingCard() {
    return Positioned(
      left: _flyStart!.dx - 40,
      top: _flyStart!.dy - 60,
      child: Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Center(
          child: Icon(Icons.stars_rounded, color: Colors.white70, size: 30),
        ),
      ).animate()
       .move(
         begin: Offset.zero, 
         end: Offset(_flyEnd!.dx - _flyStart!.dx, _flyEnd!.dy - _flyStart!.dy), 
         duration: 600.milliseconds, 
         curve: Curves.easeInOutCubic
       )
       .scale(begin: const Offset(1, 1), end: const Offset(0.5, 0.5))
       .rotate(begin: 0, end: 2)
       .fadeOut(delay: 500.milliseconds),
    );
  }

  Widget _buildGuessingGuide() {
    return Positioned(
      left: 20,
      top: 100,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GUESSING GUIDE',
              style: GoogleFonts.cinzel(
                color: AppTheme.gold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _guideRow('KING', 'QUEEN', Icons.arrow_forward_rounded),
            _guideRow('QUEEN', 'MINISTER', Icons.arrow_forward_rounded),
            _guideRow('MINISTER', 'THIEF', Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _guideRow(String from, String to, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleSmallTag(from),
          Icon(icon, size: 14, color: AppTheme.gold.withOpacity(0.5)),
          _roleSmallTag(to),
        ],
      ),
    );
  }

  Widget _roleSmallTag(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: const TextStyle(color: AppTheme.gold, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    final emojis = ['😂', '❤️', '🔥', '👍', '😮', '👑', '🤡', '💸'];
    return Positioned(
      bottom: 120,
      right: 20,
      child: Column(
        children: emojis.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => ref.read(gameProvider.notifier).sendMessage(e),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Text(e, style: const TextStyle(fontSize: 20)),
            ),
          ),
        )).toList(),
      ),
    ).animate().slideX(begin: 1, end: 0);
  }

  Widget _buildEmojiReactions(List<MessageModel> messages) {
    // Only show messages from the last 5 seconds
    final now = DateTime.now();
    final recentMessages = messages.where((m) => now.difference(m.timestamp).inSeconds < 5).toList();

    return Stack(
      children: recentMessages.map((m) {
        // Use senderId to determine horizontal position
        final xPos = (m.senderId.hashCode % 300).toDouble();
        return Positioned(
          bottom: 100,
          left: 50 + xPos,
          child: Text(
            m.text,
            style: const TextStyle(fontSize: 40),
          )
          .animate()
          .moveY(begin: 0, end: -400, duration: 3.seconds, curve: Curves.easeOut)
          .fadeOut(delay: 2.seconds, duration: 1.seconds),
        );
      }).toList(),
    );
  }

  Widget _buildScoreboardButton(List<PlayerModel> players) {
    return Positioned(
      top: 50,
      left: 20,
      child: GestureDetector(
        onTap: () => _showScoreboard(players),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          ),
          child: const Icon(Icons.leaderboard_rounded, color: AppTheme.gold, size: 20),
        ),
      ),
    );
  }

  void _showScoreboard(List<PlayerModel> players) {
    final sortedPlayers = [...players]..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'ROYAL SCOREBOARD',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.gold.withOpacity(0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: AppTheme.gold)),
                ),
                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  '${player.totalScore} pts',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBadge(me) {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, size: 14, color: AppTheme.gold),
            const SizedBox(width: 8),
            Text(
              me?.name.toUpperCase() ?? '...',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RoomModel? room) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOU', style: TextStyle(fontSize: 10, color: AppTheme.gold)),
              Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gold),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ROUND ${room?.currentRound ?? 1}',
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TOP', style: TextStyle(fontSize: 10, color: AppTheme.gold)),
              Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(me, room, players) {
    final otherPlayers = players.where((p) => p.id != me?.id).toList();
    final isKing = me?.currentRole == 'King';
    final isQueen = me?.currentRole == 'Queen';

    bool isMyTurn = (room?.status == RoomStatus.playing && isKing) || 
                   (room?.status == RoomStatus.guessing_minister && isQueen) ||
                   (room?.status == RoomStatus.guessing_thief && me?.currentRole == 'Minister');

    final isMinister = me?.currentRole == 'Minister';
    final isReveal = room?.status == RoomStatus.reveal;
    final showMyCard = _isMyCardRevealed || isKing || 
                      (isQueen && room?.status == RoomStatus.guessing_minister) ||
                      (isMinister && room?.status == RoomStatus.guessing_thief) ||
                      isReveal;

    final king = players.firstWhere((p) => p.id == room?.kingId, orElse: () => PlayerModel(id: '', name: 'KING', avatarId: ''));
    final queen = players.firstWhere((p) => p.id == room?.queenId, orElse: () => PlayerModel(id: '', name: 'QUEEN', avatarId: ''));
    final minister = players.firstWhere((p) => p.id == room?.ministerId, orElse: () => PlayerModel(id: '', name: 'MINISTER', avatarId: ''));

    String title = 'GAME IN PROGRESS';
    if (room?.status == RoomStatus.playing) {
      title = isKing ? 'GUESS THE QUEEN!' : '${king.name} IS GUESSING QUEEN';
    } else if (room?.status == RoomStatus.guessing_minister) {
      title = isQueen ? 'GUESS THE MINISTER!' : '${queen.name} IS GUESSING MINISTER';
    } else if (room?.status == RoomStatus.guessing_thief) {
      title = me?.currentRole == 'Minister' ? 'GUESS THE THIEF!' : '${minister.name} IS GUESSING THIEF';
    } else if (isReveal) {
      title = 'ROUND COMPLETE!';
    }

    if (isMyTurn) title = 'YOUR TURN TO GUESS!';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 30),
        _buildPlayersGrid(otherPlayers, isMyTurn, room?.kingId, room?.queenId, room?.ministerId, room?.status),
        const SizedBox(height: 40),
        Center(
          child: ChitCard(
            key: _myCardKey,
            role: me?.currentRole ?? "...",
            isRevealed: showMyCard,
            onTap: () {
              setState(() => _isMyCardRevealed = !_isMyCardRevealed);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersGrid(players, bool canSelect, String? kingId, String? queenId, String? ministerId, RoomStatus? status) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      alignment: WrapAlignment.center,
      children: List.generate(players.length, (index) {
        final player = players[index];
        bool isSelected = _selectedPlayerId == player.id;
        bool isKing = player.id == kingId;
        bool isQueen = player.id == queenId;
        bool isMinister = player.id == ministerId;
        
        bool showKingBadge = isKing;
        bool showQueenBadge = isQueen && (status == RoomStatus.guessing_minister || status == RoomStatus.guessing_thief || status == RoomStatus.reveal);
        bool showMinisterBadge = isMinister && (status == RoomStatus.guessing_thief || status == RoomStatus.reveal);

        _playerKeys.putIfAbsent(player.id, () => GlobalKey());
        return GestureDetector(
          onTap: canSelect ? () => setState(() => _selectedPlayerId = player.id) : null,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    key: _playerKeys[player.id],
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.gold : (showKingBadge || showQueenBadge || showMinisterBadge ? AppTheme.gold : Colors.white10),
                        width: isSelected || showKingBadge || showQueenBadge || showMinisterBadge ? 3 : 1,
                      ),
                      boxShadow: isSelected || showKingBadge || showQueenBadge || showMinisterBadge
                        ? [BoxShadow(color: AppTheme.gold.withOpacity(0.5), blurRadius: 10)] 
                        : null,
                    ),
                    child: Center(
                      child: showKingBadge 
                        ? const Icon(Icons.workspace_premium, color: AppTheme.gold, size: 35)
                        : (showQueenBadge 
                            ? const Icon(Icons.diamond, color: AppTheme.gold, size: 35)
                            : (showMinisterBadge
                                ? const Icon(Icons.gavel_rounded, color: AppTheme.gold, size: 35)
                                : const Icon(Icons.person, color: Colors.white30, size: 30))),
                    ),
                  ),
                  if (showKingBadge)
                    _badgeLabel('K'),
                  if (showQueenBadge)
                    _badgeLabel('Q'),
                  if (showMinisterBadge)
                    _badgeLabel('M'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                player.name, 
                style: TextStyle(
                  fontSize: 10, 
                  color: (showKingBadge || showQueenBadge || showMinisterBadge) ? AppTheme.gold : Colors.white70,
                  fontWeight: (showKingBadge || showQueenBadge || showMinisterBadge) ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (showKingBadge)
                const Text('KING / రాజు', style: TextStyle(fontSize: 8, color: AppTheme.gold)),
              if (showQueenBadge)
                const Text('QUEEN / రాణి', style: TextStyle(fontSize: 8, color: AppTheme.gold)),
              if (showMinisterBadge)
                const Text('MINISTER / మంత్రి', style: TextStyle(fontSize: 8, color: AppTheme.gold)),
            ],
          ),
        );
      }),
    );
  }

  Widget _badgeLabel(String label) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
        child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBottomControls(me, room) {
    bool isReveal = room?.status == RoomStatus.reveal;
    bool isHost = room?.hostId == me?.id;

    if (isReveal && isHost) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: GoldButton(
          text: 'START NEXT ROUND',
          onPressed: () => ref.read(gameProvider.notifier).startNextRound(),
        ),
      );
    }

    bool canGuess = (room?.status == RoomStatus.playing && me?.currentRole == 'King') ||
                   (room?.status == RoomStatus.guessing_minister && me?.currentRole == 'Queen') ||
                   (room?.status == RoomStatus.guessing_thief && me?.currentRole == 'Minister');
    
    if (!canGuess) return const SizedBox(height: 100);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoldButton(
            text: 'SUBMIT GUESS',
            onPressed: _selectedPlayerId == null 
              ? null
              : () {
                  ref.read(gameProvider.notifier).makeGuess(_selectedPlayerId!);
                  setState(() => _selectedPlayerId = null);
                },
          ),
        ],
      ),
    );
  }

}
