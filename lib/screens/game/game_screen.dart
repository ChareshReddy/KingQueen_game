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
import 'package:king_queen/widgets/animated_raja_rani_background.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  String? _selectedPlayerId;
  bool? _showGuide;
  bool _isMyCardRevealed = false;
  final GlobalKey _myCardKey = GlobalKey();
  final Map<String, GlobalKey> _playerKeys = {};
  String? _lastShownDeceptionTargetId;
  
  Offset? _flyStart;
  Offset? _flyEnd;
  bool _isFlying = false;

  bool _isLeaving = false;
  bool _isEmojiPanelOpen = false;

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'LEAVE GAME?',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to leave the game? If you are a key role player, the game will be reset for other players.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _leaveGame();
            },
            child: const Text('LEAVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGame() async {
    if (_isLeaving) return;
    setState(() {
      _isLeaving = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(gameProvider.notifier).leaveRoom();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error leaving game: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showGuideDialog(List<PlayerModel> players) {
    final activeRoles = players.map((p) => p.currentRole).whereType<String>().toSet();
    final sortedActiveRoles = activeRoles.toList()
      ..sort((a, b) => (GameConstants.roleScores[b] ?? 0).compareTo(GameConstants.roleScores[a] ?? 0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'ROYAL RULES & ROLES',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GUESSING SEQUENCE',
                style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _guideRow('KING / రాజు', 'QUEEN / రాణి', Icons.arrow_forward_rounded),
              _guideRow('QUEEN / రాణి', 'MINISTER / మంత్రి', Icons.arrow_forward_rounded),
              _guideRow('MINISTER / మంత్రి', 'THIEF / దొంగ', Icons.arrow_forward_rounded),
              const SizedBox(height: 16),
              Text(
                'ROLE HIERARCHY & SCORES',
                style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sortedActiveRoles.map((role) {
                final score = GameConstants.roleScores[role] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(role, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('$score pts', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              if (activeRoles.any((r) => ['Guard', 'Fake Queen', 'Assassin'].contains(r))) ...[
                const SizedBox(height: 16),
                Text(
                  'SPECIAL ROLES',
                  style: GoogleFonts.cinzel(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (activeRoles.contains('Guard')) _specialRoleDescription('GUARD', 'Can protect 1 player per round. If the protected player is guessed, it is counted as a wrong guess and roles are swapped with the Guard.'),
                if (activeRoles.contains('Fake Queen')) _specialRoleDescription('FAKE QUEEN', 'Misleads the King. If the King guesses the Fake Queen, she gets a +600 points deception bonus and no role swap occurs.'),
                if (activeRoles.contains('Assassin')) _specialRoleDescription('ASSASSIN', 'Can target 1 player. That player\'s score for the round is eliminated (set to 0).'),
              ],
            ],
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

  Widget _specialRoleDescription(String role, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(role, style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(gameProvider.notifier).updateOnlineStatus(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(gameProvider.notifier).updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(gameProvider.notifier).updateOnlineStatus(false);
    } else if (state == AppLifecycleState.detached) {
      ref.read(gameProvider.notifier).leaveRoom();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(gameProvider.notifier).updateOnlineStatus(true);
    }
  }

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

    final fakeQueenDeceivedGuesserId = room?.fakeQueenDeceivedGuesserId;
    final fakeQueenDeceivedTargetId = room?.fakeQueenDeceivedTargetId;

    if (fakeQueenDeceivedTargetId != null && _lastShownDeceptionTargetId != fakeQueenDeceivedTargetId) {
      _lastShownDeceptionTargetId = fakeQueenDeceivedTargetId;
      final guesserName = players.firstWhere((p) => p.id == fakeQueenDeceivedGuesserId, orElse: () => PlayerModel(id: '', name: 'King', avatarId: '')).name;
      final targetName = players.firstWhere((p) => p.id == fakeQueenDeceivedTargetId, orElse: () => PlayerModel(id: '', name: 'Fake Queen', avatarId: '')).name;
      
      Future.microtask(() {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              'DECEPTION DETECTED!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.face_retouching_natural, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  '$guesserName guessed $targetName thinking she was the Queen...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'But she is the FAKE QUEEN! 👑❌',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  '$targetName earns +600 points deception bonus! The King retains his crown and must guess again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS', style: TextStyle(color: AppTheme.gold)),
              ),
            ],
          ),
        );
      });
    }

    ref.listen<GameState>(gameProvider, (previous, next) {
      if (previous?.currentRoom != null && next.currentRoom == null) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The room has been closed or you were removed.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (next.currentRoom?.status == RoomStatus.waiting) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyScreen(
                roomId: next.currentRoom!.id,
                isHost: next.currentRoom!.hostId == next.me?.id,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A key player left. Returning to lobby...'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

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

    return PopScope<Object?>(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showLeaveConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: AnimatedRajaRaniBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(room, me, players),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildPlayArea(me, room, players),
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
              _buildLeaveButton(),
              _buildScoreboardButton(players),
              _buildGuideButton(players),
            ],
          ),
        ),
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

  Widget _buildGuessingGuide(List<PlayerModel> players) {
    final activeRoles = players.map((p) => p.currentRole).whereType<String>().toSet();
    final room = ref.watch(gameProvider).currentRoom;
    final status = room?.status;
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final bool show = _showGuide ?? !isMobile;

    if (!show) {
      return Positioned(
        left: 10,
        top: 80,
        child: GestureDetector(
          onTap: () => setState(() => _showGuide = true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppTheme.gold,
              size: 20,
            ),
          ),
        ),
      );
    }

    String guesserText = '';
    String targetText = '';
    if (status == RoomStatus.playing) {
      final king = players.firstWhere((p) => p.currentRole == 'King', orElse: () => PlayerModel(id: '', name: 'King', avatarId: ''));
      guesserText = king.name;
      targetText = 'Queen';
    } else if (status == RoomStatus.guessing_minister) {
      final queen = players.firstWhere((p) => p.currentRole == 'Queen', orElse: () => PlayerModel(id: '', name: 'Queen', avatarId: ''));
      guesserText = queen.name;
      targetText = 'Minister';
    } else if (status == RoomStatus.guessing_thief) {
      final minister = players.firstWhere((p) => p.currentRole == 'Minister', orElse: () => PlayerModel(id: '', name: 'Minister', avatarId: ''));
      guesserText = minister.name;
      targetText = 'Thief';
    }

    return Positioned(
      left: isMobile ? 10 : 20,
      top: isMobile ? 80 : 100,
      child: Container(
        width: isMobile ? 180 : 220,
        padding: EdgeInsets.all(isMobile ? 10 : 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GUESSING GUIDE',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.gold,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showGuide = false),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 10),
            _guideRow('KING', 'QUEEN', Icons.arrow_forward_rounded, highlight: status == RoomStatus.playing, isMobile: isMobile),
            _guideRow('QUEEN', 'MINISTER', Icons.arrow_forward_rounded, highlight: status == RoomStatus.guessing_minister, isMobile: isMobile),
            _guideRow('MINISTER', 'THIEF', Icons.arrow_forward_rounded, highlight: status == RoomStatus.guessing_thief, isMobile: isMobile),
            if (guesserText.isNotEmpty) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Container(height: 1, width: double.infinity, color: Colors.white10),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'ACTIVE GUESS',
                style: GoogleFonts.cinzel(
                  color: AppTheme.gold,
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      guesserText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 10, color: AppTheme.gold),
                  const SizedBox(width: 4),
                  Text(
                    targetText,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (activeRoles.any((r) => ['Guard', 'Fake Queen', 'Assassin'].contains(r))) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Container(height: 1, width: double.infinity, color: Colors.white10),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'SPECIAL ROLES',
                style: GoogleFonts.cinzel(
                  color: AppTheme.gold.withOpacity(0.8),
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 3 : 4),
              if (activeRoles.contains('Guard')) _specialRoleHint('GUARD', 'Protect 1 player', isMobile: isMobile),
              if (activeRoles.contains('Fake Queen')) _specialRoleHint('FAKE QUEEN', 'Mislead the King', isMobile: isMobile),
              if (activeRoles.contains('Assassin')) _specialRoleHint('ASSASSIN', 'Cancel 1 player\'s pts', isMobile: isMobile),
            ]
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _specialRoleHint(String role, String hint, {bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(role, style: TextStyle(color: AppTheme.gold, fontSize: isMobile ? 7 : 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Text(hint, style: TextStyle(color: Colors.white54, fontSize: isMobile ? 7 : 8)),
        ],
      ),
    );
  }

  Widget _guideRow(String from, String to, IconData icon, {bool highlight = false, bool isMobile = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: isMobile ? 2 : 4),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.gold.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight ? AppTheme.gold.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleSmallTag(from, isMobile: isMobile),
          const SizedBox(width: 4),
          Icon(icon, size: isMobile ? 11 : 14, color: highlight ? AppTheme.gold : AppTheme.gold.withOpacity(0.5)),
          const SizedBox(width: 4),
          _roleSmallTag(to, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _roleSmallTag(String role, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(color: AppTheme.gold, fontSize: isMobile ? 8 : 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    final emojis = ['😂', '❤️', '🔥', '👍', '😮', '👑', '🤡', '💸'];
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isEmojiPanelOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black80,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: emojis.map((e) => GestureDetector(
                  onTap: () {
                    ref.read(gameProvider.notifier).sendMessage(e);
                    setState(() => _isEmojiPanelOpen = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
            ).animate().scale(alignment: Alignment.bottomRight),
          GestureDetector(
            onTap: () => setState(() => _isEmojiPanelOpen = !_isEmojiPanelOpen),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Icon(
                _isEmojiPanelOpen ? Icons.close_rounded : Icons.insert_emoticon_rounded,
                color: AppTheme.gold,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiReactions(List<MessageModel> messages) {
    // Only show messages from the last 5 seconds
    final now = DateTime.now();
    final recentMessages = messages.where((m) => now.difference(m.timestamp).inSeconds < 5).toList();

    return Stack(
      children: recentMessages.map((m) {
        // Use senderId to determine horizontal position
        final xPos = (m.senderId.hashCode.abs() % 300).toDouble();
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

  Widget _buildUserBadge(PlayerModel? me) {
    return Positioned(
      top: 50,
      right: 70,
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

  Widget _buildLeaveButton() {
    return Positioned(
      top: 50,
      right: 20,
      child: GestureDetector(
        onTap: () => _showLeaveConfirmation(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
        ),
      ),
    );
  }

  Widget _buildGuideButton(List<PlayerModel> players) {
    return Positioned(
      top: 50,
      left: 70,
      child: GestureDetector(
        onTap: () => _showGuideDialog(players),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 20),
        ),
      ),
    );
  }

  Widget _buildHeader(RoomModel? room, PlayerModel? me, List<PlayerModel> players) {
    final myScore = me?.totalScore ?? 0;
    final topScore = players.isEmpty
        ? 0
        : players.map((p) => p.totalScore).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOU', style: TextStyle(fontSize: 10, color: AppTheme.gold)),
              Text('$myScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOP', style: TextStyle(fontSize: 10, color: AppTheme.gold)),
              Text('$topScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(PlayerModel? me, RoomModel? room, List<PlayerModel> players) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 20),
          _buildPlayersGrid(otherPlayers, isMyTurn, room?.kingId, room?.queenId, room?.ministerId, room?.status),
          const SizedBox(height: 30),
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
      ),
    );
  }

  Widget _buildPlayersGrid(List<PlayerModel> players, bool canSelect, String? kingId, String? queenId, String? ministerId, RoomStatus? status) {
    final gameData = ref.watch(gameProvider);
    final me = gameData.me;
    final room = gameData.currentRoom;

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

        // Presence check
        bool isOnline = ref.read(gameProvider.notifier).isPlayerOnline(player);

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
                  // Presence indicator dot
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                  // Guard Protected Shield Icon (shown only to the Guard or during reveal phase)
                  if (room?.guardProtectedId == player.id && 
                      (me?.currentRole == 'Guard' || status == RoomStatus.reveal))
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.shield, color: Colors.white, size: 10),
                      ),
                    ),
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
              
              // Ability action buttons
              if (me != null && (status == RoomStatus.playing || status == RoomStatus.guessing_minister || status == RoomStatus.guessing_thief)) ...[
                if (me.currentRole == 'Guard' && !me.guardUsedThisRound)
                  TextButton.icon(
                    onPressed: () => _useGuardAbility(context, player),
                    icon: const Icon(Icons.shield, size: 12, color: Colors.greenAccent),
                    label: const Text('PROTECT', style: TextStyle(fontSize: 8, color: Colors.greenAccent)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                if (me.currentRole == 'Assassin' && !me.assassinUsedThisRound)
                  TextButton.icon(
                    onPressed: () => _useAssassinAbility(context, player),
                    icon: const Icon(Icons.gps_fixed, size: 12, color: Colors.redAccent),
                    label: const Text('TARGET', style: TextStyle(fontSize: 8, color: Colors.redAccent)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
              ],
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

  Widget _buildBottomControls(PlayerModel? me, RoomModel? room) {
    bool isReveal = room?.status == RoomStatus.reveal;
    bool isHost = room?.hostId == me?.id;

    if (isReveal && isHost) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GoldButton(
              text: 'START NEXT ROUND',
              onPressed: () => ref.read(gameProvider.notifier).startNextRound(),
            ),
          ),
        ),
      );
    }

    bool canGuess = (room?.status == RoomStatus.playing && me?.currentRole == 'King') ||
                   (room?.status == RoomStatus.guessing_minister && me?.currentRole == 'Queen') ||
                   (room?.status == RoomStatus.guessing_thief && me?.currentRole == 'Minister');
    
    if (!canGuess) return const SizedBox(height: 100);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
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
        ),
      ),
    );
  }

  void _useGuardAbility(BuildContext context, PlayerModel target) async {
    await ref.read(gameProvider.notifier).protectPlayer(target.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have protected ${target.name} from being guessed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _useAssassinAbility(BuildContext context, PlayerModel target) async {
    await ref.read(gameProvider.notifier).useAssassinAbility(target.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have targeted ${target.name}! Their score is eliminated for this round.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

}
