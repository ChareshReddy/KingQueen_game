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
    );
  }
}
