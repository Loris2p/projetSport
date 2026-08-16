import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/utils/security_utils.dart';

void main() {
  group('SecurityUtils Tests', () {
    test('isValidEmail correctly identifies valid and invalid emails', () {
      expect(SecurityUtils.isValidEmail('test@example.com'), isTrue);
      expect(SecurityUtils.isValidEmail('user.name+tag@sub.domain.org'), isTrue);
      expect(SecurityUtils.isValidEmail('invalid-email'), isFalse);
      expect(SecurityUtils.isValidEmail('test@'), isFalse);
      expect(SecurityUtils.isValidEmail('@domain.com'), isFalse);
      expect(SecurityUtils.isValidEmail(''), isFalse);
      expect(SecurityUtils.isValidEmail(null), isFalse);
    });

    test('validatePassword rejects weak passwords', () {
      expect(SecurityUtils.validatePassword(null), isNotNull);
      expect(SecurityUtils.validatePassword(''), isNotNull);
      expect(SecurityUtils.validatePassword('Short1!'), contains('8 caractères'));
      expect(SecurityUtils.validatePassword('alllowercase1!'), contains('majuscule'));
      expect(SecurityUtils.validatePassword('ALLUPPERCASE1!'), contains('minuscule'));
      expect(SecurityUtils.validatePassword('NoDigitsHere!'), contains('chiffre'));
      expect(SecurityUtils.validatePassword('NoSpecialChars123'), contains('spécial'));
    });

    test('validatePassword accepts strong passwords', () {
      expect(SecurityUtils.validatePassword('StrongP@ssw0rd'), isNull);
      expect(SecurityUtils.validatePassword('Sup3r-Secure!2026'), isNull);
    });

    test('evaluatePasswordStrength returns proper evaluation', () {
      final weak = SecurityUtils.evaluatePasswordStrength('abc');
      expect(weak.label, equals('Faible'));
      expect(weak.isStrongEnough, isFalse);

      final medium = SecurityUtils.evaluatePasswordStrength('Abcdefgh');
      expect(medium.hasMinLength, isTrue);
      expect(medium.hasUppercase, isTrue);
      expect(medium.hasLowercase, isTrue);

      final strong = SecurityUtils.evaluatePasswordStrength('P@ssw0rd2026!');
      expect(strong.label, isIn(['Bon', 'Excellent']));
      expect(strong.isStrongEnough, isTrue);
    });
  });
}
