// lib/api/api_client.dart
//
// SECURITY
//  • No Gemini / Hugging Face / Brave / SendGrid / MongoDB credential exists in
//    this app. Every third-party call is proxied by Django's service layer
//    (planner.py, search.py). The Flutter client only ever talks to Django.
//  • Django sessionid + csrftoken live in flutter_secure_storage
//    (Android Keystore / iOS Keychain), never SharedPreferences.
//  • Session auth: CSRF token echoed on unsafe requests, session cookie sent
//    with credentials, so Django's SessionAuthentication identifies the user.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/trip.dart';
import 'mock_backend.dart';

/// true  = offline demo data (works with no backend at all)
/// false = real Django backend at [kApiBaseUrl]
const bool kUseMockBackend = true;

/// Where Django is listening.
///   web / desktop -> http://127.0.0.1:8000
///   Android emu   -> http://10.0.2.2:8000
///   real device   -> http://<your-lan-ip>:8000
/// Override at run time:
///   flutter run --dart-define=API_BASE_URL=https://your-host
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  bool get isUnauthorized => statusCode == 401;
  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({required this.email, this.name = ''});
  final String email;
  final String name;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        email: (json['email'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static const String _kSessionKey = 'ta_session_id';
  static const String _kCsrfKey = 'ta_csrf';
  static const String _kEmailKey = 'ta_email';

  final MockBackend _mock = MockBackend();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
      validateStatus: (code) => code != null && code >= 200 && code < 300,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Web: tell the browser to attach the Django session cookie.
          options.extra['withCredentials'] = true;

          final sid = await _secure.read(key: _kSessionKey);
          final csrf = await _secure.read(key: _kCsrfKey);

          // Mobile is not a browser — replay the cookie ourselves.
          if (!kIsWeb && sid != null) {
            options.headers['Cookie'] =
                csrf == null ? 'sessionid=$sid' : 'sessionid=$sid; csrftoken=$csrf';
          }
          if (csrf != null) {
            options.headers['X-CSRFToken'] = csrf;
          }
          handler.next(options);
        },
      ),
    );

  // ── session helpers ───────────────────────────────────────────────
  Future<String?> savedEmail() => _secure.read(key: _kEmailKey);

  Future<bool> hasSession() async {
    if (kUseMockBackend) return (await _secure.read(key: _kEmailKey)) != null;
    return (await _secure.read(key: _kSessionKey)) != null;
  }

  Future<void> _captureCookies(Map<String, List<String>> headers) async {
    final raw = headers.entries
        .where((e) => e.key.toLowerCase() == 'set-cookie')
        .expand((e) => e.value)
        .join('; ');
    final sid = RegExp(r'sessionid=([^;,\s]+)').firstMatch(raw)?.group(1);
    final csrf = RegExp(r'csrftoken=([^;,\s]+)').firstMatch(raw)?.group(1);
    if (sid != null) await _secure.write(key: _kSessionKey, value: sid);
    if (csrf != null) await _secure.write(key: _kCsrfKey, value: csrf);
  }

  /// Asks Django for a CSRF token. Harmless if the endpoint isn't implemented.
  Future<void> _primeCsrf() async {
    try {
      final res = await _dio.get('/api/auth/csrf/');
      await _captureCookies(res.headers.map);
      final data = res.data;
      if (data is Map && data['csrfToken'] is String) {
        await _secure.write(key: _kCsrfKey, value: data['csrfToken'] as String);
      }
    } catch (_) {
      // Backend may not expose this yet — carry on.
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    final dynamic raw =
        data is Map ? (data['results'] ?? data['data'] ?? const []) : data;
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── auth (/api/auth/*) ────────────────────────────────────────────
  Future<AuthSession> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (kUseMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (password.isEmpty) throw ApiException('Password is required.');
      await _secure.write(key: _kEmailKey, value: cleanEmail);
      return AuthSession(email: cleanEmail, name: 'Demo Traveller');
    }

    try {
      await _primeCsrf();
      final res = await _dio.post(
        '/api/auth/login/',
        data: {'email': cleanEmail, 'password': password},
      );
      await _captureCookies(res.headers.map);
      await _secure.write(key: _kEmailKey, value: cleanEmail);
      final data = res.data;
      return data is Map
          ? AuthSession.fromJson(Map<String, dynamic>.from(data))
          : AuthSession(email: cleanEmail);
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<AuthSession> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (kUseMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (cleanName.isEmpty) throw ApiException('Name is required.');
      if (password.isEmpty) throw ApiException('Password is required.');
      await _secure.write(key: _kEmailKey, value: cleanEmail);
      return AuthSession(email: cleanEmail, name: cleanName);
    }

    try {
      await _primeCsrf();
      final res = await _dio.post(
        '/api/auth/register/',
        data: {'name': cleanName, 'email': cleanEmail, 'password': password},
      );
      await _captureCookies(res.headers.map);
      await _secure.write(key: _kEmailKey, value: cleanEmail);
      final data = res.data;
      return data is Map
          ? AuthSession.fromJson(Map<String, dynamic>.from(data))
          : AuthSession(email: cleanEmail, name: cleanName);
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<void> logout() async {
    if (!kUseMockBackend) {
      try {
        await _dio.post('/api/auth/logout/');
      } catch (_) {
        // best effort — local state is cleared either way
      }
    }
    await _secure.delete(key: _kSessionKey);
    await _secure.delete(key: _kCsrfKey);
    await _secure.delete(key: _kEmailKey);
  }

  // ── destinations (/api/search/ → Brave Search via Django) ─────────
  Future<List<Destination>> searchDestinations(String query) async {
    if (kUseMockBackend) return _mock.searchDestinations(query);
    try {
      final res = await _dio.get('/api/search/', queryParameters: {'q': query});
      return _asList(res.data).map(Destination.fromJson).toList();
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  // ── trips (/api/trips/ → Gemini + HF via Django, Mongo Atlas) ─────
  Future<Trip> generateTrip(PlanRequest request) async {
    if (kUseMockBackend) return _mock.generateTrip(request);
    try {
      final res =
          await _dio.post('/api/trips/generate/', data: request.toJson());
      return Trip.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<List<Trip>> listTrips() async {
    if (kUseMockBackend) return _mock.listTrips();
    try {
      final res = await _dio.get('/api/trips/');
      return _asList(res.data).map(Trip.fromJson).toList();
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<Trip> getTrip(String id) async {
    if (kUseMockBackend) return _mock.getTrip(id);
    try {
      final res = await _dio.get('/api/trips/$id/');
      return Trip.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<Trip> updateTrip(Trip trip) async {
    if (kUseMockBackend) return _mock.updateTrip(trip);
    try {
      final res = await _dio.put('/api/trips/${trip.id}/', data: trip.toJson());
      return Trip.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  Future<void> deleteTrip(String id) async {
    if (kUseMockBackend) return _mock.deleteTrip(id);
    try {
      await _dio.delete('/api/trips/$id/');
    } on DioException catch (e) {
      throw _mapErr(e);
    }
  }

  // ── error mapping ─────────────────────────────────────────────────
  ApiException _mapErr(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('Cannot reach the server. Is Django running?');
      default:
        break;
    }
    final code = e.response?.statusCode;
    var msg = 'Something went wrong.';
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'] ?? data['error'] ?? data['message'];
      if (detail is String && detail.isNotEmpty) msg = detail;
    }
    if (code == 401) msg = 'Session expired. Please sign in again.';
    if (code == 403) msg = 'CSRF check failed. Reload and try again.';
    if (code == 429) msg = 'Too many requests. Please slow down.';
    return ApiException(msg, statusCode: code);
  }
}