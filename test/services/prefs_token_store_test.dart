import 'package:firedart/firedart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_app/services/prefs_token_store.dart';

void main() {
  group('PrefsTokenStore Tests', () {
    late SharedPreferences prefs;
    late PrefsTokenStore tokenStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tokenStore = PrefsTokenStore(prefs);
    });

    test('Should return null when no token is saved in SharedPreferences', () {
      final token = tokenStore.read();
      expect(token, isNull);
    });

    test('Should write token to SharedPreferences and read it back', () {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      final token = Token('user_123', 'fake_id_token', 'fake_refresh_token', expiry);

      tokenStore.write(token);

      final savedJson = prefs.getString('fd_auth_token');
      expect(savedJson, isNotNull);

      final restoredToken = tokenStore.read();
      expect(restoredToken, isNotNull);
      expect(restoredToken?.toMap()['idToken'], equals('fake_id_token'));
    });

    test('Should remove token when write(null) or delete() is called', () {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      final token = Token('user_123', 'fake_id_token', 'fake_refresh_token', expiry);

      tokenStore.write(token);
      expect(prefs.containsKey('fd_auth_token'), isTrue);

      tokenStore.write(null);
      expect(prefs.containsKey('fd_auth_token'), isFalse);

      tokenStore.write(token);
      expect(prefs.containsKey('fd_auth_token'), isTrue);

      tokenStore.delete();
      expect(prefs.containsKey('fd_auth_token'), isFalse);
    });

    test('Should handle corrupt JSON in SharedPreferences gracefully by returning null', () {
      prefs.setString('fd_auth_token', 'invalid_json_{{');
      expect(tokenStore.read(), isNull);
    });
  });
}
