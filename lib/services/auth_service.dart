import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

typedef AuthUser = User;

class AuthResult {
  final User user;
  final String? token;
  const AuthResult(this.user, this.token);
}

abstract class AuthService {
  factory AuthService([ApiClient? client]) = ApiAuthService;
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> signup(String name, String email, String password);
}

class ApiAuthService implements AuthService {
  final ApiClient _client;
  ApiAuthService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  @override
  Future<AuthResult> login(String email, String password) async {
    final dynamic response = await _client.post(
      ApiConfig.loginPath,
      body: {'email': email.trim(), 'password': password},
    );
    final token = response['token']?.toString();
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    if (token != null) _client.setAuthToken(token);
    return AuthResult(user, token);
  }

  @override
  Future<AuthResult> signup(String name, String email, String password) async {
    final dynamic response = await _client.post(
      ApiConfig.signupPath,
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    final token = response['token']?.toString();
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    if (token != null) _client.setAuthToken(token);
    return AuthResult(user, token);
  }
}

class MockAuthService implements AuthService {
  final Duration delay;
  const MockAuthService({this.delay = const Duration(milliseconds: 600)});

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future.delayed(delay);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    await _wait();
    if (!email.contains('@') || password.length < 6) {
      throw const ApiException('Invalid email or password.', 401);
    }
    return AuthResult(
      User(
        id: 'mock_user_1',
        name: _nameFromEmail(email),
        email: email,
        createdAt: DateTime.now(),
      ),
      'demo-token',
    );
  }

  @override
  Future<AuthResult> signup(String name, String email, String password) async {
    await _wait();
    if (name.trim().isEmpty || !email.contains('@') || password.length < 6) {
      throw const ApiException('Please check your details and try again.', 400);
    }
    return AuthResult(
      User(
        id: 'mock_user_1',
        name: name.trim(),
        email: email,
        createdAt: DateTime.now(),
      ),
      'demo-token',
    );
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Learner';
    return local[0].toUpperCase() + local.substring(1);
  }
}
