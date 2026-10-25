import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dating_profile.dart';

class ApiService {
  // Current active user ID
  static String activeUserId = 'p1';
  static String activeUserName = 'Aarav Sharma';
  static String activeUserAvatar = 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600';

  // Primary IP from your Wi-Fi interface (for physical Android phone & local network)
  // Also supports 10.0.2.2 (Android Emulator) and 127.0.0.1 (Web / Windows)
  static const String lanHost = '192.168.1.40';
  static const int port = 5000;

  // Primary URL using your machine's Wi-Fi LAN IP
  static String baseUrl = 'http://$lanHost:$port/api';
  static String? lastError;

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
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['user'] != null) {
        activeUserId = data['user']['id'] ?? 'p1';
        activeUserName = data['user']['name'] ?? name;
        activeUserAvatar = data['user']['avatar'] ?? avatar;
      }
      return data;
    } catch (e) {
      lastError = e.toString();
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch candidate swipe feed for active user
  static Future<List<DatingProfile>> getFeed({String? userId}) async {
    final uid = userId ?? activeUserId;
    try {
      final response = await _getWithFallback('/feed?user_id=$uid');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List candidatesJson = data['candidates'] ?? [];
        lastError = null;
        return candidatesJson.map((c) => DatingProfile.fromJson(c)).toList();
      }
      lastError = 'HTTP ${response.statusCode}: ${response.body}';
      return [];
    } catch (e) {
      lastError = e.toString();
      return [];
    }
  }

  // Swipe action (like or pass or superlike)
  static Future<Map<String, dynamic>> swipe({
    String? likerId,
    required String targetId,
    required String action, // 'like', 'pass', 'superlike'
  }) async {
    final uid = likerId ?? activeUserId;
    try {
      final response = await _postWithFallback(
        '/swipe',
        {
          'liker_id': uid,
          'target_id': targetId,
          'action': action,
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error'};
    } catch (e) {
      lastError = e.toString();
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch Minimum Spanning Tree (MST)
  static Future<MstResult?> getMst({String algo = 'kruskal'}) async {
    try {
      final response = await _getWithFallback('/mst?algo=$algo&start_node=$activeUserId');
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
      final res = await http.get(Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) return res;
    } catch (_) {}

    // Fall back through candidate IP addresses
    for (final host in candidateUrls) {
      if (host == baseUrl) continue;
      try {
        final res = await http.get(Uri.parse('$host$path')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          baseUrl = host; // Pin working host
          return res;
        }
      } catch (_) {}
    }

    throw Exception('Cannot reach CupidGraph backend at $baseUrl. Check if python app.py is running on port 5000 and phone is on same Wi-Fi.');
  }

  static Future<http.Response> _postWithFallback(String path, Map<String, dynamic> body) async {
    final headers = {'Content-Type': 'application/json'};
    final encodedBody = json.encode(body);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: encodedBody,
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 201) return res;
    } catch (_) {}

    for (final host in candidateUrls) {
      if (host == baseUrl) continue;
      try {
        final res = await http.post(
          Uri.parse('$host$path'),
          headers: headers,
          body: encodedBody,
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 || res.statusCode == 201) {
          baseUrl = host;
          return res;
        }
      } catch (_) {}
    }

    throw Exception('Cannot reach CupidGraph backend at $baseUrl. Check if python app.py is running on port 5000.');
  }

  // =====================================================================
  // IN-APP OVER-THE-AIR (OTA) AUTO-UPDATE LOGIC
  // =====================================================================
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';

  static Future<Map<String, dynamic>?> checkAppUpdate() async {
    try {
      final res = await _getWithFallback('/app/version');
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final int latestCode = data['latest_version_code'] ?? 1;
          if (latestCode > currentVersionCode) {
            return {
              'hasUpdate': true,
              'latestVersion': data['latest_version'] ?? '1.0.1',
              'releaseNotes': data['release_notes'] ?? 'New features and improvements available!',
              'downloadUrl': '$baseUrl/app/download',
              'isApkAvailable': data['is_apk_available'] ?? false,
              'fileSizeBytes': data['file_size_bytes'] ?? 0,
            };
          }
        }
      }
    } catch (e) {
      // Silently ignore update check errors on network issues
    }
    return null;
  }

  static Future<bool> openApkDownload() async {
    try {
      final downloadUri = Uri.parse('$baseUrl/app/download');
      return await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }
}
