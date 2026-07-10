import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/models/message_model.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

class GameState {
  final RoomModel? currentRoom;
  final List<PlayerModel> players;
  final List<MessageModel> messages;
  final PlayerModel? me;
  final bool isLoading;

  GameState({
    this.currentRoom,
    this.players = const [],
    this.messages = const [],
    this.me,
    this.isLoading = false,
  });

  GameState copyWith({
    RoomModel? currentRoom,
    List<PlayerModel>? players,
    List<MessageModel>? messages,
    PlayerModel? me,
    bool? isLoading,
  }) {
    return GameState(
      currentRoom: currentRoom ?? this.currentRoom,
      players: players ?? this.players,
      messages: messages ?? this.messages,
      me: me ?? this.me,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  late FirebaseService _service;
  StreamSubscription<RoomModel>? _roomSubscription;
  StreamSubscription<List<PlayerModel>>? _playersSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

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
    _roomSubscription = null;
    _playersSubscription = null;
    _messagesSubscription = null;
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
      state = state.copyWith(currentRoom: room);
    });
    _playersSubscription = _service.streamPlayers(roomId).listen((players) {
      state = state.copyWith(players: players);
      final updatedMe = players.firstWhere((p) => p.id == state.me?.id, orElse: () => state.me!);
      state = state.copyWith(me: updatedMe);
    });
    _messagesSubscription = _service.streamMessages(roomId).listen((messages) {
      state = state.copyWith(messages: messages);
    });
  }

  Future<void> startGame() async {
    if (state.currentRoom == null) return;
    
    final players = state.players;
    if (players.length < 4) return;

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
    await _service.updatePlayerReady(state.currentRoom!.id, state.me!.id, !state.me!.isReady);
  }

  Future<void> leaveRoom() async {
    if (state.currentRoom == null || state.me == null) return;
    _cancelSubscriptions();
    await _service.leaveRoom(state.currentRoom!.id, state.me!.id);
    state = GameState(me: state.me);
  }

  Future<void> useSpyAbility(String targetPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.useSpyAbility(state.currentRoom!.id, state.me!.id);
  }

  Future<void> protectPlayer(String targetPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.protectPlayer(state.currentRoom!.id, state.me!.id, targetPlayerId);
  }

  Future<void> useAssassinAbility(String targetPlayerId) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.useAssassinAbility(state.currentRoom!.id, state.me!.id, targetPlayerId);
  }
  Future<void> useJokerAbility(String fakeRole) async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.useJokerAbility(state.currentRoom!.id, state.me!.id, fakeRole);
  }

  Future<void> useCommanderAbility() async {
    if (state.currentRoom == null || state.me == null) return;
    await _service.useCommanderAbility(state.currentRoom!.id, state.me!.id);
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

  void addBot() async {
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
    await _service.joinRoom(state.currentRoom!.id, bot);
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
