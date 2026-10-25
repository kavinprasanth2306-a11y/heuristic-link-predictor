import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dating_profile.dart';

class ApiService {
  // Primary IP from your Wi-Fi interface (for physical Android phone & local network)
  // Also supports 10.0.2.2 (Android Emulator) and 127.0.0.1 (Web / Windows)
  static const String lanHost = '192.168.1.40';
  static const int port = 5000;

  // Primary URL using your machine's Wi-Fi LAN IP
  static String baseUrl = 'http://$lanHost:$port/api';

  // Candidate base URLs to query in fallback order
  static final List<String> candidateUrls = [
    'http://192.168.1.40:5000/api',  // Physical Android device over Wi-Fi
    'http://10.0.2.2:5000/api',      // Android Emulator host loopback
    'http://127.0.0.1:5000/api',     // Web & Desktop localhost
    'http://localhost:5000/api',     // Standard localhost
  ];

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

  // Multi-target fallback network handler
  static Future<http.Response> _getWithFallback(String path) async {
    // Try current baseUrl first
    try {
      return await http.get(Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 3));
    } catch (_) {}

    // Fall back through candidate IP addresses
    for (final host in candidateUrls) {
      if (host == baseUrl) continue;
      try {
        final res = await http.get(Uri.parse('$host$path')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          baseUrl = host; // Pin working host
          return res;
        }
      } catch (_) {}
    }

    throw Exception('Failed to connect to backend on any candidate IP.');
  }

  static Future<http.Response> _postWithFallback(String path, Map<String, dynamic> body) async {
    final headers = {'Content-Type': 'application/json'};
    final encodedBody = json.encode(body);

    try {
      return await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: encodedBody,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    for (final host in candidateUrls) {
      if (host == baseUrl) continue;
      try {
        final res = await http.post(
          Uri.parse('$host$path'),
          headers: headers,
          body: encodedBody,
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200 || res.statusCode == 201) {
          baseUrl = host;
          return res;
        }
      } catch (_) {}
    }

    throw Exception('Failed to post to backend on any candidate IP.');
  }
}
