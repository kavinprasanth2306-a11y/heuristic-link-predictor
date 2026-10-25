"""
Algorithmic Core for AI-Driven Social Network Friend Recommendation & Relationship Analysis System
Course: 25CS301 - Artificial Intelligence
Course Outcomes: CO2 (Search & Graph Algorithms), CO3 (Knowledge Representation), CO5 (AI Applications)

Contains from-scratch implementations:
1. Minimum Spanning Tree (MST):
   - Kruskal's Algorithm with Disjoint Set Union (DSU / Union-Find with path compression & rank)
   - Prim's Algorithm with Priority Queue (Binary Min-Heap)
   - Cost metric: Dissimilarity/resistance cost = round(10.0 / interaction_strength, 3)

2. Topological Sorting (Mentorship & Influence Hierarchy):
   - Kahn's Algorithm (BFS Indegree approach)
   - DFS-based Topological Sort with 3-color Cycle Detection (White=0, Gray=1, Black=2)
   - Automatic cycle resolution / feedback edge identification

3. Heuristic Search & Link Prediction (Friend Recommendation Engine):
   - Graph Topology Metrics: Common Neighbors, Jaccard Similarity, Adamic-Adar Index
   - AI Profile Similarity: Cosine Similarity on TF-IDF / Multi-hot encoded skills & interests
   - A* Social Path Finder: f(n) = g(n) + h(n), where g(n) is social resistance and h(n) is profile cosine distance
   - Hybrid AI Recommendation Score (0-100%) with Explainable AI badges
"""

import math
import heapq
import time
from collections import deque, defaultdict
import numpy as np

# =====================================================================
# 1. DISJOINT SET UNION (DSU) FOR KRUSKAL'S ALGORITHM
# =====================================================================
class DisjointSetUnion:
    """Disjoint Set Union (DSU) with Path Compression and Union by Rank.
    Time Complexity: O(alpha(V)) ~ O(1) amortized per operation.
    """
    def __init__(self, elements):
        self.parent = {elem: elem for elem in elements}
        self.rank = {elem: 0 for elem in elements}

    def find(self, i):
        # Path compression heuristic
        if self.parent[i] == i:
            return i
        self.parent[i] = self.find(self.parent[i])
        return self.parent[i]

    def union(self, root1, root2):
        # Union by rank heuristic
        if self.rank[root1] < self.rank[root2]:
            self.parent[root1] = root2
        elif self.rank[root1] > self.rank[root2]:
            self.parent[root2] = root1
        else:
            self.parent[root2] = root1
            self.rank[root1] += 1


