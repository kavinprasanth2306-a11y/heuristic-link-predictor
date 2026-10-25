// Models for CupidGraph Dating Profiles & Algorithmic Payloads

class DatingProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String bio;
  final String location;
  final String avatar;
  final String readinessStage;
  final List<String> lifestyleTraits;
  final List<String> interests;
  final List<String> mutualConnections;
  
  // AI Prediction Attributes
  final double matchScore;
  final double cosineSimilarity;
  final double adamicAdarIndex;
  final double jaccardSimilarity;
  final int mutualFriendsCount;
  final List<String> sharedTraits;
  final List<String> sharedInterests;
  final List<String> explainableBadges;
  final List<String> introPath;
  final List<String> introPathNames;
  final double introPathCost;

  DatingProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bio,
    required this.location,
    required this.avatar,
    required this.readinessStage,
    required this.lifestyleTraits,
    required this.interests,
    required this.mutualConnections,
    this.matchScore = 0.0,
    this.cosineSimilarity = 0.0,
    this.adamicAdarIndex = 0.0,
    this.jaccardSimilarity = 0.0,
    this.mutualFriendsCount = 0,
    this.sharedTraits = const [],
    this.sharedInterests = const [],
    this.explainableBadges = const [],
    this.introPath = const [],
    this.introPathNames = const [],
    this.introPathCost = 0.0,
  });

  factory DatingProfile.fromJson(Map<String, dynamic> json) {
    return DatingProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 20,
      gender: json['gender'] ?? 'Female',
      bio: json['bio'] ?? '',
      location: json['location'] ?? 'Bengaluru',
      avatar: json['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
      readinessStage: json['readiness_stage'] ?? 'Icebreaker',
      lifestyleTraits: List<String>.from(json['lifestyle_traits'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      mutualConnections: List<String>.from(json['mutual_connections'] ?? []),
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
      cosineSimilarity: (json['cosine_similarity'] ?? 0.0).toDouble(),
      adamicAdarIndex: (json['adamic_adar_index'] ?? 0.0).toDouble(),
      jaccardSimilarity: (json['jaccard_similarity'] ?? 0.0).toDouble(),
      mutualFriendsCount: json['mutual_friends_count'] ?? 0,
      sharedTraits: List<String>.from(json['shared_traits'] ?? []),
      sharedInterests: List<String>.from(json['shared_interests'] ?? []),
      explainableBadges: List<String>.from(json['explainable_badges'] ?? []),
      introPath: List<String>.from(json['intro_path'] ?? []),
      introPathNames: List<String>.from(json['intro_path_names'] ?? []),
      introPathCost: (json['intro_path_cost'] ?? 0.0).toDouble(),
    );
  }
}

class MstResult {
  final String algorithm;
  final double totalCost;
  final int totalEdges;
  final int mstEdgesCount;
  final int edgesPruned;
  final double prunePercentage;
  final double executionTimeMs;
  final String timeComplexity;
  final List<Map<String, dynamic>> mstEdges;
  final List<Map<String, dynamic>> steps;

  MstResult({
    required this.algorithm,
    required this.totalCost,
    required this.totalEdges,
    required this.mstEdgesCount,
    required this.edgesPruned,
    required this.prunePercentage,
    required this.executionTimeMs,
    required this.timeComplexity,
    required this.mstEdges,
    required this.steps,
  });

  factory MstResult.fromJson(Map<String, dynamic> json) {
    return MstResult(
      algorithm: json['algorithm'] ?? 'Kruskal\'s MST',
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      totalEdges: json['total_edges'] ?? 0,
      mstEdgesCount: json['mst_edges_count'] ?? 0,
      edgesPruned: json['edges_pruned'] ?? 0,
      prunePercentage: (json['prune_percentage'] ?? 0.0).toDouble(),
      executionTimeMs: (json['execution_time_ms'] ?? 0.0).toDouble(),
      timeComplexity: json['time_complexity'] ?? 'O(E log V)',
      mstEdges: List<Map<String, dynamic>>.from(json['mst_edges'] ?? []),
      steps: List<Map<String, dynamic>>.from(json['steps'] ?? []),
    );
  }
}
