import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:king_queen/models/message_model.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';
import 'package:king_queen/core/constants/game_constants.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<PlayerModel> loginAnonymous(String name) async {
    final userCredential = await _auth.signInAnonymously();
    return _createOrUpdateUser(userCredential.user!.uid, name);
  }

  Future<PlayerModel> signupWithEmail(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return _createOrUpdateUser(userCredential.user!.uid, name);
  }

  Future<PlayerModel> loginWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _db.collection('users').doc(userCredential.user!.uid).get();
    if (!doc.exists) throw Exception("User data not found");
    return PlayerModel.fromMap(doc.data()!);
  }

  Future<PlayerModel> _createOrUpdateUser(String uid, String name) async {
    final player = PlayerModel(
      id: uid,
      name: name,
      avatarId: (1 + (uid.hashCode % 10)).toString(),
    );
    await _db.collection('users').doc(player.id).set(player.toMap());
    return player;
  }

  Future<String> createRoom(PlayerModel host) async {
    final roomId = _generateRoomId();
    final room = RoomModel(
      id: roomId,
      hostId: host.id,
      playerIds: [host.id],
      createdAt: DateTime.now(),
      status: RoomStatus.waiting,
    );

    await _db.collection('rooms').doc(roomId).set(room.toMap());
    await _db.collection('rooms').doc(roomId).collection('players').doc(host.id).set(host.copyWith(isHost: true).toMap());
    
    return roomId;
  }

  Future<void> joinRoom(String roomId, PlayerModel player) async {
    final roomDoc = _db.collection('rooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomDoc);
      if (!roomSnap.exists) throw Exception("Room not found");
      
      final playerIds = List<String>.from(roomSnap.get('playerIds') ?? []);
      
      // Block newcomers if the game has already started
      final status = roomSnap.get('status') as String? ?? 'waiting';
      if (status != 'waiting' && !playerIds.contains(player.id)) {
        throw Exception("Game is already in progress in this room");
      }
      
      if (playerIds.length >= 10 && !playerIds.contains(player.id)) {
        throw Exception("Room is full (Max 10 players)");
      }
      
      if (!playerIds.contains(player.id)) {
        playerIds.add(player.id);
        transaction.update(roomDoc, {'playerIds': playerIds});
      }
      
      final playerDoc = roomDoc.collection('players').doc(player.id);
      transaction.set(playerDoc, player.toMap());
    });
  }

  Stream<RoomModel?> streamRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return RoomModel.fromMap(data);
    });
  }

  Stream<List<PlayerModel>> streamPlayers(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('players').snapshots().map((snap) {
      return snap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateGameRoles(String roomId, Map<String, String> rolesMap, String kingId, String queenId, String ministerId, String thiefId) async {
    final batch = _db.batch();
    
    batch.update(_db.collection('rooms').doc(roomId), {
      'status': 'guessing',
      'guessStageIndex': 0,
      'kingId': kingId,
      'queenId': queenId,
      'ministerId': ministerId,
      'thiefId': thiefId,
    });

    for (var entry in rolesMap.entries) {
      batch.update(_db.collection('rooms').doc(roomId).collection('players').doc(entry.key), {
        'currentRole': entry.value,
        'isReady': true,
      });
    }

    await batch.commit();
  }

  Future<void> resolveGuess({
    required String roomId,
    required String guesserId,
    required String guessedPlayerId,
    required String currentRole,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final playersColl = roomRef.collection('players');

    final result = await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) throw Exception("Room not found");
      
      final roomStatus = roomSnap.get('status') as String;
      final guardProtectedId = roomSnap.data()!.containsKey('guardProtectedId') 
          ? roomSnap.get('guardProtectedId') as String? 
          : null;
      final assassinTargetId = roomSnap.data()!.containsKey('assassinTargetId') 
          ? roomSnap.get('assassinTargetId') as String? 
          : null;

      final playersSnap = await playersColl.get();
      final players = playersSnap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
      final chain = _computeRoleChain(players);
      final guessStageIndex = roomSnap.data()!.containsKey('guessStageIndex')
          ? roomSnap.get('guessStageIndex') as int
          : 0;

      // Verify room status and guesser turn
      if (roomStatus != 'guessing' || currentRole != chain[guessStageIndex]) {
        throw Exception("Stale game state or guess already resolved.");
      }

      // Check if the guessed player is protected by the Guard
      if (guardProtectedId == guessedPlayerId) {
        // Intercepted by Guard! Treat as wrong guess.
        // Guesser swaps roles with the Guard player.
        final guardPlayer = players.firstWhere(
          (p) => p.currentRole == 'Guard',
          orElse: () => throw Exception("Guard role not found in game"),
        );

        final guesserRef = playersColl.doc(guesserId);
        final guardRef = playersColl.doc(guardPlayer.id);

        transaction.update(guesserRef, {'currentRole': 'Guard'});
        transaction.update(guardRef, {'currentRole': currentRole});

        // Update room role fields
        void updateRoleFieldIfStandard(String role, String playerId) {
          if (role == 'King') transaction.update(roomRef, {'kingId': playerId});
          else if (role == 'Queen') transaction.update(roomRef, {'queenId': playerId});
          else if (role == 'Minister') transaction.update(roomRef, {'ministerId': playerId});
          else if (role == 'Thief') transaction.update(roomRef, {'thiefId': playerId});
        }
        updateRoleFieldIfStandard(currentRole, guardPlayer.id);
        updateRoleFieldIfStandard('Guard', guesserId);
        return null;
      }

      // Determine if the guess is correct
      final targetRole = chain[guessStageIndex + 1];
      final targetPlayer = players.firstWhere((p) => p.currentRole == targetRole);
      final isCorrect = guessedPlayerId == targetPlayer.id;

      if (isCorrect) {
        // Correct guess: is it the last role in the chain (always Thief)?
        if (guessStageIndex + 1 == chain.length - 1) {
          // Finish round and award points
          transaction.update(roomRef, {'status': 'reveal'});
          
          final Map<String, int> scores = {};
          int maxScore = -1;
          for (var player in players) {
            int roundScore = 0;
            String role = player.id == guesserId ? targetRole : (player.currentRole ?? '');
            
            // Check if player is targeted by the Assassin
            if (assassinTargetId == player.id) {
              roundScore = 0; // Score eliminated by Assassin
            } else {
              roundScore = GameConstants.roleScores[role] ?? 0;
            }
            
            scores[player.id] = roundScore;
            if (roundScore > maxScore) {
              maxScore = roundScore;
            }

            transaction.update(playersColl.doc(player.id), {
              'totalScore': FieldValue.increment(roundScore),
            });
          }
          return {
            'isReveal': true,
            'scores': scores,
            'maxScore': maxScore,
          };
        } else {
          // Move to next guess stage
          transaction.update(roomRef, {'guessStageIndex': guessStageIndex + 1});
        }
      } else {
        // Incorrect guess: check if wrongly accused is Fake Queen
        final guesserRef = playersColl.doc(guesserId);
        final otherRef = playersColl.doc(guessedPlayerId);

        final guesserSnap = await transaction.get(guesserRef);
        final otherSnap = await transaction.get(otherRef);

        final guesserRole = guesserSnap.get('currentRole') as String;
        final otherRole = otherSnap.get('currentRole') as String;

        if (otherRole == 'Fake Queen') {
          // DESIGN CHOICE (Option A): Fake Queen successfully deceives the guesser!
          // Deception bonus: 600 points total.
          // Guesser remains their role and guesses again, no role swap occurs.
          transaction.update(otherRef, {
            'totalScore': FieldValue.increment(600),
          });
          transaction.update(roomRef, {
            'fakeQueenDeceivedGuesserId': guesserId,
            'fakeQueenDeceivedTargetId': guessedPlayerId,
          });
          return null;
        }

        // Standard incorrect guess: swap roles with the wrongly accused player
        transaction.update(guesserRef, {'currentRole': otherRole});
        transaction.update(otherRef, {'currentRole': guesserRole});

        // Update room role fields
        void updateRoleFieldIfStandard(String role, String playerId) {
          if (role == 'King') transaction.update(roomRef, {'kingId': playerId});
          else if (role == 'Queen') transaction.update(roomRef, {'queenId': playerId});
          else if (role == 'Minister') transaction.update(roomRef, {'ministerId': playerId});
          else if (role == 'Thief') transaction.update(roomRef, {'thiefId': playerId});
        }

        updateRoleFieldIfStandard(guesserRole, guessedPlayerId);
        updateRoleFieldIfStandard(otherRole, guesserId);
      }
      return null;
    });

    if (result != null && result['isReveal'] == true) {
      final scores = Map<String, int>.from(result['scores'] as Map);
      final maxScore = result['maxScore'] as int;

      final batch = _db.batch();
      scores.forEach((playerId, roundScore) {
        // Exclude bots and only update if player scored points
        // DESIGN CHOICE: A player is considered a winner of the round if they score the highest points.
        // In this case, we increment their lifetime wins in the users collection.
        if (!playerId.startsWith('bot_')) {
          final userRef = _db.collection('users').doc(playerId);
          final isWinner = roundScore == maxScore;
          batch.update(userRef, {
            'totalScore': FieldValue.increment(roundScore),
            if (isWinner) 'wins': FieldValue.increment(1),
          });
        }
      });
      await batch.commit();
    }
  }

  Future<void> updatePlayerReady(String roomId, String playerId, bool isReady) async {
    await _db.collection('rooms').doc(roomId).collection('players').doc(playerId).update({
      'isReady': isReady,
    });
  }

  Future<void> leaveRoom(String roomId, String playerId) async {
    final roomDoc = _db.collection('rooms').doc(roomId);
    final playersColl = roomDoc.collection('players');

    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomDoc);
      if (!roomSnap.exists) return;

      // Get all players for role resetting if game resets to waiting
      final playersSnap = await playersColl.get();

      final playerIds = List<String>.from(roomSnap.get('playerIds') ?? []);
      final hostId = roomSnap.get('hostId') as String;
      final statusStr = roomSnap.get('status') as String;

      playerIds.remove(playerId);
      final Map<String, dynamic> updates = {'playerIds': playerIds};

      final status = roomSnap.get('status') as String? ?? 'waiting';
      if (status != 'waiting') {
        if (playerIds.length < 4) {
          // Reset to lobby if too few players remain
          updates.addAll({
            'status': 'waiting',
            'kingId': null,
            'queenId': null,
            'ministerId': null,
            'thiefId': null,
            'guardProtectedId': null,
            'assassinTargetId': null,
            'fakeQueenDeceivedGuesserId': null,
            'fakeQueenDeceivedTargetId': null,
            'guessStageIndex': 0,
          });
          for (var pId in playerIds) {
            transaction.update(playersColl.doc(pId), {
              'currentRole': null,
              'isReady': false,
              'guardUsedThisRound': false,
              'assassinUsedThisRound': false,
            });
          }
        } else if (status != 'reveal' && status != 'finished') {
          // Dynamically adjust guess index if players leave
          final players = playersSnap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
          final remainingPlayers = players.where((p) => p.id != playerId).toList();
          
          final oldChain = _computeRoleChain(players);
          final newChain = _computeRoleChain(remainingPlayers);
          
          final leavingPlayer = players.firstWhere((p) => p.id == playerId, orElse: () => PlayerModel(id: '', name: '', avatarId: ''));
          final leavingRole = leavingPlayer.currentRole;
          final leavingIndex = oldChain.indexOf(leavingRole ?? '');
          
          final oldGuessStageIndex = roomSnap.data()!.containsKey('guessStageIndex') 
              ? roomSnap.get('guessStageIndex') as int 
              : 0;
          
          int newGuessStageIndex = oldGuessStageIndex;
          
          if (leavingIndex < oldGuessStageIndex) {
            // A player before the current guesser left, so shift the index back by 1
            newGuessStageIndex = max(0, oldGuessStageIndex - 1);
          }
          
          if (newGuessStageIndex + 1 >= newChain.length) {
            updates['status'] = 'reveal';
          } else {
            if (newGuessStageIndex != oldGuessStageIndex) {
              updates['guessStageIndex'] = newGuessStageIndex;
            }
          }
        }
      }

      if (hostId == playerId) {
        if (playerIds.isNotEmpty) {
          final newHostId = playerIds.first;
          updates['hostId'] = newHostId;
          transaction.update(playersColl.doc(newHostId), {'isHost': true});
        } else {
          transaction.delete(roomDoc);
          for (var doc in playersSnap.docs) {
            transaction.delete(doc.reference);
          }
          return;
        }
      }

      // Check if game was in progress and needs to reset
      if (statusStr != 'waiting') {
        final kingId = roomSnap.data()!.containsKey('kingId') ? roomSnap.get('kingId') as String? : null;
        final queenId = roomSnap.data()!.containsKey('queenId') ? roomSnap.get('queenId') as String? : null;
        final ministerId = roomSnap.data()!.containsKey('ministerId') ? roomSnap.get('ministerId') as String? : null;
        final thiefId = roomSnap.data()!.containsKey('thiefId') ? roomSnap.get('thiefId') as String? : null;

        final isKeyRoleLeft = playerId == kingId || playerId == queenId || playerId == ministerId || playerId == thiefId;

        // If player count is less than 4 or a key role player left, reset to lobby
        if (playerIds.length < 4 || isKeyRoleLeft) {
          updates['status'] = 'waiting';
          updates['kingId'] = null;
          updates['queenId'] = null;
          updates['ministerId'] = null;
          updates['thiefId'] = null;
          updates['guardProtectedId'] = null;
          updates['assassinTargetId'] = null;
          updates['fakeQueenDeceivedGuesserId'] = null;
          updates['fakeQueenDeceivedTargetId'] = null;
          updates['guessStageIndex'] = 0;

          // Reset all remaining players' roles and ready status
          for (var doc in playersSnap.docs) {
            if (doc.id != playerId) {
              transaction.update(doc.reference, {
                'currentRole': null,
                'isReady': false,
                'guardUsedThisRound': false,
                'assassinUsedThisRound': false,
              });
            }
          }
        }
      }

      transaction.update(roomDoc, updates);
      transaction.delete(playersColl.doc(playerId));
    });
  }

  Future<void> protectPlayer(String roomId, String guardId, String targetId) async {
    final batch = _db.batch();
    batch.update(_db.collection('rooms').doc(roomId), {
      'guardProtectedId': targetId,
    });
    batch.update(_db.collection('rooms').doc(roomId).collection('players').doc(guardId), {
      'guardUsedThisRound': true,
    });
    await batch.commit();
  }

  Future<void> useAssassinAbility(String roomId, String assassinId, String targetId) async {
    final batch = _db.batch();
    batch.update(_db.collection('rooms').doc(roomId), {
      'assassinTargetId': targetId,
    });
    batch.update(_db.collection('rooms').doc(roomId).collection('players').doc(assassinId), {
      'assassinUsedThisRound': true,
    });
    await batch.commit();
  }

  Future<void> resetRound(String roomId, List<String> playerIds) async {
    final messagesSnap = await _db.collection('rooms').doc(roomId).collection('messages').get();

    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);

    batch.update(roomRef, {
      'status': 'dealing',
      'currentRound': FieldValue.increment(1),
      'kingId': null,
      'queenId': null,
      'ministerId': null,
      'thiefId': null,
      'guardProtectedId': null,
      'assassinTargetId': null,
      'fakeQueenDeceivedGuesserId': null,
      'fakeQueenDeceivedTargetId': null,
      'guessStageIndex': 0,
    });

    for (var id in playerIds) {
      batch.update(roomRef.collection('players').doc(id), {
        'currentRole': null,
        'isReady': false,
        'guardUsedThisRound': false,
        'assassinUsedThisRound': false,
      });
    }

    for (var doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> updatePlayerOnlineStatus(String roomId, String playerId, bool isOnline) async {
    await _db.collection('rooms').doc(roomId).collection('players').doc(playerId).update({
      'isOnline': isOnline,
    });
  }

  Future<void> updatePlayerHeartbeat(String roomId, String playerId) async {
    await _db.collection('rooms').doc(roomId).collection('players').doc(playerId).update({
      'lastSeen': DateTime.now().toIso8601String(),
      'isOnline': true,
    });
  }

  Future<void> sendMessage(String roomId, MessageModel message) async {
    await _db.collection('rooms').doc(roomId).collection('messages').doc(message.id).set(message.toMap());
  }

  Stream<List<MessageModel>> streamMessages(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MessageModel.fromMap(doc.data())).toList());
  }

  List<String> _computeRoleChain(List<PlayerModel> players) {
    final activeRoles = players.map((p) => p.currentRole).whereType<String>().toSet();
    final chain = activeRoles.toList()
      ..sort((a, b) => (GameConstants.roleScores[b] ?? 0).compareTo(GameConstants.roleScores[a] ?? 0));
    return chain;
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
