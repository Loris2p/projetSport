import 'dart:convert';
import 'package:firedart/firedart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsTokenStore extends TokenStore {
  final SharedPreferences prefs;
  static const String _key = 'fd_auth_token';

  PrefsTokenStore(this.prefs);

  @override
  Token? read() {
    final String? json = prefs.getString(_key);
    if (json == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(json);
      return Token.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  @override
  void write(Token? token) {
    if (token != null) {
      prefs.setString(_key, jsonEncode(token.toMap()));
    } else {
      prefs.remove(_key);
    }
  }

  @override
  void delete() {
    prefs.remove(_key);
  }
}
