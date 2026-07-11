class PlayerModel {
  final String id;
  final String name;
  final String avatarId;
  final int totalScore;
  final int wins;
  final bool isHost;
  final bool isOnline;
  final String? currentRole;
  final bool isReady;
  final bool guardUsedThisRound;
  final bool assassinUsedThisRound;
  final DateTime? lastSeen;

  PlayerModel({
    required this.id,
    required this.name,
    required this.avatarId,
    this.totalScore = 0,
    this.wins = 0,
    this.isHost = false,
    this.isOnline = true,
    this.currentRole,
    this.isReady = false,
    this.guardUsedThisRound = false,
    this.assassinUsedThisRound = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarId': avatarId,
      'totalScore': totalScore,
      'wins': wins,
      'isHost': isHost,
      'isOnline': isOnline,
      'currentRole': currentRole,
      'isReady': isReady,
      'guardUsedThisRound': guardUsedThisRound,
      'assassinUsedThisRound': assassinUsedThisRound,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatarId: map['avatarId'] ?? '1',
      totalScore: map['totalScore'] ?? 0,
      wins: map['wins'] ?? 0,
      isHost: map['isHost'] ?? false,
      isOnline: map['isOnline'] ?? true,
      currentRole: map['currentRole'],
      isReady: map['isReady'] ?? false,
      guardUsedThisRound: map['guardUsedThisRound'] ?? false,
      assassinUsedThisRound: map['assassinUsedThisRound'] ?? false,
      lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
    );
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    String? avatarId,
    int? totalScore,
    int? wins,
    bool? isHost,
    bool? isOnline,
    String? currentRole,
    bool? isReady,
    bool? guardUsedThisRound,
    bool? assassinUsedThisRound,
    DateTime? lastSeen,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      totalScore: totalScore ?? this.totalScore,
      wins: wins ?? this.wins,
      isHost: isHost ?? this.isHost,
      isOnline: isOnline ?? this.isOnline,
      currentRole: currentRole ?? this.currentRole,
      isReady: isReady ?? this.isReady,
      guardUsedThisRound: guardUsedThisRound ?? this.guardUsedThisRound,
      assassinUsedThisRound: assassinUsedThisRound ?? this.assassinUsedThisRound,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