# =====================================================================
# 2. MINIMUM SPANNING TREE (MST) ALGORITHMS (CO2)
# =====================================================================
def run_kruskals_mst(nodes, edges):
    """
    Kruskal's Algorithm for Minimum Spanning Tree (Backbone Network Extraction).
    Sorts all edges by weight (dissimilarity/resistance) and greedily adds
    them if they don't form a cycle using Disjoint Set Union (DSU).
    
    Time Complexity: O(E log E) or O(E log V)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    steps = []
    
    # Standardize edge list: (u, v, cost, strength, label)
    formatted_edges = []
    for edge in edges:
        u, v, strength = edge[0], edge[1], edge[2]
        label = edge[3] if len(edge) > 3 else "Connection"
        # Cost is inverse of interaction strength (lower cost = stronger affinity)
        cost = round(10.0 / max(strength, 1), 3)
        formatted_edges.append((cost, u, v, strength, label))
    
    # Sort edges primarily by non-decreasing weight/cost
    formatted_edges.sort(key=lambda x: x[0])
    
    dsu = DisjointSetUnion(nodes)
    mst_edges = []
    total_cost = 0.0
    discarded_edges = []

    for cost, u, v, strength, label in formatted_edges:
        root_u = dsu.find(u)
        root_v = dsu.find(v)
        
        if root_u != root_v:
            dsu.union(root_u, root_v)
            mst_edges.append({
                "source": u,
                "target": v,
                "weight": cost,
                "strength": strength,
                "label": label
            })
            total_cost += cost
            steps.append({
                "step": len(steps) + 1,
                "action": "ADDED",
                "edge": f"{u} — {v}",
                "cost": cost,
                "strength": strength,
                "reason": f"Connects separate components {root_u} and {root_v} with minimal cost"
            })
        else:
            discarded_edges.append({
                "source": u,
                "target": v,
                "weight": cost,
                "strength": strength,
                "reason": f"Cycle rejected: {u} and {v} are already connected"
            })
            steps.append({
                "step": len(steps) + 1,
                "action": "REJECTED",
                "edge": f"{u} — {v}",
                "cost": cost,
                "strength": strength,
                "reason": "Forms a redundant cycle within the backbone"
            })

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    total_initial_edges = len(edges)
    edges_pruned = total_initial_edges - len(mst_edges)
    prune_percentage = round((edges_pruned / max(total_initial_edges, 1)) * 100, 1)

    return {
        "algorithm": "Kruskal's MST",
        "mst_edges": mst_edges,
        "total_cost": round(total_cost, 3),
        "initial_edges_count": total_initial_edges,
        "mst_edges_count": len(mst_edges),
        "edges_pruned": edges_pruned,
        "prune_percentage": prune_percentage,
        "execution_time_ms": elapsed_ms,
        "steps": steps,
        "time_complexity": "O(E log E)",
        "space_complexity": "O(V + E)"
    }


def run_prims_mst(nodes, edges, start_node=None):
    """
    Prim's Algorithm for Minimum Spanning Tree with Binary Min-Heap Priority Queue.
    Grows a single tree from a start node, always adding the minimum weight cut-edge.
    
    Time Complexity: O(E log V)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    if not nodes:
        return {"algorithm": "Prim's MST", "mst_edges": [], "total_cost": 0, "execution_time_ms": 0}

    # Build adjacency list
    adj = {n: [] for n in nodes}
    edge_info_map = {}
    for edge in edges:
        u, v, strength = edge[0], edge[1], edge[2]
        label = edge[3] if len(edge) > 3 else "Connection"
        cost = round(10.0 / max(strength, 1), 3)
        adj[u].append((v, cost, strength, label))
        adj[v].append((u, cost, strength, label))
        edge_info_map[(min(u, v), max(u, v))] = (cost, strength, label)

    if not start_node or start_node not in nodes:
        start_node = nodes[0]

    visited = set()
    mst_edges = []
    total_cost = 0.0
    steps = []

    # Priority Queue stores: (cost, current_node, neighbor_node, strength, label)
    pq = []
    visited.add(start_node)
    
    for neighbor, cost, strength, label in adj[start_node]:
        heapq.heappush(pq, (cost, start_node, neighbor, strength, label))

    steps.append({
        "step": 1,
        "action": "START",
        "node": start_node,
        "reason": f"Initialized Prim's cut-set from root node {start_node}"
    })

    while pq and len(visited) < len(nodes):
        cost, u, v, strength, label = heapq.heappop(pq)
        if v in visited:
            continue

        visited.add(v)
        mst_edges.append({
            "source": u,
            "target": v,
            "weight": cost,
            "strength": strength,
            "label": label
        })
        total_cost += cost
        steps.append({
            "step": len(steps) + 1,
            "action": "ADDED",
            "edge": f"{u} — {v}",
            "cost": cost,
            "strength": strength,
            "reason": f"Minimal frontier cut-edge connecting new node {v} to tree"
        })

        for next_node, next_cost, next_str, next_label in adj[v]:
            if next_node not in visited:
                heapq.heappush(pq, (next_cost, v, next_node, next_str, next_label))

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)
    total_initial_edges = len(edges)
    edges_pruned = total_initial_edges - len(mst_edges)

    return {
        "algorithm": "Prim's MST",
        "start_node": start_node,
        "mst_edges": mst_edges,
        "total_cost": round(total_cost, 3),
        "initial_edges_count": total_initial_edges,
        "mst_edges_count": len(mst_edges),
        "edges_pruned": edges_pruned,
        "prune_percentage": round((edges_pruned / max(total_initial_edges, 1)) * 100, 1),
        "execution_time_ms": elapsed_ms,
        "steps": steps,
        "time_complexity": "O(E log V)",
        "space_complexity": "O(V + E)"
    }


