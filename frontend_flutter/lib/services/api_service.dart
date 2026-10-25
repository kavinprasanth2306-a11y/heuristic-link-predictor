import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dating_profile.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for Desktop/Web/Local testing
  // In flutter android run, 10.0.2.2 connects directly to host localhost:5000
  static String baseUrl = 'http://10.0.2.2:5000/api';

  // Fallback to localhost if running on non-android or local unit tests
  static void setCustomBaseUrl(String url) {
    baseUrl = url;
  }

  // Complete onboarding wizard & submit 10-D compatibility vector + photo
  static Future<Map<String, dynamic>> onboardUser({
    required String name,
    required String email,
    required String avatar,
    required int age,
    required String gender,
    required String bio,
    required String location,
    required List<double> vector10d,
  }) async {
    try {
      final response = await _postWithFallback(
        '/auth/onboard',
        {
          'name': name,
          'email': email,
          'avatar': avatar,
          'age': age,
          'gender': gender,
          'bio': bio,
          'location': location,
          'vector_10d': vector10d,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch candidate swipe feed for active user
  static Future<List<DatingProfile>> getFeed({String userId = 'p1'}) async {
    try {
      final response = await _getWithFallback('/feed?user_id=$userId');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List candidatesJson = data['candidates'] ?? [];
        return candidatesJson.map((c) => DatingProfile.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Swipe action (like or pass or superlike)
  static Future<Map<String, dynamic>> swipe({
    String likerId = 'p1',
    required String targetId,
    required String action, // 'like', 'pass', 'superlike'
  }) async {
    try {
      final response = await _postWithFallback(
        '/swipe',
        {
          'liker_id': likerId,
          'target_id': targetId,
          'action': action,
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch Minimum Spanning Tree (MST)
  static Future<MstResult?> getMst({String algo = 'kruskal'}) async {
    try {
      final response = await _getWithFallback('/mst?algo=$algo');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MstResult.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch Topological Sort & Cohort Stages
  static Future<Map<String, dynamic>?> getTopologicalSort() async {
    try {
      final response = await _getWithFallback('/topological-sort');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Run benchmark suite
  static Future<Map<String, dynamic>?> runBenchmarks() async {
    try {
      final response = await _postWithFallback('/benchmarks/run', {});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Reset datastore session
  static Future<bool> resetSession() async {
    try {
      final response = await _postWithFallback('/reset', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Robust network fallback (checks 10.0.2.2 for Android emulator and 127.0.0.1 for desktop/web)
  static Future<http.Response> _getWithFallback(String path) async {
    try {
      return await http.get(Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 4));
    } catch (_) {
      final altUrl = baseUrl.contains('10.0.2.2') ? 'http://127.0.0.1:5000/api' : 'http://10.0.2.2:5000/api';
      return await http.get(Uri.parse('$altUrl$path'));
    }
  }

  static Future<http.Response> _postWithFallback(String path, Map<String, dynamic> body) async {
    final headers = {'Content-Type': 'application/json'};
    try {
      return await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      final altUrl = baseUrl.contains('10.0.2.2') ? 'http://127.0.0.1:5000/api' : 'http://10.0.2.2:5000/api';
      return await http.post(
        Uri.parse('$altUrl$path'),
        headers: headers,
        body: json.encode(body),
      );
    }
  }
}
