"""
CupidGraph Algorithmic Engine
Course: 25CS301 - Artificial Intelligence
Integrated COs: CO2 (Graph Algorithms & Search), CO3 (Knowledge Representation), CO5 (AI Applications)

From-scratch implementations:
1. Minimum Spanning Tree (MST):
   - Kruskal's Algorithm with Disjoint Set Union (DSU with union by rank and path compression)
   - Prim's Algorithm with Binary Min-Heap Priority Queue
   - Cost Metric: Dissimilarity / Friction = 1.0 - Compatibility_Score (or round(10.0 / score, 3))
   - Use Case: Social Cohort / Group Dating Optimization to connect individuals with minimal friction.

2. Topological Sorting (Relationship Readiness & Milestone Progression):
   - Kahn's Algorithm (BFS In-degree)
   - Cycle detection and feedback resolution
   - Progression tiers: Icebreaker -> Lifestyle Compatibility -> Core Values -> Long-Term Commitment

3. Hybrid AI Compatibility & Link Prediction Engine (CO3, CO5):
   - Multi-hot vector Cosine Similarity over lifestyle traits and interests
   - Adamic-Adar Index over mutual social circles
   - Jaccard Similarity on mutual friends
   - Weighted Hybrid Match Score (0 - 100%)
   - Explainable AI (XAI) reason badges

4. A* Social Introduction Path Finder (CO2):
   - Shortest trusted route between two users
   - f(n) = g(n) + h(n), where g(n) is social distance resistance, h(n) is profile cosine dissimilarity
"""

import math
import heapq
import time
from collections import deque, defaultdict
import numpy as np

# =====================================================================
# 1. DISJOINT SET UNION (DSU) FOR KRUSKAL'S MST
# =====================================================================
class DisjointSetUnion:
    """Disjoint Set Union (DSU) with Path Compression and Union by Rank.
    Time Complexity: O(alpha(V)) ~ O(1) amortized.
    """
    def __init__(self, elements):
        self.parent = {elem: elem for elem in elements}
        self.rank = {elem: 0 for elem in elements}

    def find(self, i):
        if self.parent[i] == i:
            return i
        self.parent[i] = self.find(self.parent[i])
        return self.parent[i]

    def union(self, root1, root2):
        if self.rank[root1] < self.rank[root2]:
            self.parent[root1] = root2
        elif self.rank[root1] > self.rank[root2]:
            self.parent[root2] = root1
        else:
            self.parent[root2] = root1
            self.rank[root1] += 1


# =====================================================================
# 2. HYBRID COMPATIBILITY & LINK PREDICTION (CO3, CO5)
# =====================================================================
def compute_profile_cosine_similarity(profile_u, profile_v, vocabulary=None):
    """
    Computes Cosine Similarity between two user profile vectors
    based on multi-hot encoded lifestyle traits and interests.
    Cosine Similarity = (A . B) / (||A|| * ||B||)
    """
    if vocabulary is None:
        vocabulary = list(set(
            profile_u.get("lifestyle_traits", []) + profile_u.get("interests", []) +
            profile_v.get("lifestyle_traits", []) + profile_v.get("interests", [])
        ))

    if not vocabulary:
        return 0.0

    vec_u = [1 if (t in profile_u.get("lifestyle_traits", []) or t in profile_u.get("interests", [])) else 0 for t in vocabulary]
    vec_v = [1 if (t in profile_v.get("lifestyle_traits", []) or t in profile_v.get("interests", [])) else 0 for t in vocabulary]

    dot_product = sum(u * v for u, v in zip(vec_u, vec_v))
    norm_u = math.sqrt(sum(u * u for u in vec_u))
    norm_v = math.sqrt(sum(v * v for v in vec_v))

    if norm_u == 0 or norm_v == 0:
        return 0.0
    return round(dot_product / (norm_u * norm_v), 4)


