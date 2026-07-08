import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'navigation_service.dart';

class ApiService {
  static const _baseUrl = 'http://192.168.10.103:5000/api/v1';

  // ── Helper principal ──────────────────────────────
  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool useRefresh = false,
    bool isRetry = false,
  }) async {
    final token = useRefresh
        ? await StorageService.getRefreshToken()
        : await StorageService.getAccessToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl$path');
    final encoded = body != null ? jsonEncode(body) : null;

    late http.Response res;
    switch (method) {
      case 'GET':    res = await http.get(uri, headers: headers); break;
      case 'POST':   res = await http.post(uri, headers: headers, body: encoded); break;
      case 'PUT':    res = await http.put(uri, headers: headers, body: encoded); break;
      case 'DELETE': res = await http.delete(uri, headers: headers); break;
      default:       throw Exception('método HTTP inválido');
    }

    if (res.statusCode == 401 && !useRefresh && !isRetry) {
      final ok = await _refreshToken();
      if (ok) return _request(method, path, body: body, isRetry: true);
      await StorageService.clearTokens();
      NavigationService.goToLogin();
      throw Exception('session_expired');
    }

    return res;
  }

  static Future<bool> _refreshToken() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null) return false;

    final res = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final current = await StorageService.getRefreshToken();
      await StorageService.saveTokens(data['access_token'], current!);
      return true;
    }
    return false;
  }

  // ── Auth ──────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> register(String name, String email, String username, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'username': username, 'password': password}),
    );
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<void> logout() async {
    try { await _request('POST', '/auth/logout', useRefresh: true); } catch (_) {}
    await StorageService.clearTokens();
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _request('GET', '/auth/me');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  // ── Babies ────────────────────────────────────────
  static Future<Map<String, dynamic>> getBabies() async {
    final res = await _request('GET', '/babies/');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> createBaby(String name, String birthDate) async {
    final res = await _request('POST', '/babies/', body: {'name': name, 'birth_date': birthDate});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> getBabyStatus(int babyId) async {
    final res = await _request('GET', '/babies/$babyId/status');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> updateBaby(int babyId, String name, String birthDate) async {
    final res = await _request('PUT', '/babies/$babyId', body: {'name': name, 'birth_date': birthDate});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<int> deleteBaby(int babyId) async {
    final res = await _request('DELETE', '/babies/$babyId');
    return res.statusCode;
  }

  // ── Feedings ──────────────────────────────────────
  static Future<Map<String, dynamic>> getFeedings(int babyId) async {
    final res = await _request('GET', '/babies/$babyId/feedings/');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> startFeeding(int babyId) async {
    final res = await _request('POST', '/babies/$babyId/feedings/start', body: {});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> finishFeeding(int feedingId) async {
    final res = await _request('POST', '/feedings/$feedingId/finish', body: {});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<int> deleteFeeding(int feedingId) async {
    final res = await _request('DELETE', '/feedings/$feedingId');
    return res.statusCode;
  }

  static Future<Map<String, dynamic>> updateFeeding(
    int feedingId, {
    String? startedAt,
    String? endedAt,
    String? type,
    String? side,
    int? volumeMl,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'started_at': ?startedAt,
      'ended_at': ?endedAt,
      'type': ?type,
      'side': ?side,
      'volume_ml': ?volumeMl,
      'note': ?note,
    };
    final res = await _request('PUT', '/feedings/$feedingId', body: body);
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  // ── Naps ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getNaps(int babyId) async {
    final res = await _request('GET', '/babies/$babyId/naps/');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> startNap(int babyId) async {
    final res = await _request('POST', '/babies/$babyId/naps/start', body: {});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> finishNap(int napId) async {
    final res = await _request('POST', '/naps/$napId/finish', body: {});
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> updateNap(
    int napId, {
    String? startedAt,
    String? endedAt,
    String? location,
    String? lightEnvironment,
    bool? whiteNoise,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'started_at': ?startedAt,
      'ended_at': ?endedAt,
      'location': ?location,
      'light_environment': ?lightEnvironment,
      'white_noise': ?whiteNoise,
      'note': ?note,
    };
    final res = await _request('PUT', '/naps/$napId', body: body);
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<int> deleteNap(int napId) async {
    final res = await _request('DELETE', '/naps/$napId');
    return res.statusCode;
  }

  // ── Diapers ───────────────────────────────────────
  static Future<Map<String, dynamic>> getDiapers(int babyId) async {
    final res = await _request('GET', '/babies/$babyId/diapers/');
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> registerDiaper(
    int babyId, {
    String? changedAt,
    String? type,
    String? consistency,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'changed_at': ?changedAt,
      'type': ?type,
      'consistency': ?consistency,
      'note': ?note,
    };
    final res = await _request('POST', '/babies/$babyId/diapers/', body: body);
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> updateDiaper(
    int diaperId, {
    String? changedAt,
    String? type,
    String? consistency,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'changed_at': ?changedAt,
      'type': ?type,
      'consistency': ?consistency,
      'note': ?note,
    };
    final res = await _request('PUT', '/diapers/$diaperId', body: body);
    return {'status': res.statusCode, 'data': jsonDecode(res.body)};
  }

  static Future<int> deleteDiaper(int diaperId) async {
    final res = await _request('DELETE', '/diapers/$diaperId');
    return res.statusCode;
  }
}
