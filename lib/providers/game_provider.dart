import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/models/message_model.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:king_queen/core/constants/game_constants.dart';
import 'package:flutter/foundation.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

class GameState {
  final RoomModel? currentRoom;
  final List<PlayerModel> players;
  final List<MessageModel> messages;
  final PlayerModel? me;
  final bool isLoading;
  final Set<String> removingPlayerIds;

  GameState({
    this.currentRoom,
    this.players = const [],
    this.messages = const [],
    this.me,
    this.isLoading = false,
    this.removingPlayerIds = const {},
  });

  GameState copyWith({
    RoomModel? currentRoom,
    List<PlayerModel>? players,
    List<MessageModel>? messages,
    PlayerModel? me,
    bool? isLoading,
    Set<String>? removingPlayerIds,
  }) {
    return GameState(
      currentRoom: currentRoom ?? this.currentRoom,
      players: players ?? this.players,
      messages: messages ?? this.messages,
      me: me ?? this.me,
      isLoading: isLoading ?? this.isLoading,
      removingPlayerIds: removingPlayerIds ?? this.removingPlayerIds,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  late FirebaseService _service;
  StreamSubscription<RoomModel?>? _roomSubscription;
  StreamSubscription<List<PlayerModel>>? _playersSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  Timer? _heartbeatTimer;
  final Set<String> _removingPlayerIds = {};

  @override
  GameState build() {
    _service = ref.watch(firebaseServiceProvider);
    ref.onDispose(() {
      _cancelSubscriptions();
    });
    return GameState();
  }

  void _cancelSubscriptions() {
    _roomSubscription?.cancel();
    _playersSubscription?.cancel();
    _messagesSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _roomSubscription = null;
    _playersSubscription = null;
    _messagesSubscription = null;
    _heartbeatTimer = null;
  }

  Future<void> login(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      final player = await _service.loginAnonymous(name);
      state = state.copyWith(me: player, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final player = await _service.loginWithEmail(email, password);
      state = state.copyWith(me: player, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signup(String email, String password, String name) async {
    state = state.copyWith(isLoading: true);
    try {
      final player = await _service.signupWithEmail(email, password, name);
      state = state.copyWith(me: player, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<String> createRoom() async {
    if (state.me == null) throw Exception("Not logged in");
    state = state.copyWith(isLoading: true);
    try {
      final roomId = await _service.createRoom(state.me!);
      _listenToRoom(roomId);
      state = state.copyWith(isLoading: false);
      return roomId;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    if (state.me == null) throw Exception("Not logged in");
    state = state.copyWith(isLoading: true);
    try {
      await _service.joinRoom(roomId, state.me!);
      _listenToRoom(roomId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _listenToRoom(String roomId) {
    _cancelSubscriptions();

    _roomSubscription = _service.streamRoom(roomId).listen((room) {
      if (room == null) {
        _cancelSubscriptions();
        state = GameState(me: state.me);
      } else {
        state = state.copyWith(currentRoom: room);
        _checkAndTriggerAutoGuess();
        _checkAndTriggerAutoStart();
      }
    });
    _playersSubscription = _service.streamPlayers(roomId).listen((players) {
      state = state.copyWith(players: players);
      final updatedMe = players.firstWhere((p) => p.id == state.me?.id, orElse: () => state.me!);
      state = state.copyWith(me: updatedMe);

      // Auto-remove offline players if we are the host
      final room = state.currentRoom;
      if (room != null && state.me?.id == room.hostId) {
        for (var player in players) {
          // Guard so a player already in the removal flow doesn't trigger multiple times
          if (_removingPlayerIds.contains(player.id)) continue;

          // Use a longer grace period (45 seconds) for hard removal to prevent
          // false-positive kicks from temporary app-switching or transient network drops.
          if (!isPlayerOnline(player, thresholdSeconds: 45) && player.id != room.hostId) {
            _removingPlayerIds.add(player.id);
            state = state.copyWith(removingPlayerIds: Set.from(_removingPlayerIds));

            // Delay removal by 1200ms to let the local and remote grid fade animations run
            Future.delayed(const Duration(milliseconds: 1200), () {
              // Ensure they are still offline and still in the room before kicking
              final currentPlayers = state.players;
              final stillOffline = currentPlayers.any((p) => p.id == player.id && !isPlayerOnline(p, thresholdSeconds: 45));
              
              if (stillOffline) {
                _service.leaveRoom(room.id, player.id);
              }
              _removingPlayerIds.remove(player.id);
              state = state.copyWith(removingPlayerIds: Set.from(_removingPlayerIds));
            });
          }
        }
      }
    });
    _messagesSubscription = _service.streamMessages(roomId).listen((messages) {
      state = state.copyWith(messages: messages);
    });

    _startHeartbeatTimer(roomId);
  }

  void _startHeartbeatTimer(String roomId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state.currentRoom != null && state.me != null) {
        _service.updatePlayerHeartbeat(state.currentRoom!.id, state.me!.id);
      }
    });
  }

  bool isPlayerOnline(PlayerModel player, {int thresholdSeconds = 15}) {
    if (player.id.startsWith('bot_')) return true;
    if (player.lastSeen == null) return player.isOnline;
    final diff = DateTime.now().difference(player.lastSeen!);
    // Auto-guess triggers on a short window (default 15s) for smooth UX,
    // while removal uses a longer window (e.g. 45s) to allow recovery.
    return player.isOnline && diff.inSeconds < thresholdSeconds;
  }

  void _checkAndTriggerAutoGuess() {
    final room = state.currentRoom;
    if (room == null) return;

    if (room.status != RoomStatus.guessing) {
      return;
    }

    final onlinePlayers = state.players.where((p) => isPlayerOnline(p) && !p.id.startsWith('bot_')).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (onlinePlayers.isEmpty || onlinePlayers.first.id != state.me?.id) {
      return;
    }

    final chain = _computeRoleChain(state.players);
    if (room.guessStageIndex >= chain.length) return;

    final currentRole = chain[room.guessStageIndex];
    final activePlayer = state.players.firstWhere(
      (p) => p.currentRole == currentRole,
      orElse: () => PlayerModel(id: '', name: '', avatarId: ''),
    );
    if (activePlayer.id.isEmpty) return;

    final activeGuesserId = activePlayer.id;

    final isBot = activePlayer.id.startsWith('bot_');
    final isOffline = !isPlayerOnline(activePlayer);

    if (isBot || isOffline) {
      final targetStatus = room.status;
      final targetRound = room.currentRound;
      final targetStageIndex = room.guessStageIndex;
      Future.delayed(const Duration(seconds: 3), () {
        final currentRoom = state.currentRoom;
        if (currentRoom == null ||
            currentRoom.status != targetStatus ||
            currentRoom.currentRound != targetRound ||
            currentRoom.guessStageIndex != targetStageIndex) {
          return;
        }
        _makeAutoGuess(currentRoom, activeGuesserId, currentRole);
      });
    }
  }

  void _checkAndTriggerAutoStart() {
    final room = state.currentRoom;
    if (room == null || room.status != RoomStatus.dealing) return;

    final onlinePlayers = state.players.where((p) => isPlayerOnline(p) && !p.id.startsWith('bot_')).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (onlinePlayers.isEmpty || onlinePlayers.first.id != state.me?.id) {
      return;
    }

    // Coordinator triggers startGame after 1 second delay
    Future.delayed(const Duration(seconds: 1), () {
      final currentRoom = state.currentRoom;
      if (currentRoom != null && currentRoom.status == RoomStatus.dealing) {
        startGame();
      }
    });
  }

  void _makeAutoGuess(RoomModel room, String guesserId, String currentRole) {
    final chain = _computeRoleChain(state.players);
    final currentStage = room.guessStageIndex;
    
    final List<String> excludedIds = [];
    for (int i = 0; i <= currentStage; i++) {
      if (i < chain.length) {
        final role = chain[i];
        final player = state.players.firstWhere(
          (p) => p.currentRole == role,
          orElse: () => PlayerModel(id: '', name: '', avatarId: ''),
        );
        if (player.id.isNotEmpty) {
          excludedIds.add(player.id);
        }
      }
    }

    final candidates = state.players
        .where((p) => !excludedIds.contains(p.id))
        .toList();

    if (candidates.isEmpty) return;

    final randomCandidate = candidates[Random().nextInt(candidates.length)];

    _service.resolveGuess(
      roomId: room.id,
      guesserId: guesserId,
      guessedPlayerId: randomCandidate.id,
      currentRole: currentRole,
    );
  }

  List<String> _computeRoleChain(List<PlayerModel> players) {
    final activeRoles = players.map((p) => p.currentRole).whereType<String>().toSet();
    final chain = activeRoles.toList()
      ..sort((a, b) => (GameConstants.roleScores[b] ?? 0).compareTo(GameConstants.roleScores[a] ?? 0));
    return chain;
  }

  Future<void> startGame() async {
    if (state.currentRoom == null) return;
    
    final players = state.players;
    if (players.length < 4) return;

    try {
      final roles = _getRolesForPlayerCount(players.length);
      roles.shuffle();
      final Map<String, String> rolesMap = {};

      for (int i = 0; i < players.length; i++) {
        rolesMap[players[i].id] = roles[i];
      }

      final kingId = players[roles.indexOf('King')].id;
      final queenId = players[roles.indexOf('Queen')].id;
      final ministerId = players[roles.indexOf('Minister')].id;
      final thiefId = players[roles.indexOf('Thief')].id;

      await _service.updateGameRoles(state.currentRoom!.id, rolesMap, kingId, queenId, ministerId, thiefId);
    } catch (e) {
      debugPrint('startGame failed: $e');
      rethrow;
    }
  }

  List<String> _getRolesForPlayerCount(int count) {
    List<String> pool = ['King', 'Queen', 'Minister', 'Spy', 'Joker', 'Guard', 'Fake Queen', 'Assassin', 'Commander'];
    // Defensive clamp: ensure we don't request more elements than available in the pool
    final int activeCount = count.clamp(1, pool.length + 1);
    List<String> roles = pool.sublist(0, activeCount - 1);
    roles.add('Thief');
    
    // Fallback: if count exceeds the pool size, fill the rest with Commander
    while (roles.length < count) {
      roles.add('Commander');
    }
    return roles;
  }

  void makeGuess(String guessedPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;

    final room = state.currentRoom!;
    final me = state.me!;

    await _service.resolveGuess(
      roomId: room.id,
      guesserId: me.id,
      guessedPlayerId: guessedPlayerId,
      currentRole: me.currentRole ?? '',
    );
    await refreshMe();
  }

  Future<void> toggleReady() async {
    if (state.currentRoom == null || state.me == null) return;
    try {
      await _service.updatePlayerReady(state.currentRoom!.id, state.me!.id, !state.me!.isReady);
    } catch (e) {
      debugPrint('toggleReady failed: $e');
      rethrow;
    }
  }

  Future<void> leaveRoom() async {
    if (state.currentRoom == null || state.me == null) return;
    _cancelSubscriptions();
    await _service.leaveRoom(state.currentRoom!.id, state.me!.id);
    state = GameState(me: state.me);
  }

  Future<void> protectPlayer(String targetPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.protectPlayer(state.currentRoom!.id, state.me!.id, targetPlayerId);
  }

  Future<void> useAssassinAbility(String targetPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.useAssassinAbility(state.currentRoom!.id, state.me!.id, targetPlayerId);
  }

  Future<void> refreshMe() async {
    if (state.me == null) return;
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(state.me!.id).get();
    if (userSnap.exists) {
      final data = userSnap.data()!;
      final updatedMe = state.me!.copyWith(
        totalScore: data['totalScore'] ?? 0,
        wins: data['wins'] ?? 0,
      );
      state = state.copyWith(me: updatedMe);
    }
  }
  Future<void> startNextRound() async {
    if (state.currentRoom == null) return;
    await _service.resetRound(state.currentRoom!.id, state.players.map((p) => p.id).toList());
  }

  Future<void> addBot() async {
    if (state.currentRoom == null) return;
    if (state.players.length >= 10) return; // Limit room to max 10 players
    final botNames = ['Soldier Bot', 'Police Bot', 'Thief Bot', 'Spy Bot', 'Joker Bot'];
    final name = botNames[Random().nextInt(botNames.length)];
    final bot = PlayerModel(
      id: 'bot_${Uuid().v4()}',
      name: '$name ${state.players.length}',
      avatarId: 'bot',
      isReady: true,
    );
    try {
      await _service.joinRoom(state.currentRoom!.id, bot);
    } catch (e) {
      debugPrint('addBot failed: $e');
      rethrow;
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.updatePlayerOnlineStatus(state.currentRoom!.id, state.me!.id, isOnline);
  }

  Future<void> sendMessage(String text) async {
    if (state.currentRoom == null || state.me == null) return;
    
    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: state.me!.id,
      senderName: state.me!.name,
      text: text,
      timestamp: DateTime.now(),
    );
    
    await _service.sendMessage(state.currentRoom!.id, message);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