def compute_adamic_adar_index(u_id, v_id, mutual_dict):
    """
    Adamic-Adar Index on mutual social connections:
    Sum of 1 / log(degree(z)) for all mutual friends z.
    Shared acquaintances with small degrees represent tighter, higher-intimacy bonds.
    """
    friends_u = set(mutual_dict.get(u_id, []))
    friends_v = set(mutual_dict.get(v_id, []))
    shared = friends_u.intersection(friends_v)

    score = 0.0
    for z in shared:
        deg = len(mutual_dict.get(z, []))
        if deg > 1:
            score += 1.0 / math.log(deg)
        elif deg == 1:
            score += 1.0
    return round(score, 4), list(shared)


def compute_jaccard_similarity(u_id, v_id, mutual_dict):
    """Jaccard coefficient on mutual social network: |N(u) n N(v)| / |N(u) U N(v)|"""
    friends_u = set(mutual_dict.get(u_id, []))
    friends_v = set(mutual_dict.get(v_id, []))
    intersection_len = len(friends_u.intersection(friends_v))
    union_len = len(friends_u.union(friends_v))
    if union_len == 0:
        return 0.0
    return round(intersection_len / union_len, 4)


def calculate_match_score(profile_u, profile_v, mutual_dict, all_vocabulary=None):
    """
    Computes calibrated Hybrid Compatibility Match Score (0 to 100%)
    Score = w1 * Cosine + w2 * AdamicAdar_Norm + w3 * Jaccard + w4 * ReadinessAlignment
    """
    u_id, v_id = profile_u["id"], profile_v["id"]
    
    # 1. Trait & Interest Cosine Similarity
    cosine_sim = compute_profile_cosine_similarity(profile_u, profile_v, all_vocabulary)
    
    # 2. Social Graph Adamic-Adar & Jaccard
    aa_score, mutual_friends = compute_adamic_adar_index(u_id, v_id, mutual_dict)
    jaccard_sim = compute_jaccard_similarity(u_id, v_id, mutual_dict)
    
    # Normalize Adamic-Adar to [0, 1] range (typical threshold ~ 2.0)
    aa_norm = min(aa_score / 2.0, 1.0)

    # 3. Relationship Readiness Alignment bonus
    stage_u = profile_u.get("readiness_stage", "Icebreaker")
    stage_v = profile_v.get("readiness_stage", "Icebreaker")
    readiness_bonus = 1.0 if stage_u == stage_v else 0.6

    # Weighted Hybrid Formula
    # 45% Lifestyle/Interests Cosine, 25% Adamic-Adar mutual circle, 15% Jaccard, 15% Readiness Stage
    raw_score = (
        0.45 * cosine_sim +
        0.25 * aa_norm +
        0.15 * jaccard_sim +
        0.15 * readiness_bonus
    ) * 100.0

    score = round(min(max(raw_score, 40.0), 98.5), 1)

    # Shared tags for Explainable AI (XAI)
    shared_traits = list(set(profile_u.get("lifestyle_traits", [])).intersection(set(profile_v.get("lifestyle_traits", []))))
    shared_interests = list(set(profile_u.get("interests", [])).intersection(set(profile_v.get("interests", []))))

    # Reason Badges
    badges = []
    if len(mutual_friends) > 0:
        badges.append(f"{len(mutual_friends)} Mutual Friend{'s' if len(mutual_friends) > 1 else ''}")
    if shared_interests:
        badges.append(f"Shared: {', '.join(shared_interests[:2])}")
    if shared_traits:
        badges.append(f"Lifestyle: {', '.join(shared_traits[:2])}")
    if stage_u == stage_v:
        badges.append(f"Aligned Stage: {stage_u}")

    if not badges:
        badges.append("High Emerging Chemistry")

    return {
        "match_score": score,
        "cosine_similarity": cosine_sim,
        "adamic_adar_index": aa_score,
        "jaccard_similarity": jaccard_sim,
        "mutual_friends_count": len(mutual_friends),
        "mutual_friends_ids": mutual_friends,
        "shared_traits": shared_traits,
        "shared_interests": shared_interests,
        "explainable_badges": badges,
        "dissimilarity_cost": round(1.0 - (score / 100.0), 3)
    }


