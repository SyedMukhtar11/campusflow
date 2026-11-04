import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';

/// Login state for the whole app.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final SessionStorage _storage;
  final ApiClient? _client;

  User? _user;
  bool _initializing = true;
  bool _busy = false;
  String? _error;
  bool _disposed = false;

  /// Completes when the saved session (if any) has been loaded.
  late final Future<void> ready;

  AuthProvider({
    AuthService? service,
    SessionStorage? storage,
    ApiClient? client,
  })  : _service = service ?? ApiAuthService(client),
        _storage = storage ?? MemorySessionStorage(),
        _client = client ?? ApiClient.instance {
    ready = _restore();
  }

  User? get user => _user;
  String? get token => _client?.token;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => isLoggedIn;
  bool get isInitializing => _initializing;
  bool get isBusy => _busy;
  bool get isLoading => _busy;
  String? get error => _error;

  Future<void> _restore() async {
    final saved = await _storage.read();
    if (saved != null) {
      _user = User(name: saved.name, email: saved.email);
      _client?.token = saved.token;
    }
    _initializing = false;
    _safeNotify();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email, password));

  Future<bool> signup(String name, String email, String password) =>
      _run(() => _service.signup(name, email, password));

  Future<bool> _run(Future<AuthResult> Function() action) async {
    _busy = true;
    _error = null;
    _safeNotify();
    try {
      final result = await action();
      _user = result.user;
      _client?.token = result.token;
      await _storage.save(
        token: result.token,
        name: result.user.name,
        email: result.user.email,
      );
      _busy = false;
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    }
    _busy = false;
    _safeNotify();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    _client?.token = null;
    await _storage.clear();
    _safeNotify();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
