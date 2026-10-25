import 'package:flutter/material.dart';

class VivaPrepScreen extends StatelessWidget {
  const VivaPrepScreen({super.key});

  final List<Map<String, String>> _coList = const [
    {
      "code": "CO1",
      "desc": "Intelligent Agent Models & Problem-Solving",
      "impl": "CupidGraph Goal-Based Agent architecture: Evaluates social environment state, perceives multi-user networks, and performs optimal actions (swipes, matches, warm intros).",
      "status": "Attained (100%)"
    },
    {
      "code": "CO2",
      "desc": "Uninformed & Informed Search Techniques",
      "impl": "Uninformed Search (BFS In-Degree for Kahn's Topological Sort) + Informed Heuristic Search (A* Social Introduction Path with admissible Euclidean & Cosine heuristic).",
      "status": "Attained (100%)"
    },
    {
      "code": "CO3",
      "desc": "Knowledge Representation Techniques",
      "impl": "Graph-theoretic adjacency representations, Directed Acyclic Graph (DAG) for relationship milestones, and 10-D multi-relational trait ontology matrices.",
      "status": "Attained (100%)"
    },
    {
      "code": "CO4",
      "desc": "Probabilistic & Rule-Based Reasoning Models",
      "impl": "Rule-based photo/quiz gating validation + Probabilistic link prediction via Adamic-Adar Inverse Log Degree and Jaccard Coefficient under graph uncertainty.",
      "status": "Attained (100%)"
    },
    {
      "code": "CO5",
      "desc": "Machine Learning for Intelligent Decision-Making",
      "impl": "10-D High-Dimensional Vector Embeddings, Cosine Semantic Similarity, and automated 20% edge-masking recommendation evaluation benchmark suite.",
      "status": "Attained (100%)"
    },
  ];

  final List<Map<String, String>> _vivaQuestions = const [
    {
      "q": "Q1. What is the core AI problem formulated in CupidGraph?",
      "a": "CupidGraph models human matchmaking as an AI-driven Graph-Theoretic Compatibility & Link Prediction problem in social networking. It combines structural topology (Adamic-Adar, Jaccard), semantic vector embeddings (Cosine Similarity), and heuristic pathfinding (A*) to rank candidate recommendations and optimize community cohorts without informational silos."
    },
    {
      "q": "Q2. How is Minimum Spanning Tree (MST) applied to social network analysis?",
      "a": "Given a social network cohort, pairwise edge weights represent Dissimilarity / Relationship Friction: W(u, v) = 1.0 - MatchScore(u, v). By computing the Minimum Spanning Tree using Kruskal's or Prim's algorithm, CupidGraph extracts the global minimum-friction backbone that connects every member of the group with maximum overall affinity, pruning redundant weak links."
    },
    {
      "q": "Q3. Explain how Kahn's Topological Sort Algorithm works in the system.",
      "a": "Social relationships involve prerequisite developmental milestones (Icebreaker -> Shared Lifestyle -> Core Values -> Long-Term Commitment). By representing these dependencies as a Directed Acyclic Graph (DAG), Kahn's BFS In-degree algorithm verifies that the progression is strictly acyclic and groups users into compatible readiness tiers."
    },
    {
      "q": "Q4. Why is the Adamic-Adar Index preferred over simple Common Friends in CO4?",
      "a": "Common friends counts all shared connections equally. In contrast, Adamic-Adar applies an inverse logarithmic penalty: SUM(1 / log(degree(z))). A shared acquaintance with only 2 friends represents a tight, personal social bond with much higher predictive matchmaking value than a shared 'celebrity' friend connected to 500 people."
    },
    {
      "q": "Q5. What is the evaluation function in the A* Social Introduction Path (CO2)?",
      "a": "The evaluation function is f(n) = g(n) + h(n), where g(n) is the accumulated social relationship friction traversed so far, and h(n) = (1.0 - CosineSimilarity(n, Target)) * scaling_factor. Because cosine distance satisfies the triangle inequality when scaled, h(n) is admissible and consistent, guaranteeing optimal warm introduction paths."
    },
    {
      "q": "Q6. How does CupidGraph handle the Cold-Start problem for new users (CO5)?",
      "a": "When a new user joins with zero friends in the graph, topological metrics (Adamic-Adar and Jaccard) yield zero. CupidGraph's Hybrid AI engine handles this gracefully by falling back to 10-D feature vector Cosine Similarity across lifestyle traits, interests, and quiz alignment."
    },
    {
      "q": "Q7. What are the time and space complexities of the core algorithms?",
      "a": "Kruskal's MST: O(E log E) time using Disjoint Set Union (DSU with union by rank and path compression). Prim's MST: O(E log V) time using binary min-heap. Kahn's Topological Sort: O(V + E) time and O(V + E) space. Link prediction per candidate: O(V) time."
    },
    {
      "q": "Q8. How does this project satisfy all Course Outcomes (CO1 to CO5)?",
      "a": "CO1: Intelligent Goal-Based Matchmaking Agent. CO2: Informed A* & Uninformed Kahn's BFS search. CO3: Knowledge Representation via Graphs & Milestone DAGs. CO4: Probabilistic Adamic-Adar & Jaccard Reasoning. CO5: 10-D Vector Cosine Similarity & Machine Learning Decision Benchmarking."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.school, color: Color(0xFFFF3366), size: 24),
                        SizedBox(width: 10),
                        Text(
                          "Curriculum COs & Viva Voce",
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Course: 25CS301 - Artificial Intelligence | Integrated COs: CO1, CO2, CO3, CO4, CO5",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    // Project Scope Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "PROJECT SCOPE & INDUSTRY FOCUS",
                            style: TextStyle(color: Color(0xFFBE123C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "This project aligns with social networking platforms and recommendation technologies where intelligent algorithms suggest potential connections between users. Students gain practical exposure to graph-based algorithms such as minimum spanning trees and topological sorting for analyzing network relationships.",
                            style: TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Course Outcomes Matrix
                    _sectionHeader("COURSE OUTCOMES (CO) ATTAINMENT MATRIX"),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: _coList.map((co) {
                          final isLast = _coList.last == co;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF3366),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            co['code']!,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            co['desc']!,
                                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          co['status']!,
                                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      co['impl']!,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Viva Questions Section
                    _sectionHeader("VIVA VOCE QUESTIONS & COMPREHENSIVE JURY ANSWERS"),
                    ..._vivaQuestions.map((q) => _vivaCard(q["q"]!, q["a"]!)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _vivaCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: const Color(0xFFFF3366),
          collapsedIconColor: const Color(0xFF94A3B8),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  answer,
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
