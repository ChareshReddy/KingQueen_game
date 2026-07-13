import 'package:flutter_test/flutter_test.dart';
import 'package:king_queen/core/constants/game_constants.dart';
import 'package:king_queen/core/utils/game_utils.dart';

void main() {
  group('GameConstants Tests', () {
    test('Verify all 10 roles are present in scoring map', () {
      final roles = GameConstants.roleScores.keys.toList();
      expect(roles.length, 12 - 2); // 10 roles
      expect(roles.contains('King'), true);
      expect(roles.contains('Queen'), true);
      expect(roles.contains('Minister'), true);
      expect(roles.contains('Spy'), true);
      expect(roles.contains('Joker'), true);
      expect(roles.contains('Guard'), true);
      expect(roles.contains('Fake Queen'), true);
      expect(roles.contains('Assassin'), true);
      expect(roles.contains('Commander'), true);
      expect(roles.contains('Thief'), true);
    });

    test('Verify roles are ordered strictly by score descending', () {
      final scores = GameConstants.roleScores;
      expect(scores['King']! > scores['Queen']!, true);
      expect(scores['Queen']! > scores['Minister']!, true);
      expect(scores['Minister']! > scores['Spy']!, true);
      expect(scores['Spy']! > scores['Joker']!, true);
      expect(scores['Joker']! > scores['Guard']!, true);
      expect(scores['Guard']! > scores['Fake Queen']!, true);
      expect(scores['Fake Queen']! > scores['Assassin']!, true);
      expect(scores['Assassin']! > scores['Commander']!, true);
      expect(scores['Commander']! > scores['Thief']!, true);
      expect(scores['Thief']!, 0);
    });
  });

  group('GameUtils Tests', () {
    test('Verify generateRoomId length and character set constraints', () {
      final code = GameUtils.generateRoomId();
      expect(code.length, 6);
      
      const validChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      for (int i = 0; i < code.length; i++) {
        expect(validChars.contains(code[i]), true);
      }
    });

    test('Verify computeRoleChain sorts roles correctly by points descending', () {
      // 5 players case
      final roles5 = ['Thief', 'Minister', 'Spy', 'King', 'Queen'];
      final chain5 = GameUtils.computeRoleChain(roles5);
      expect(chain5, ['King', 'Queen', 'Minister', 'Spy', 'Thief']);

      // 8 players case
      final roles8 = ['Fake Queen', 'Joker', 'Spy', 'Queen', 'Guard', 'Thief', 'Minister', 'King'];
      final chain8 = GameUtils.computeRoleChain(roles8);
      expect(chain8, ['King', 'Queen', 'Minister', 'Spy', 'Joker', 'Guard', 'Fake Queen', 'Thief']);
    });
  });
}
