import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the auth token.
/// Caches the value in memory after the first disk read.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _key = 'auth_token';
  String? _cache;

  Future<String?> read() async {
    _cache ??= (await SharedPreferences.getInstance()).getString(_key);
    return _cache;
  }

  Future<void> write(String token) async {
    _cache = token;
    await (await SharedPreferences.getInstance()).setString(_key, token);
  }

  Future<void> clear() async {
    _cache = null;
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
