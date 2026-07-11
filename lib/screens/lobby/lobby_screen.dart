import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/providers/game_provider.dart';
import 'package:king_queen/screens/game/game_screen.dart';
import 'package:king_queen/widgets/gold_button.dart';
import 'package:king_queen/widgets/animated_raja_rani_background.dart';
import 'package:google_fonts/google_fonts.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  final bool isHost;

  const LobbyScreen({super.key, required this.roomId, this.isHost = false});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> with WidgetsBindingObserver {
  bool _isLeaving = false;
  bool _isTogglingReady = false;
  bool _isStartingGame = false;
  bool _isAddingBot = false;

  Future<void> _leaveLobby(BuildContext context) async {
    if (_isLeaving) return;
    setState(() {
      _isLeaving = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(gameProvider.notifier).leaveRoom();
      if (mounted) {
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error leaving room: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
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
      }
    });

    final gameData = ref.watch(gameProvider);
    final players = gameData.players;
    final room = gameData.currentRoom;

    if (room?.status == RoomStatus.guessing) {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      });
    }

    return PopScope<Object?>(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveLobby(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'RajaRani',
              style: GoogleFonts.cinzel(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'ROOM: ${widget.roomId}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: AppTheme.gold, size: 16),
              tooltip: 'Copy Room Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.roomId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room code ${widget.roomId} copied!'),
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
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.roomId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code copied to clipboard! Share with friends.'),
                  backgroundColor: AppTheme.gold,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedRajaRaniBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _buildInfoBanner(players, room),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      return _buildPlayerTile(players[index], gameData.me?.id == players[index].id);
                    },
                  ),
                ),
                _buildBottomPanel(context, ref, room?.hostId == gameData.me?.id, players, room, gameData.me),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildInfoBanner(List<PlayerModel> players, RoomModel? room) {
    final int count = players.length;
    String bannerText = 'Waiting for players (Min: 4, Max: 10)';
    if (count < 4) {
      bannerText = 'Waiting for players — $count/4 minimum joined';
    } else {
      final int readyCount = players.where((p) => p.isReady || p.id == room?.hostId).length;
      final int totalRequired = players.length;
      if (readyCount < totalRequired) {
        bannerText = '$readyCount/$totalRequired players ready — waiting for everyone to hit READY';
      } else {
        final bool isHost = room?.hostId == ref.read(gameProvider).me?.id;
        if (isHost) {
          bannerText = 'All players ready! Tap START GAME to begin';
        } else {
          bannerText = 'All players ready — waiting for host to start';
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppTheme.gold.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(
            bannerText,
            style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600),
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
            child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P'),
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

  Widget _buildBottomPanel(
    BuildContext context,
    WidgetRef ref,
    bool isHost,
    List<PlayerModel> players,
    RoomModel? room,
    PlayerModel? me,
  ) {
    // START GAME requires at least 4 players and all non-hosts to be ready
    final bool allReady = players.length >= 4 && 
        players.every((p) => p.isReady || p.id == room?.hostId);

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
                        onPressed: (allReady && !_isStartingGame)
                          ? () async {
                              setState(() => _isStartingGame = true);
                              try {
                                await ref.read(gameProvider.notifier).startGame();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not start game: ${e.toString().replaceFirst("Exception: ", "")}'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isStartingGame = false);
                              }
                            }
                          : null,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isAddingBot
                              ? null
                              : () async {
                                  setState(() => _isAddingBot = true);
                                  try {
                                    await ref.read(gameProvider.notifier).addBot();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Could not add AI player: ${e.toString().replaceFirst("Exception: ", "")}'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isAddingBot = false);
                                  }
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
                    text: me?.isReady == true ? 'UNREADY' : 'READY',
                    onPressed: _isTogglingReady
                        ? null
                        : () async {
                            setState(() => _isTogglingReady = true);
                            try {
                              await ref.read(gameProvider.notifier).toggleReady();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not update ready status: ${e.toString().replaceFirst("Exception: ", "")}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isTogglingReady = false);
                            }
                          },
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _leaveLobby(context),
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
