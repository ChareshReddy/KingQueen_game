import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { waiting, dealing, guessing, reveal, finished }

class RoomModel {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final RoomStatus status;
  final int currentRound;
  final int guessStageIndex;
  final String? kingId;
  final String? queenId;
  final String? ministerId;
  final String? thiefId;
  final String? guardProtectedId;
  final String? assassinTargetId;
  final String? fakeQueenDeceivedGuesserId;
  final String? fakeQueenDeceivedTargetId;
  final DateTime createdAt;
  final DateTime expireAt;

  RoomModel({
    required this.id,
    required this.hostId,
    required this.playerIds,
    this.status = RoomStatus.waiting,
    this.currentRound = 1,
    this.guessStageIndex = 0,
    this.kingId,
    this.queenId,
    this.ministerId,
    this.thiefId,
    this.guardProtectedId,
    this.assassinTargetId,
    this.fakeQueenDeceivedGuesserId,
    this.fakeQueenDeceivedTargetId,
    required this.createdAt,
    DateTime? expireAt,
  }) : expireAt = expireAt ?? createdAt.add(const Duration(hours: 6));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'status': status.name,
      'currentRound': currentRound,
      'guessStageIndex': guessStageIndex,
      'kingId': kingId,
      'queenId': queenId,
      'ministerId': ministerId,
      'thiefId': thiefId,
      'guardProtectedId': guardProtectedId,
      'assassinTargetId': assassinTargetId,
      'fakeQueenDeceivedGuesserId': fakeQueenDeceivedGuesserId,
      'fakeQueenDeceivedTargetId': fakeQueenDeceivedTargetId,
      'createdAt': createdAt.toIso8601String(),
      'expireAt': expireAt, // Firestore SDK saves DateTime directly as a Timestamp!
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] != null) {
      parsedCreatedAt = DateTime.parse(map['createdAt']);
    }
    
    DateTime parsedExpireAt = parsedCreatedAt.add(const Duration(hours: 6));
    if (map['expireAt'] != null) {
      if (map['expireAt'] is Timestamp) {
        parsedExpireAt = (map['expireAt'] as Timestamp).toDate();
      } else {
        parsedExpireAt = DateTime.parse(map['expireAt']);
      }
    }

    return RoomModel(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      playerIds: List<String>.from(map['playerIds'] ?? []),
      status: RoomStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'waiting'),
        orElse: () => RoomStatus.waiting,
      ),
      currentRound: map['currentRound'] ?? 1,
      guessStageIndex: map['guessStageIndex'] ?? 0,
      kingId: map['kingId'],
      queenId: map['queenId'],
      ministerId: map['ministerId'],
      thiefId: map['thiefId'],
      guardProtectedId: map['guardProtectedId'],
      assassinTargetId: map['assassinTargetId'],
      fakeQueenDeceivedGuesserId: map['fakeQueenDeceivedGuesserId'],
      fakeQueenDeceivedTargetId: map['fakeQueenDeceivedTargetId'],
      createdAt: parsedCreatedAt,
      expireAt: parsedExpireAt,
    );
  }

  RoomModel copyWith({
    String? id,
    String? hostId,
    List<String>? playerIds,
    RoomStatus? status,
    int? currentRound,
    int? guessStageIndex,
    String? kingId,
    String? queenId,
    String? ministerId,
    String? thiefId,
    String? guardProtectedId,
    String? assassinTargetId,
    String? fakeQueenDeceivedGuesserId,
    String? fakeQueenDeceivedTargetId,
    DateTime? createdAt,
    DateTime? expireAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      guessStageIndex: guessStageIndex ?? this.guessStageIndex,
      kingId: kingId ?? this.kingId,
      queenId: queenId ?? this.queenId,
      ministerId: ministerId ?? this.ministerId,
      thiefId: thiefId ?? this.thiefId,
      guardProtectedId: guardProtectedId ?? this.guardProtectedId,
      assassinTargetId: assassinTargetId ?? this.assassinTargetId,
      fakeQueenDeceivedGuesserId: fakeQueenDeceivedGuesserId ?? this.fakeQueenDeceivedGuesserId,
      fakeQueenDeceivedTargetId: fakeQueenDeceivedTargetId ?? this.fakeQueenDeceivedTargetId,
      createdAt: createdAt ?? this.createdAt,
      expireAt: expireAt ?? this.expireAt,
    );
  }
}
