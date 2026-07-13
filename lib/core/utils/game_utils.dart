import 'dart:math';
import '../constants/game_constants.dart';

class GameUtils {
  /// Computes the sorted active-role chain from a list of active role names.
  static List<String> computeRoleChain(Iterable<String> roles) {
    final chain = roles.toList()
      ..sort((a, b) => (GameConstants.roleScores[b] ?? 0).compareTo(GameConstants.roleScores[a] ?? 0));
    return chain;
  }

  /// Generates a 6-character room code.
  static String generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