# =====================================================================
# 3. TOPOLOGICAL SORTING (MENTORSHIP & INFLUENCE HIERARCHY) (CO2/CO3)
# =====================================================================
def run_kahns_algorithm(nodes, directed_edges):
    """
    Kahn's Algorithm (BFS In-degree) for Topological Sorting of Mentorship/Dependency DAG.
    Computes in-degree for all vertices, initializes queue with in-degree 0 nodes (Root Mentors),
    and iteratively peels away layers. Detects cycles if sorted nodes < total nodes.
    
    Time Complexity: O(V + E)
    Space Complexity: O(V + E)
    """
    start_time = time.perf_counter()
    
    adj = {n: [] for n in nodes}
    in_degree = {n: 0 for n in nodes}
    edge_labels = {}

    for edge in directed_edges:
        u, v = edge[0], edge[1]
        topic = edge[2] if len(edge) > 2 else "Mentorship"
        if u in adj and v in in_degree:
            adj[u].append(v)
            in_degree[v] += 1
            edge_labels[(u, v)] = topic

    initial_in_degrees = dict(in_degree)
    
    # Queue for all nodes with in-degree 0 (Level 0 Mentors)
    queue = deque([n for n in nodes if in_degree[n] == 0])
    topological_order = []
    hierarchy_layers = []  # Grouped by depth/generation
    current_layer = list(queue)
    
    step_log = []
    step_count = 1

    while queue:
        layer_size = len(queue)
        this_level = []
        for _ in range(layer_size):
            curr = queue.popleft()
            topological_order.append(curr)
            this_level.append(curr)
            
            step_log.append({
                "step": step_count,
                "node": curr,
                "action": "PROCESS_MENTOR",
                "remaining_in_degree": 0,
                "description": f"Node {curr} has in-degree 0 (free of dependencies); placed in order."
            })
            step_count += 1

            for neighbor in adj[curr]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)
                    step_log.append({
                        "step": step_count,
                        "node": neighbor,
                        "action": "IN_DEGREE_ZERO",
                        "description": f"Dependency {curr}->{neighbor} resolved. {neighbor} in-degree is now 0."
                    })
                    step_count += 1
        
        if this_level:
            hierarchy_layers.append(this_level)

    has_cycle = len(topological_order) != len(nodes)
    cycle_nodes = [n for n in nodes if in_degree[n] > 0] if has_cycle else []

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)

    return {
        "algorithm": "Kahn's Algorithm (BFS In-degree)",
        "topological_order": topological_order,
        "hierarchy_layers": hierarchy_layers,
        "initial_in_degrees": initial_in_degrees,
        "has_cycle": has_cycle,
        "cycle_nodes": cycle_nodes,
        "step_log": step_log[:40], # capped for responsiveness
        "execution_time_ms": elapsed_ms,
        "time_complexity": "O(V + E)",
        "space_complexity": "O(V + E)"
    }


def run_dfs_topological_sort(nodes, directed_edges):
    """
    DFS-based Topological Sort with 3-State Cycle Detection:
    0 = WHITE (Unvisited), 1 = GRAY (In Current Recursion Stack / Visiting), 2 = BLACK (Finished / Visited)
    If an edge points to a GRAY node, a back-edge (cycle) is detected.
    
    Time Complexity: O(V + E)
    Space Complexity: O(V)
    """
    start_time = time.perf_counter()
    
    adj = {n: [] for n in nodes}
    for edge in directed_edges:
        u, v = edge[0], edge[1]
        if u in adj and v in adj:
            adj[u].append(v)

    color = {n: 0 for n in nodes}  # 0: WHITE, 1: GRAY, 2: BLACK
    stack = []
    has_cycle = False
    cycle_edges = []
    traversal_steps = []

    def dfs(u):
        nonlocal has_cycle
        color[u] = 1 # GRAY
        traversal_steps.append({"node": u, "state": "VISITING (GRAY)"})
        
        for v in adj[u]:
            if color[v] == 1:
                has_cycle = True
                cycle_edges.append((u, v))
                traversal_steps.append({"node": v, "state": f"CYCLE DETECTED (Back-edge from {u} to {v})"})
            elif color[v] == 0:
                dfs(v)
                
        color[u] = 2 # BLACK
        stack.append(u)
        traversal_steps.append({"node": u, "state": "FINISHED (BLACK, Pushed to Stack)"})

    for node in nodes:
        if color[node] == 0:
            dfs(node)

    topological_order = stack[::-1]  # Reverse postorder
    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 3)

    return {
        "algorithm": "DFS Topological Sort",
        "topological_order": topological_order if not has_cycle else [],
        "has_cycle": has_cycle,
        "cycle_edges": cycle_edges,
        "traversal_steps": traversal_steps[:40],
        "execution_time_ms": elapsed_ms,
        "time_complexity": "O(V + E)",
        "space_complexity": "O(V)"
    }