# =====================================================================
# 3. A* HEURISTIC SHORTEST TRUSTED INTRODUCTION PATH (CO2)
# =====================================================================
def a_star_social_intro_path(start_id, target_id, profiles_dict, mutual_dict):
    """
    A* Heuristic Search for Shortest Trusted Mutual Introduction Route:
    f(n) = g(n) + h(n)
    where:
      g(n) = Cumulative social relationship friction along chain
      h(n) = Admissible heuristic = (1.0 - CosineSimilarity(n, target)) * 2.0
    """
    if start_id == target_id:
        return [start_id], 0.0

    target_profile = profiles_dict.get(target_id)
    if not target_profile:
        return [], float('inf')

    def heuristic(node_id):
        curr_p = profiles_dict.get(node_id)
        if not curr_p:
            return 1.0
        sim = compute_profile_cosine_similarity(curr_p, target_profile)
        return round((1.0 - sim) * 2.0, 3)

    pq = [(heuristic(start_id), 0.0, start_id, [start_id])]
    g_scores = {start_id: 0.0}
    visited = set()

    while pq:
        f, g, current, path = heapq.heappop(pq)

        if current == target_id:
            return path, round(g, 3)

        if current in visited and g > g_scores.get(current, float('inf')):
            continue
        visited.add(current)

        for neighbor in mutual_dict.get(current, []):
            if neighbor not in profiles_dict:
                continue

            # Friction edge weight based on mutual match
            match_res = calculate_match_score(profiles_dict[current], profiles_dict[neighbor], mutual_dict)
            edge_friction = match_res["dissimilarity_cost"] + 0.2

            tentative_g = g + edge_friction
            if tentative_g < g_scores.get(neighbor, float('inf')):
                g_scores[neighbor] = tentative_g
                h = heuristic(neighbor)
                f_score = tentative_g + h
                heapq.heappush(pq, (f_score, tentative_g, neighbor, path + [neighbor]))

    return [], float('inf')


