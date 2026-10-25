import 'package:flutter/material.dart';

class VivaPrepScreen extends StatelessWidget {
  const VivaPrepScreen({super.key});

  final List<Map<String, String>> _vivaQuestions = const [
    {
      "q": "Q1. What is the core AI problem formulated in CupidGraph?",
      "a": "CupidGraph models human matchmaking as a Graph-Theoretic Compatibility & Link Prediction problem. It synthesizes structural topology (Adamic-Adar, Jaccard), semantic trait embeddings (Cosine Similarity), and heuristic pathfinding (A*) to rank profiles and optimize community cohorts without informational silos."
    },
    {
      "q": "Q2. How is Minimum Spanning Tree (MST) applied to a dating ecosystem?",
      "a": "Given a community or group-dating cohort, pairwise edge weights represent Dissimilarity / Relationship Friction: W(u, v) = 1.0 - MatchScore(u, v). By computing the Minimum Spanning Tree using Kruskal's or Prim's algorithm, CupidGraph extracts the global minimum-friction backbone that connects every member of the cohort with maximum overall affinity, pruning redundant weak links."
    },
    {
      "q": "Q3. Explain how Kahn's Algorithm is used for Relationship Readiness.",
      "a": "Relationship development involves prerequisite psychological milestones (Icebreaker -> Shared Lifestyle -> Core Values -> Long-Term Commitment). By representing these dependencies as a Directed Acyclic Graph (DAG), Kahn's BFS In-degree algorithm verifies that the progression is acyclic and groups users into compatible readiness tiers."
    },
    {
      "q": "Q4. Why is the Adamic-Adar Index preferred over simple Common Friends?",
      "a": "Common friends counts all shared connections equally. In contrast, Adamic-Adar applies an inverse logarithmic penalty: Σ (1 / log(degree(z))). A shared acquaintance with only 2 friends represents a tight, personal social bond with much higher predictive matchmaking value than a shared 'celebrity' friend connected to 500 people."
    },
    {
      "q": "Q5. What is the evaluation function in the A* Social Introduction Path?",
      "a": "The evaluation function is f(n) = g(n) + h(n), where g(n) is the accumulated social relationship friction traversed so far, and h(n) = (1.0 - CosineSimilarity(n, Target)) * scaling_factor. Because cosine distance satisfies the triangle inequality when scaled, h(n) is admissible and consistent, guaranteeing optimal warm introduction paths."
    },
    {
      "q": "Q6. How does CupidGraph handle the Cold-Start problem for new users?",
      "a": "When a new user joins with zero friends in the graph, topological metrics (Adamic-Adar and Jaccard) yield zero. CupidGraph's Hybrid AI engine handles this gracefully by falling back to multi-hot vector Cosine Similarity across lifestyle traits, interests, and readiness stage alignment."
    },
    {
      "q": "Q7. What are the time and space complexities of the core algorithms?",
      "a": "Kruskal's MST: O(E log E) time using Disjoint Set Union (DSU with union by rank and path compression). Prim's MST: O(E log V) time using binary min-heap. Kahn's Topological Sort: O(V + E) time and O(V + E) space. Link prediction per candidate: O(V) time."
    },
    {
      "q": "Q8. How does this project satisfy Course Outcomes CO2, CO3, and CO5?",
      "a": "CO2 (Graph Algorithms & Search): Implemented from scratch via Kruskal/Prim MST, Kahn's DAG sorting, and A* heuristic search. CO3 (Knowledge Representation): Modeled via multi-relational graphs, milestone DAGs, and cycle resolution rules. CO5 (AI Applications): Implemented via feature vector cosine similarity, Adamic-Adar link prediction, and 20% edge-masking benchmark suite."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "CO Mapping & Viva Prep Guide",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Rubric #1 (Relevance - 4 Marks) & Rubric #5 (Viva Voce - 4 Marks)",
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    // Curriculum CO Attainment Table
                    _sectionHeader("CURRICULUM COURSE OUTCOME (CO) ATTAINMENT MATRIX"),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141926),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _coRow("CO2", "Graph Algorithms & Heuristic Search", "Kruskal/Prim MST, Kahn's Sort, A* Social Path", "100%"),
                          const Divider(color: Colors.white12),
                          _coRow("CO3", "Knowledge Representation & Reasoning", "Multi-relational Graph, Milestone DAG, Cycle Rules", "100%"),
                          const Divider(color: Colors.white12),
                          _coRow("CO5", "AI Applications & Machine Learning", "Trait Cosine Vectors, Adamic-Adar Link Prediction", "100%"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Industry Relevance Cards
                    _sectionHeader("INDUSTRIAL RELEVANCE (DATING TECH & SOCIAL RECOMMENDER NETWORKS)"),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141926),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("• Tinder / Hinge Matchmaking: Uses collaborative filtering & reciprocal affinity scores to rank candidate decks.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                          SizedBox(height: 6),
                          Text("• LinkedIn (PYMK): Applies degree-penalized Adamic-Adar to prioritize intimate mutual connections over hyper-connected accounts.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                          SizedBox(height: 6),
                          Text("• Group Cohort Matching: Employs Minimum Spanning Trees (MST) to minimize global relationship friction in team formation.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Viva Voce Accordion
                    _sectionHeader("VIVA VOCE FLASHCARDS (TOP EXAMINER QUESTIONS)"),
                    ..._vivaQuestions.map((q) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ExpansionTile(
                          iconColor: const Color(0xFFFF4458),
                          collapsedIconColor: Colors.white38,
                          title: Text(
                            q['q']!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                q['a']!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coRow(String co, String comp, String impl, String attainment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4458).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(co, style: const TextStyle(color: Color(0xFFFF4458), fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(impl, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Text(attainment, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
