import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dating_profile.dart';

class ApiService {
  // Backend base URL (default to localhost:5000 for web & desktop, 10.0.2.2 for android emulator)
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Fetch candidate swipe feed for active user
  static Future<List<DatingProfile>> getFeed({String userId = 'p1'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feed?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List candidatesJson = data['candidates'] ?? [];
        return candidatesJson.map((c) => DatingProfile.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching feed: $e');
      return [];
    }
  }

  // Swipe action (like or pass)
  static Future<Map<String, dynamic>> swipe({
    String likerId = 'p1',
    required String targetId,
    required String action, // 'like' or 'pass'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/swipe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'liker_id': likerId,
          'target_id': targetId,
          'action': action,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error'};
    } catch (e) {
      print('Error recording swipe: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch Minimum Spanning Tree (MST)
  static Future<MstResult?> getMst({String algo = 'kruskal'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mst?algo=$algo'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MstResult.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error fetching MST: $e');
      return null;
    }
  }

  // Fetch Topological Sort & Cohort Stages
  static Future<Map<String, dynamic>?> getTopologicalSort() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topological-sort'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      }
      return null;
    } catch (e) {
      print('Error fetching topological sort: $e');
      return null;
    }
  }

  // Run benchmark suite
  static Future<Map<String, dynamic>?> runBenchmarks() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/benchmarks/run'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error running benchmarks: $e');
      return null;
    }
  }

  // Reset datastore session
  static Future<bool> resetSession() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/reset'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
