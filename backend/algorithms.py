"""
CupidGraph Algorithmic Engine
Course: 25CS301 - Artificial Intelligence
Integrated COs: CO2 (Graph Algorithms & Search), CO3 (Knowledge Representation), CO5 (AI Applications)

Features:
1. True 10-Dimensional Vector Cosine Similarity (CO5)
2. Adamic-Adar Degree-Penalized Link Prediction Index (CO3)
3. Jaccard Similarity on Mutual Connections
4. Kruskal's & Prim's Minimum Spanning Tree (MST) on Relationship Friction (CO2)
5. Kahn's Topological Sort with Cycle Detection on Readiness DAG (CO2, CO3)
6. A* Heuristic Shortest Trusted Introduction Path (CO2)
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
# 2. REAL 10-D VECTOR COSINE SIMILARITY & HYBRID AI SCORING (CO5)
# =====================================================================
def compute_vector_10d_cosine_similarity(vec_a, vec_b):
    """
    Computes true Cosine Similarity between two normalized 10-D preference vectors:
    Cosine Sim = (A . B) / (||A|| * ||B||)
    """
    if not vec_a or not vec_b or len(vec_a) != len(vec_b):
        return 0.5

    dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
    norm_a = math.sqrt(sum(a * a for a in vec_a))
    norm_b = math.sqrt(sum(b * b for b in vec_b))

    if norm_a == 0 or norm_b == 0:
        return 0.0
    return round(dot_product / (norm_a * norm_b), 4)


def compute_profile_cosine_similarity(p1, p2):
    """
    Computes cosine similarity between two profiles either via vector_10d if present,
    or via one-hot encoded lifestyle_traits and interests.
    """
    if "vector_10d" in p1 and "vector_10d" in p2:
        return compute_vector_10d_cosine_similarity(p1["vector_10d"], p2["vector_10d"])

    features_1 = set(p1.get("lifestyle_traits", []) + p1.get("interests", []))
    features_2 = set(p2.get("lifestyle_traits", []) + p2.get("interests", []))

    if not features_1 or not features_2:
        return 0.0

    all_features = sorted(list(features_1.union(features_2)))
    v1 = [1 if f in features_1 else 0 for f in all_features]
    v2 = [1 if f in features_2 else 0 for f in all_features]

    dot = sum(a * b for a, b in zip(v1, v2))
    norm1 = math.sqrt(sum(a * a for a in v1))
    norm2 = math.sqrt(sum(b * b for b in v2))
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return round(dot / (norm1 * norm2), 4)


def compute_adamic_adar_index(u_id, v_id, mutual_dict):
    """
    Adamic-Adar Index on mutual social connections:
    Sum of 1 / log(degree(z)) for all mutual friends z.
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
    friends_u = set(mutual_dict.get(u_id, []))
    friends_v = set(mutual_dict.get(v_id, []))
    intersection_len = len(friends_u.intersection(friends_v))
    union_len = len(friends_u.union(friends_v))
    if union_len == 0:
        return 0.0
    return round(intersection_len / union_len, 4)


def calculate_match_score(profile_u, profile_v, mutual_dict):
    """
    Computes calibrated Hybrid Compatibility Match Score (0 to 100%)
    Score = w1 * 10D_Cosine + w2 * AdamicAdar_Norm + w3 * Jaccard + w4 * ReadinessAlignment
    """
    u_id, v_id = profile_u["id"], profile_v["id"]
    
    # 1. Real 10-D Vector Cosine Similarity
    vec_u = profile_u.get("vector_10d", [0.5] * 10)
    vec_v = profile_v.get("vector_10d", [0.5] * 10)
    cosine_sim = compute_vector_10d_cosine_similarity(vec_u, vec_v)
    
    # 2. Social Topology (Adamic-Adar + Jaccard)
    aa_score, mutual_friends = compute_adamic_adar_index(u_id, v_id, mutual_dict)
    jaccard_sim = compute_jaccard_similarity(u_id, v_id, mutual_dict)
    aa_norm = min(aa_score / 2.0, 1.0)

    # 3. Relationship Readiness Alignment bonus
    stage_u = profile_u.get("readiness_stage", "Icebreaker / Quiz")
    stage_v = profile_v.get("readiness_stage", "Icebreaker / Quiz")
    readiness_bonus = 1.0 if stage_u == stage_v else 0.6

    # Weighted Hybrid Formula
    raw_score = (
        0.50 * cosine_sim +
        0.25 * aa_norm +
        0.10 * jaccard_sim +
        0.15 * readiness_bonus
    ) * 100.0

    score = round(min(max(raw_score, 45.0), 98.8), 1)

    # Explainable AI (XAI) Badges
    shared_traits = list(set(profile_u.get("lifestyle_traits", [])).intersection(set(profile_v.get("lifestyle_traits", []))))
    shared_interests = list(set(profile_u.get("interests", [])).intersection(set(profile_v.get("interests", []))))

    badges = []
    badges.append(f"{int(cosine_sim * 100)}% 10-D Value Match")
    if len(mutual_friends) > 0:
        badges.append(f"{len(mutual_friends)} Mutual Social Bridge{'s' if len(mutual_friends) > 1 else ''}")
    if shared_interests:
        badges.append(f"Shared: {shared_interests[0]}")
    if stage_u == stage_v:
        badges.append(f"Stage: {stage_u}")

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
    """
    if start_id == target_id:
        return [start_id], 0.0

    target_profile = profiles_dict.get(target_id)
    if not target_profile:
        return [], float('inf')

    target_vec = target_profile.get("vector_10d", [0.5] * 10)

    def heuristic(node_id):
        curr_p = profiles_dict.get(node_id)
        if not curr_p:
            return 1.0
        sim = compute_vector_10d_cosine_similarity(curr_p.get("vector_10d", []), target_vec)
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
    start_time = time.perf_counter()
    steps = []
    sorted_edges = sorted(edges_with_costs, key=lambda x: x["cost"])
    dsu = DisjointSetUnion(nodes)

    mst_edges = []
    total_cost = 0.0

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
                "reason": f"Unified clusters with minimal dissimilarity"
            })
        else:
            steps.append({
                "step": len(steps) + 1,
                "action": "REJECTED",
                "edge": f"{u} — {v}",
                "cost": cost,
                "reason": "Redundant connection; cycle pruned"
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
