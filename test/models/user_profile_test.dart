import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Should create UserProfile with default isAdmin false', () {
      final profile = UserProfile(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Jean Dupont',
      );

      expect(profile.uid, equals('user_123'));
      expect(profile.email, equals('test@example.com'));
      expect(profile.displayName, equals('Jean Dupont'));
      expect(profile.isAdmin, isFalse);
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final original = UserProfile(
        uid: 'admin_1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        isAdmin: true,
      );

      final json = original.toJson();
      expect(json['uid'], equals('admin_1'));
      expect(json['email'], equals('admin@example.com'));
      expect(json['displayName'], equals('Admin User'));
      expect(json['isAdmin'], isTrue);

      final restored = UserProfile.fromJson(json);
      expect(restored.uid, equals(original.uid));
      expect(restored.email, equals(original.email));
      expect(restored.displayName, equals(original.displayName));
      expect(restored.isAdmin, equals(original.isAdmin));
    });
  });
}