# =====================================================================
# 4. MINIMUM SPANNING TREE (MST) — GROUP MATCHING BACKBONE (CO2)
# =====================================================================
def run_kruskals_mst(nodes, edges_with_costs):
    """
    Kruskal's Algorithm for Minimum Spanning Tree (MST).
    Minimizes total dissimilarity friction to extract the optimal community backbone.
    
    Time Complexity: O(E log E) or O(E log V)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    steps = []

    # Sort edges primarily by non-decreasing cost
    sorted_edges = sorted(edges_with_costs, key=lambda x: x["cost"])
    dsu = DisjointSetUnion(nodes)

    mst_edges = []
    total_cost = 0.0
    discarded_edges = []

    for edge in sorted_edges:
        u, v, cost = edge["source"], edge["target"], edge["cost"]
        root_u = dsu.find(u)
        root_v = dsu.find(v)

        if root_u != root_v:
            dsu.union(root_u, root_v)
            mst_edges.append(edge)
            total_cost += cost
            steps.append({
                "step": len(steps) + 1,
                "action": "ADDED",
                "edge": f"{u} — {v}",
                "cost": cost,
                "affinity_score": edge.get("score", round((1.0 - cost) * 100, 1)),
                "reason": f"Unified clusters {root_u} and {root_v} with minimal dissimilarity"
            })
        else:
            discarded_edges.append(edge)
            steps.append({
                "step": len(steps) + 1,
                "action": "REJECTED",
                "edge": f"{u} — {v}",
                "cost": cost,
                "reason": "Redundant connection; cluster already spanned"
            })

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    edges_pruned = len(edges_with_costs) - len(mst_edges)

    return {
        "algorithm": "Kruskal's MST",
        "mst_edges": mst_edges,
        "total_cost": round(total_cost, 3),
        "total_edges": len(edges_with_costs),
        "mst_edges_count": len(mst_edges),
        "edges_pruned": edges_pruned,
        "prune_percentage": round((edges_pruned / max(len(edges_with_costs), 1)) * 100, 1),
        "execution_time_ms": elapsed_ms,
        "steps": steps,
        "time_complexity": "O(E log E)",
        "space_complexity": "O(V + E)"
    }


def run_prims_mst(nodes, edges_with_costs, start_node=None):
    """
    Prim's Algorithm for Minimum Spanning Tree with Binary Min-Heap Priority Queue.
    Grows connected match backbone from an initial seed profile.
    
    Time Complexity: O(E log V)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    if not nodes:
        return {"algorithm": "Prim's MST", "mst_edges": [], "total_cost": 0, "execution_time_ms": 0}

    adj = {n: [] for n in nodes}
    for e in edges_with_costs:
        u, v, cost = e["source"], e["target"], e["cost"]
        score = e.get("score", round((1.0 - cost) * 100, 1))
        adj[u].append((v, cost, score))
        adj[v].append((u, cost, score))

    if not start_node or start_node not in nodes:
        start_node = nodes[0]

    visited = set([start_node])
    mst_edges = []
    total_cost = 0.0
    steps = [{
        "step": 1,
        "action": "SEED_NODE",
        "node": start_node,
        "reason": f"Initialized community backbone from seed profile {start_node}"
    }]

    pq = []
    for neighbor, cost, score in adj[start_node]:
        heapq.heappush(pq, (cost, start_node, neighbor, score))

    while pq and len(visited) < len(nodes):
        cost, u, v, score = heapq.heappop(pq)
        if v in visited:
            continue

        visited.add(v)
        mst_edges.append({
            "source": u,
            "target": v,
            "cost": cost,
            "score": score
        })
        total_cost += cost
        steps.append({
            "step": len(steps) + 1,
            "action": "ADDED",
            "edge": f"{u} — {v}",
            "cost": cost,
            "affinity_score": score,
            "reason": f"Expanded frontier cut to encompass profile {v}"
        })

        for next_node, next_cost, next_score in adj[v]:
            if next_node not in visited:
                heapq.heappush(pq, (next_cost, v, next_node, next_score))

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    edges_pruned = len(edges_with_costs) - len(mst_edges)

    return {
        "algorithm": "Prim's MST",
        "start_node": start_node,
        "mst_edges": mst_edges,
        "total_cost": round(total_cost, 3),
        "total_edges": len(edges_with_costs),
        "mst_edges_count": len(mst_edges),
        "edges_pruned": edges_pruned,
        "prune_percentage": round((edges_pruned / max(len(edges_with_costs), 1)) * 100, 1),
        "execution_time_ms": elapsed_ms,
        "steps": steps,
        "time_complexity": "O(E log V)",
        "space_complexity": "O(V + E)"
    }


# =====================================================================
# 5. TOPOLOGICAL SORTING (RELATIONSHIP MILESTONES & DAG) (CO2, CO3)
# =====================================================================
def run_kahns_readiness_sort(nodes, directed_milestone_edges):
    """
    Kahn's Algorithm (BFS In-degree) on Relationship Milestone DAG.
    Validates prerequisite ordering:
    Icebreaker -> Lifestyle Compatibility -> Core Values -> Long-Term Commitment
    
    Time Complexity: O(V + E)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    adj = {n: [] for n in nodes}
    in_degree = {n: 0 for n in nodes}

    for edge in directed_milestone_edges:
        u, v = edge[0], edge[1]
        if u in adj and v in in_degree:
            adj[u].append(v)
            in_degree[v] += 1

    initial_in_degrees = dict(in_degree)
    queue = deque([n for n in nodes if in_degree[n] == 0])
    topological_order = []
    hierarchy_layers = []

    while queue:
        layer_size = len(queue)
        this_layer = []
        for _ in range(layer_size):
            curr = queue.popleft()
            topological_order.append(curr)
            this_layer.append(curr)

            for neighbor in adj[curr]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)
        if this_layer:
            hierarchy_layers.append(this_layer)

    has_cycle = len(topological_order) != len(nodes)
    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)

    return {
        "algorithm": "Kahn's Topological Sort",
        "topological_order": topological_order,
        "hierarchy_layers": hierarchy_layers,
        "initial_in_degrees": initial_in_degrees,
        "has_cycle": has_cycle,
        "execution_time_ms": elapsed_ms,
        "time_complexity": "O(V + E)",
        "space_complexity": "O(V + E)"
    }
