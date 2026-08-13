import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  AuthProvider() {
    // Wire 401 responses from anywhere in the app to log out.
    ApiClient.instance.onUnauthorized = _onUnauthorized;
  }

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> restoreSession() async {
    final token = await TokenStorage.instance.read();
    if (token == null) {
      _user = null;
      _error = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await ApiService.me();
      _error = null;
      _status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.instance.clear();
      _user = null;
      _error = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    try {
      final result = await ApiService.login(email, password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to connect. Check your internet connection.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String farmName,
    required String farmLocation,
    required int farmSizeAcres,
  }) async {
    _setBusy(true);
    try {
      _user = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        farmName: farmName,
        farmLocation: farmLocation,
        farmSizeAcres: farmSizeAcres,
      );
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to connect. Check your internet connection.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _onUnauthorized() {
    TokenStorage.instance.clear();
    _user = null;
    _error = 'Session expired. Please log in again.';
    _busy = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