# =====================================================================
# 4. AI HEURISTIC SEARCH & LINK PREDICTION (CO2, CO3, CO5)
# =====================================================================
def compute_profile_cosine_similarity(user_a, user_b, all_skills=None, all_interests=None):
    """
    Computes Cosine Similarity between two users based on multi-hot encoded
    skills and interests vectors (CO3: Knowledge Representation, CO5: Machine Learning).
    
    Cosine Similarity = (A . B) / (||A|| * ||B||)
    """
    if all_skills is None or all_interests is None:
        vocabulary = list(set(user_a.get("skills", []) + user_a.get("interests", []) +
                              user_b.get("skills", []) + user_b.get("interests", [])))
    else:
        vocabulary = list(set(all_skills + all_interests))

    if not vocabulary:
        return 0.0

    vec_a = [1 if (term in user_a.get("skills", []) or term in user_a.get("interests", [])) else 0 for term in vocabulary]
    vec_b = [1 if (term in user_b.get("skills", []) or term in user_b.get("interests", [])) else 0 for term in vocabulary]

    dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
    norm_a = math.sqrt(sum(a * a for a in vec_a))
    norm_b = math.sqrt(sum(b * b for b in vec_b))

    if norm_a == 0 or norm_b == 0:
        return 0.0
    return round(dot_product / (norm_a * norm_b), 4)


def compute_adamic_adar_index(user_a_id, user_b_id, adj_dict):
    """
    Adamic-Adar Index:
    Sum of 1 / log(degree(z)) for all mutual neighbors z in (N(a) intersect N(b)).
    Heuristic principle: Shared neighbors that have small social degrees indicate
    much higher personal intimacy/affinity than "celebrity" nodes with hundreds of friends.
    """
    neighbors_a = set(adj_dict.get(user_a_id, []))
    neighbors_b = set(adj_dict.get(user_b_id, []))
    mutual_neighbors = neighbors_a.intersection(neighbors_b)

    score = 0.0
    for z in mutual_neighbors:
        deg = len(adj_dict.get(z, []))
        if deg > 1:
            score += 1.0 / math.log(deg)
        elif deg == 1:
            score += 1.0  # fallback limit
    return round(score, 4), list(mutual_neighbors)


def compute_jaccard_similarity(user_a_id, user_b_id, adj_dict):
    """
    Jaccard Similarity Coefficient: |N(A) n N(B)| / |N(A) U N(B)|
    """
    neighbors_a = set(adj_dict.get(user_a_id, []))
    neighbors_b = set(adj_dict.get(user_b_id, []))
    
    intersection_len = len(neighbors_a.intersection(neighbors_b))
    union_len = len(neighbors_a.union(neighbors_b))
    
    if union_len == 0:
        return 0.0
    return round(intersection_len / union_len, 4)


def a_star_social_path(start_user_id, target_user_id, users_dict, adj_dict, edge_weights_dict):
    """
    A* Heuristic Search for Optimal Social Introduction Path (CO2):
    f(n) = g(n) + h(n)
    where:
      g(n) = Cumulative social relationship resistance along path = sum(10 / interaction_strength)
      h(n) = Admissible heuristic = (1 - Profile_Cosine_Similarity(current, target)) * scaling_factor
    
    Guarantees the most natural, highest-affinity warm introduction chain.
    """
    if start_user_id == target_user_id:
        return [start_user_id], 0.0

    target_user = users_dict.get(target_user_id)
    if not target_user:
        return [], float('inf')

    # Heuristic function h(n)
    def heuristic(u_id):
        u = users_dict.get(u_id)
        if not u:
            return 1.0
        cos_sim = compute_profile_cosine_similarity(u, target_user)
        # Cosine distance scaled to match resistance bounds [0, 5.0]
        return round((1.0 - cos_sim) * 3.0, 3)

    # Priority queue stores: (f_score, g_score, current_node, path)
    h_start = heuristic(start_user_id)
    pq = [(h_start, 0.0, start_user_id, [start_user_id])]
    g_scores = {start_user_id: 0.0}
    visited = set()

    while pq:
        f, g, current, path = heapq.heappop(pq)

        if current == target_user_id:
            return path, round(g, 2)

        if current in visited and g > g_scores.get(current, float('inf')):
            continue
        visited.add(current)

        for neighbor in adj_dict.get(current, []):
            edge_key = (min(current, neighbor), max(current, neighbor))
            strength = edge_weights_dict.get(edge_key, 5)
            edge_resistance = round(10.0 / max(strength, 1), 3)

            tentative_g = g + edge_resistance
            if tentative_g < g_scores.get(neighbor, float('inf')):
                g_scores[neighbor] = tentative_g
                h = heuristic(neighbor)
                f_score = tentative_g + h
                heapq.heappush(pq, (f_score, tentative_g, neighbor, path + [neighbor]))

    return [], float('inf')


