import 'package:flutter/material.dart';
import '../models/dating_profile.dart';
import '../services/api_service.dart';

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  List<DatingProfile> _candidates = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  Offset _cardOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final feed = await ApiService.getFeed(userId: 'p1');
    setState(() {
      _candidates = feed;
      _currentIndex = 0;
      _isLoading = false;
      _cardOffset = Offset.zero;
    });
  }

  Future<void> _handleSwipe(String action) async {
    if (_currentIndex >= _candidates.length) return;
    final currentProfile = _candidates[_currentIndex];

    // Optimistically advance card
    setState(() {
      _currentIndex++;
      _cardOffset = Offset.zero;
    });

    final res = await ApiService.swipe(
      likerId: 'p1',
      targetId: currentProfile.id,
      action: action,
    );

    if (res['is_match'] == true && mounted) {
      _showMatchDialog(currentProfile, res['intro_path_names'] ?? []);
    }
  }

  void _showMatchDialog(DatingProfile profile, List dynamicPath) {
    final path = dynamicPath.cast<String>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E102F), Color(0xFF0F0B18)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFF4458).withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4458).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "IT'S A MATCH!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFFFF4458),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You and ${profile.name} mutually aligned!",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Dual avatar circles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFFF4458),
                    child: const CircleAvatar(
                      radius: 39,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.favorite, color: Color(0xFFFF4458), size: 30),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFFF4458),
                    child: CircleAvatar(
                      radius: 39,
                      backgroundImage: NetworkImage(profile.avatar),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF00F0FF), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${profile.matchScore}% Hybrid AI Match Score",
                      style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (path.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "A* Intro Path: ${path.join(' → ')}",
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Keep Swiping"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4458),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Chat opened with ${profile.name}!")),
                        );
                      },
                      child: const Text("Send Hello 👋"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showWhyMatchSheet(DatingProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141926),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF00F0FF)),
                    const SizedBox(width: 8),
                    Text(
                      "Why ${profile.name}?",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4458).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF4458).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    "${profile.matchScore}% Match",
                    style: const TextStyle(color: Color(0xFFFF4458), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "HYBRID ALGORITHMIC BREAKDOWN (CO3 & CO5):",
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            _metricRow("Profile Vector Cosine Similarity", "${(profile.cosineSimilarity * 100).toInt()}%", Icons.interests),
            _metricRow("Adamic-Adar Social Affinity Index", profile.adamicAdarIndex.toStringAsFixed(2), Icons.people),
            _metricRow("Jaccard Mutual Network Overlap", "${(profile.jaccardSimilarity * 100).toInt()}%", Icons.hub),
            _metricRow("Readiness Stage Alignment", profile.readinessStage, Icons.favorite_border),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.explainableBadges.map((badge) {
                return Chip(
                  label: Text(badge, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white60),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(value, style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4458)));
    }

    if (_currentIndex >= _candidates.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              "No more profiles right now!",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check back later or reset the demo dataset.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4458),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await ApiService.resetSession();
                _loadFeed();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Reset CupidGraph Deck"),
            ),
          ],
        ),
      );
    }

    final profile = _candidates[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Active User Info Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600'),
                          backgroundColor: Colors.grey.shade900,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Aarav Sharma (You)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text("${_candidates.length - _currentIndex} profiles remaining", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _loadFeed,
                      tooltip: "Refresh Feed",
                    ),
                  ],
                ),
              ),

              // Swipeable Card
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cardOffset += details.delta;
                    });
                  },
                  onPanEnd: (details) {
                    if (_cardOffset.dx > 120) {
                      _handleSwipe('like');
                    } else if (_cardOffset.dx < -120) {
                      _handleSwipe('pass');
                    } else {
                      setState(() => _cardOffset = Offset.zero);
                    }
                  },
                  child: Transform.translate(
                    offset: _cardOffset,
                    child: Transform.rotate(
                      angle: _cardOffset.dx / 1000,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Photo
                              Image.network(
                                profile.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.person, size: 80, color: Colors.white24),
                                ),
                              ),

                              // Gradient Overlays
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.2),
                                      Colors.black.withValues(alpha: 0.95),
                                    ],
                                    stops: const [0.4, 0.65, 1.0],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),

                              // Match Score Pill (Top Right)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF4458), Color(0xFFFE4080)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF4458).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${profile.matchScore}% Match",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Like/Dislike Overlay indicators while dragging
                              if (_cardOffset.dx > 40)
                                Positioned(
                                  top: 40,
                                  left: 24,
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.greenAccent, width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text("LIKE", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 24)),
                                    ),
                                  ),
                                ),

                              if (_cardOffset.dx < -40)
                                Positioned(
                                  top: 40,
                                  right: 24,
                                  child: Transform.rotate(
                                    angle: 0.2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFFF4458), width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text("PASS", style: TextStyle(color: Color(0xFFFF4458), fontWeight: FontWeight.bold, fontSize: 24)),
                                    ),
                                  ),
                                ),

                              // Profile Details (Bottom)
                              Positioned(
                                bottom: 20,
                                left: 20,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "${profile.name}, ${profile.age}",
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white54, size: 14),
                                        const SizedBox(width: 4),
                                        Text(profile.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.timeline, color: Colors.amberAccent, size: 14),
                                        const SizedBox(width: 4),
                                        Text(profile.readinessStage, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      profile.bio,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                                    ),
                                    const SizedBox(height: 12),
                                    // Tags
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        ...profile.interests.take(3).map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                            )),
                                        ...profile.lifestyleTraits.take(2).map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(tag, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11)),
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Action Buttons (Pass, Why Match?, Like)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Pass Button
                    FloatingActionButton(
                      heroTag: 'pass_btn',
                      backgroundColor: const Color(0xFF1E293B),
                      onPressed: () => _handleSwipe('pass'),
                      child: const Icon(Icons.close, color: Colors.white60, size: 30),
                    ),

                    // Why Match? (XAI)
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Color(0xFF00F0FF), size: 28),
                      tooltip: "Why Match? (XAI)",
                      onPressed: () => _showWhyMatchSheet(profile),
                    ),

                    // Like Button
                    FloatingActionButton(
                      heroTag: 'like_btn',
                      backgroundColor: const Color(0xFFFF4458),
                      onPressed: () => _handleSwipe('like'),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
