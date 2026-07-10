enum RoomStatus { waiting, dealing, playing, guessing_minister, guessing_thief, reveal, finished }

class RoomModel {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final RoomStatus status;
  final int currentRound;
  final String? kingId;
  final String? queenId;
  final String? ministerId;
  final String? thiefId;
  final String? guardProtectedId;
  final String? assassinTargetId;
  final String? jokerBluffRole;
  final String? jokerBluffPlayerId;
  final String? fakeQueenDeceivedGuesserId;
  final String? fakeQueenDeceivedTargetId;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.hostId,
    required this.playerIds,
    this.status = RoomStatus.waiting,
    this.currentRound = 1,
    this.kingId,
    this.queenId,
    this.ministerId,
    this.thiefId,
    this.guardProtectedId,
    this.assassinTargetId,
    this.jokerBluffRole,
    this.jokerBluffPlayerId,
    this.fakeQueenDeceivedGuesserId,
    this.fakeQueenDeceivedTargetId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'status': status.name,
      'currentRound': currentRound,
      'kingId': kingId,
      'queenId': queenId,
      'ministerId': ministerId,
      'thiefId': thiefId,
      'guardProtectedId': guardProtectedId,
      'assassinTargetId': assassinTargetId,
      'jokerBluffRole': jokerBluffRole,
      'jokerBluffPlayerId': jokerBluffPlayerId,
      'fakeQueenDeceivedGuesserId': fakeQueenDeceivedGuesserId,
      'fakeQueenDeceivedTargetId': fakeQueenDeceivedTargetId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      playerIds: List<String>.from(map['playerIds'] ?? []),
      status: RoomStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'waiting'),
        orElse: () => RoomStatus.waiting,
      ),
      currentRound: map['currentRound'] ?? 1,
      kingId: map['kingId'],
      queenId: map['queenId'],
      ministerId: map['ministerId'],
      thiefId: map['thiefId'],
      guardProtectedId: map['guardProtectedId'],
      assassinTargetId: map['assassinTargetId'],
      jokerBluffRole: map['jokerBluffRole'],
      jokerBluffPlayerId: map['jokerBluffPlayerId'],
      fakeQueenDeceivedGuesserId: map['fakeQueenDeceivedGuesserId'],
      fakeQueenDeceivedTargetId: map['fakeQueenDeceivedTargetId'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  RoomModel copyWith({
    String? id,
    String? hostId,
    List<String>? playerIds,
    RoomStatus? status,
    int? currentRound,
    String? kingId,
    String? queenId,
    String? ministerId,
    String? thiefId,
    String? guardProtectedId,
    String? assassinTargetId,
    String? jokerBluffRole,
    String? jokerBluffPlayerId,
    String? fakeQueenDeceivedGuesserId,
    String? fakeQueenDeceivedTargetId,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      kingId: kingId ?? this.kingId,
      queenId: queenId ?? this.queenId,
      ministerId: ministerId ?? this.ministerId,
      thiefId: thiefId ?? this.thiefId,
      guardProtectedId: guardProtectedId ?? this.guardProtectedId,
      assassinTargetId: assassinTargetId ?? this.assassinTargetId,
      jokerBluffRole: jokerBluffRole ?? this.jokerBluffRole,
      jokerBluffPlayerId: jokerBluffPlayerId ?? this.jokerBluffPlayerId,
      fakeQueenDeceivedGuesserId: fakeQueenDeceivedGuesserId ?? this.fakeQueenDeceivedGuesserId,
      fakeQueenDeceivedTargetId: fakeQueenDeceivedTargetId ?? this.fakeQueenDeceivedTargetId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