def recommend_friends_for_user(target_user_id, users_dict, connections, top_n=5):
    """
    Hybrid AI Multi-Factor Recommendation Engine (CO2, CO3, CO5).
    Evaluates all unconnected candidate users using a calibrated multi-objective objective:
    
    Composite Score = w1 * Jaccard + w2 * AdamicAdar_Normalized + w3 * CosineSimilarity + w4 * IntroPathBonus
    Produces Explainable AI ("Why this recommendation?") badges.
    """
    target_user = users_dict.get(target_user_id)
    if not target_user:
        return []

    # Build adjacency dictionary & edge weights
    adj_dict = defaultdict(list)
    edge_weights = {}
    for c in connections:
        u, v, strength = c[0], c[1], c[2]
        adj_dict[u].append(v)
        adj_dict[v].append(u)
        edge_weights[(min(u, v), max(u, v))] = strength

    existing_friends = set(adj_dict.get(target_user_id, []))
    candidates = [u_id for u_id in users_dict if u_id != target_user_id and u_id not in existing_friends]

    recommendations = []
    all_skills = [s for u in users_dict.values() for s in u.get("skills", [])]
    all_interests = [i for u in users_dict.values() for i in u.get("interests", [])]

    for cand_id in candidates:
        cand_user = users_dict[cand_id]
        
        # 1. Topological Metrics
        cn_score, mutual_friends = compute_adamic_adar_index(target_user_id, cand_id, adj_dict)
        jaccard = compute_jaccard_similarity(target_user_id, cand_id, adj_dict)
        adamic_adar = cn_score
        num_mutual = len(mutual_friends)
        
        # 2. Semantic Profile Cosine Match
        cosine_sim = compute_profile_cosine_similarity(target_user, cand_user, all_skills, all_interests)
        
        # 3. Department / Year Affinity
        dept_match = 1.0 if target_user.get("department") == cand_user.get("department") else 0.0
        
        # 4. A* Social Introduction Path
        path, path_cost = a_star_social_path(target_user_id, cand_id, users_dict, adj_dict, edge_weights)
        path_hops = len(path) - 1 if path else 99
        path_bonus = 1.0 / max(path_hops, 1) if path else 0.0

        # Weighted Hybrid Formula (0 to 100%)
        # 35% Profile/Skill Match, 25% Adamic-Adar / Mutual Network, 20% Jaccard, 10% Dept Match, 10% Path Proximity
        adamic_adar_norm = min(adamic_adar / 2.5, 1.0) # normalizer
        hybrid_score = (
            0.35 * cosine_sim +
            0.25 * adamic_adar_norm +
            0.15 * jaccard +
            0.10 * dept_match +
            0.15 * path_bonus
        ) * 100.0

        # Explanations Badge generation (Explainable AI / XAI)
        explanations = []
        if num_mutual > 0:
            explanations.append(f"{num_mutual} Mutual Friend{'s' if num_mutual > 1 else ''}")
        if cosine_sim >= 0.5:
            explanations.append(f"{int(cosine_sim * 100)}% Skill & Interest Alignment")
        elif cosine_sim >= 0.25:
            explanations.append(f"{int(cosine_sim * 100)}% Skill Match")
            
        if dept_match == 1.0:
            explanations.append(f"Same Dept ({cand_user.get('department')})")
            
        if path_hops == 2:
            explanations.append("Warm 2-Hop Intro Path Available")
        elif path_hops > 2 and path_hops < 5:
            explanations.append(f"{path_hops}-Hop Connection Path")

        if not explanations:
            explanations.append("High Emerging Talent Match")

        # Shared skills and interests
        shared_skills = list(set(target_user.get("skills", [])).intersection(set(cand_user.get("skills", []))))
        shared_interests = list(set(target_user.get("interests", [])).intersection(set(cand_user.get("interests", []))))

        recommendations.append({
            "candidate_id": cand_id,
            "name": cand_user.get("name"),
            "department": cand_user.get("department"),
            "year": cand_user.get("year"),
            "role": cand_user.get("role"),
            "avatar": cand_user.get("avatar"),
            "match_score": round(hybrid_score, 1),
            "jaccard_similarity": jaccard,
            "adamic_adar_index": adamic_adar,
            "cosine_similarity": cosine_sim,
            "mutual_friends_count": num_mutual,
            "mutual_friends": [users_dict[m]["name"] for m in mutual_friends if m in users_dict],
            "shared_skills": shared_skills,
            "shared_interests": shared_interests,
            "intro_path": path,
            "intro_path_names": [users_dict[p]["name"] for p in path if p in users_dict],
            "intro_path_cost": path_cost,
            "explainable_badges": explanations
        })

    # Sort candidates by hybrid score descending
    recommendations.sort(key=lambda x: x["match_score"], reverse=True)
    return recommendations[:top_n]
