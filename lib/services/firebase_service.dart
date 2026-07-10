import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:king_queen/models/message_model.dart';
import 'package:king_queen/models/player_model.dart';
import 'package:king_queen/models/room_model.dart';

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
    final roomSnap = await roomDoc.get();
    
    if (!roomSnap.exists) throw Exception("Room not found");
    
    await roomDoc.update({
      'playerIds': FieldValue.arrayUnion([player.id])
    });
    await roomDoc.collection('players').doc(player.id).set(player.toMap());
  }

  Stream<RoomModel> streamRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots().map((snap) => RoomModel.fromMap(snap.data()!));
  }

  Stream<List<PlayerModel>> streamPlayers(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('players').snapshots().map((snap) {
      return snap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateGameRoles(String roomId, Map<String, String> rolesMap, String kingId, String queenId, String ministerId, String thiefId) async {
    final batch = _db.batch();
    
    batch.update(_db.collection('rooms').doc(roomId), {
      'status': 'playing',
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

  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db.collection('rooms').doc(roomId).update({'status': status});
  }

  Future<void> finishRound(String roomId, List<PlayerModel> players) async {
    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);

    batch.update(roomRef, {'status': 'reveal'});

    for (var player in players) {
      int roundScore = 0;
      switch (player.currentRole) {
        case 'King': roundScore = 1000; break;
        case 'Queen': roundScore = 900; break;
        case 'Minister': roundScore = 500; break;
        case 'Thief': roundScore = 0; break;
      }
      
      batch.update(roomRef.collection('players').doc(player.id), {
        'totalScore': FieldValue.increment(roundScore),
      });
    }

    await batch.commit();
  }

  Future<void> resetRound(String roomId, List<String> playerIds) async {
    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);

    batch.update(roomRef, {
      'status': 'dealing',
      'currentRound': FieldValue.increment(1),
      'kingId': null,
      'queenId': null,
      'ministerId': null,
      'thiefId': null,
    });

    for (var id in playerIds) {
      batch.update(roomRef.collection('players').doc(id), {
        'currentRole': null,
        'isReady': false,
      });
    }

    await batch.commit();
  }

  Future<void> swapRolesAndContinue(String roomId, String kingId, String otherId) async {
    final kingDoc = _db.collection('rooms').doc(roomId).collection('players').doc(kingId);
    final otherDoc = _db.collection('rooms').doc(roomId).collection('players').doc(otherId);

    await _db.runTransaction((transaction) async {
      final kingSnap = await transaction.get(kingDoc);
      final otherSnap = await transaction.get(otherDoc);

      final kingRole = kingSnap.get('currentRole');
      final otherRole = otherSnap.get('currentRole');

      transaction.update(kingDoc, {'currentRole': otherRole});
      transaction.update(otherDoc, {'currentRole': kingRole});
      
      // Map role to its ID field in the room document
      String? roleToField(String role) {
        switch (role) {
          case 'King': return 'kingId';
          case 'Queen': return 'queenId';
          case 'Minister': return 'ministerId';
          case 'Thief': return 'thiefId';
          default: return null;
        }
      }

      final kingField = roleToField(kingRole);
      final otherField = roleToField(otherRole);

      if (kingField != null) {
        transaction.update(_db.collection('rooms').doc(roomId), {kingField: otherId});
      }
      if (otherField != null) {
        transaction.update(_db.collection('rooms').doc(roomId), {otherField: kingId});
      }
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

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
