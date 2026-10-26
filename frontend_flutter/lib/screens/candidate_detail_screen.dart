import 'package:flutter/material.dart';
import '../models/dating_profile.dart';
import 'chat_screen.dart';

class CandidateDetailScreen extends StatelessWidget {
  final DatingProfile profile;

  const CandidateDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar with Back Button
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFFF3366),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            partnerId: profile.id,
                            partnerName: profile.name,
                            partnerAvatar: profile.avatar,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile.avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Icon(Icons.person, size: 100, color: Colors.white24),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F172A).withValues(alpha: 0.3),
                          const Color(0xFF0F172A),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${profile.name}, ${profile.age}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF94A3B8), size: 16),
                            const SizedBox(width: 4),
                            Text(profile.location, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hybrid Match Score Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF3366).withValues(alpha: 0.15),
                          const Color(0xFF6366F1).withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3366),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Match Compatibility", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                Text(
                                  "${profile.matchScore}% Match",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => ChatScreen(
                                  partnerId: profile.id,
                                  partnerName: profile.name,
                                  partnerAvatar: profile.avatar,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text("Message"),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio Section
                  const Text("About Me", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Readiness & Stage
                  const Text("Relationship Readiness Stage", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timeline, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          profile.readinessStage,
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Interests
                  const Text("Passions & Interests", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(tag, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                    )).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Lifestyle Traits
                  const Text("Lifestyle & Vibe", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.lifestyleTraits.map((trait) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                      ),
                      child: Text(trait, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
                    )).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 10-D Feature Vector Radar / Bar Representation
                  const Text("10-D Feature Orthogonal Weights", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("Orthogonal coordinates used for Cosine Angle calculation:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 12),
                  ...List.generate(profile.vector10d.length, (i) {
                    final labels = [
                      "Weekend Energy", "Social Battery", "Relationship Goal", "Communication",
                      "Sleep Cycle", "Athletics", "Travel Curiosity", "Intellectual Spark",
                      "Conflict Resolution", "Pet Affinity"
                    ];
                    final val = profile.vector10d[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              labels[i % labels.length],
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: val.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: const Color(0xFF1E293B),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  i % 2 == 0 ? const Color(0xFFFF3366) : const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              "${(val * 100).toInt()}%",
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
