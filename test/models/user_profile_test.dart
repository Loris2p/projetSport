import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Should create UserProfile with default isAdmin false', () {
      final profile = UserProfile(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Jean Dupont',
        birthDate: DateTime(1995, 5, 20),
      );

      expect(profile.uid, equals('user_123'));
      expect(profile.email, equals('test@example.com'));
      expect(profile.displayName, equals('Jean Dupont'));
      expect(profile.birthDate, equals(DateTime(1995, 5, 20)));
      expect(profile.isAdmin, isFalse);
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final birthDate = DateTime(1990, 10, 15);
      final original = UserProfile(
        uid: 'admin_1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        birthDate: birthDate,
        isAdmin: true,
      );

      final json = original.toJson();
      expect(json['uid'], equals('admin_1'));
      expect(json['email'], equals('admin@example.com'));
      expect(json['displayName'], equals('Admin User'));
      expect(json['birthDate'], equals(birthDate.toIso8601String()));
      expect(json['isAdmin'], isTrue);

      final restored = UserProfile.fromJson(json);
      expect(restored.uid, equals(original.uid));
      expect(restored.email, equals(original.email));
      expect(restored.displayName, equals(original.displayName));
      expect(restored.birthDate, equals(birthDate));
      expect(restored.isAdmin, equals(original.isAdmin));
    });

    test('Should copyWith correctly', () {
      final original = UserProfile(
        uid: 'user_1',
        email: 'user@example.com',
        displayName: 'User',
        birthDate: DateTime(2000, 1, 1),
      );

      final updated = original.copyWith(
        displayName: 'New Name',
        birthDate: DateTime(1999, 12, 31),
      );

      expect(updated.uid, equals('user_1'));
      expect(updated.email, equals('user@example.com'));
      expect(updated.displayName, equals('New Name'));
      expect(updated.birthDate, equals(DateTime(1999, 12, 31)));
    });
  });
}
