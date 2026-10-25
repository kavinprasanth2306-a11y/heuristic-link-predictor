"""
CupidGraph Flask REST API Server
Course: 25CS301 - Artificial Intelligence
Integrated COs: CO2, CO3, CO5
Provides RESTful endpoints for swipe feeds, match calculations, MST group backbones,
topological readiness progression, and automated academic benchmarks.
"""

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
import algorithms
from dataset import get_dating_dataset
import test_suite

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests for Flutter app

# In-memory session store initialized with curated dating dataset
DATASTORE = get_dating_dataset()
USER_LIKES = set()  # Set of (liker_id, liked_id)
MATCHES = []  # List of mutual matches

def get_profiles_map():
    return {p["id"]: p for p in DATASTORE["profiles"]}

def get_mutual_connections_dict():
    mutual_dict = {}
    for p in DATASTORE["profiles"]:
        mutual_dict[p["id"]] = p.get("mutual_connections", [])
    return mutual_dict

# =====================================================================
# 1. PROFILE FEED & SWIPE ACTIONS (TINDER ENGINE)
# =====================================================================
@app.route('/api/feed', methods=['GET'])
def get_feed():
    """
    Returns candidate swipe deck for the active user, ranked by Hybrid Match Score.
    Default active user is 'p1' (Aarav).
    """
    active_user_id = request.args.get("user_id", "p1")
    profiles_map = get_profiles_map()

    if active_user_id not in profiles_map:
        return jsonify({"status": "error", "message": "User not found"}), 404

    active_user = profiles_map[active_user_id]
    mutual_dict = get_mutual_connections_dict()

    # Filter candidates by gender preference & exclude self and already-liked profiles
    candidates = []
    for p in DATASTORE["profiles"]:
        if p["id"] == active_user_id:
            continue
        if (active_user_id, p["id"]) in USER_LIKES:
            continue
        if p["gender"] in active_user.get("interested_in", ["Female"]):
            # Calculate match score & explainable badges
            match_data = algorithms.calculate_match_score(active_user, p, mutual_dict)
            intro_path, path_cost = algorithms.a_star_social_intro_path(active_user_id, p["id"], profiles_map, mutual_dict)

            candidate_obj = dict(p)
            candidate_obj.update({
                "match_score": match_data["match_score"],
                "cosine_similarity": match_data["cosine_similarity"],
                "adamic_adar_index": match_data["adamic_adar_index"],
                "jaccard_similarity": match_data["jaccard_similarity"],
                "mutual_friends_count": match_data["mutual_friends_count"],
                "shared_traits": match_data["shared_traits"],
                "shared_interests": match_data["shared_interests"],
                "explainable_badges": match_data["explainable_badges"],
                "intro_path": intro_path,
                "intro_path_names": [profiles_map[pid]["name"] for pid in intro_path if pid in profiles_map],
                "intro_path_cost": path_cost
            })
            candidates.append(candidate_obj)

    # Sort descending by match score
    candidates.sort(key=lambda x: x["match_score"], reverse=True)

    return jsonify({
        "status": "success",
        "active_user": active_user,
        "total_candidates": len(candidates),
        "candidates": candidates
    })

@app.route('/api/swipe', methods=['POST'])
def record_swipe():
    """
    Records a swipe action (like / pass).
    If reciprocal affinity exists (match score > 75%), triggers instant 'It's a Match!' event.
    """
    data = request.json or {}
    liker_id = data.get("liker_id", "p1")
    target_id = data.get("target_id")
    action = data.get("action", "like")  # 'like' or 'pass'

    if not target_id:
        return jsonify({"status": "error", "message": "target_id required"}), 400

    profiles_map = get_profiles_map()
    if target_id not in profiles_map:
        return jsonify({"status": "error", "message": "Target profile not found"}), 404

    USER_LIKES.add((liker_id, target_id))

    is_match = False
    intro_path_names = []

    if action == "like":
        # Check mutual compatibility for realistic matchmaking threshold
        mutual_dict = get_mutual_connections_dict()
        match_info = algorithms.calculate_match_score(profiles_map[liker_id], profiles_map[target_id], mutual_dict)
        intro_path, _ = algorithms.a_star_social_intro_path(liker_id, target_id, profiles_map, mutual_dict)
        intro_path_names = [profiles_map[pid]["name"] for pid in intro_path if pid in profiles_map]

        # In dating simulations, high match score (>70%) triggers mutual match celebration
        if match_info["match_score"] >= 70.0:
            is_match = True
            MATCHES.append({
                "user_a": liker_id,
                "user_b": target_id,
                "match_score": match_info["match_score"],
                "intro_path_names": intro_path_names
            })

    return jsonify({
        "status": "success",
        "action": action,
        "is_match": is_match,
        "matched_profile": profiles_map[target_id] if is_match else None,
        "intro_path_names": intro_path_names
    })

# =====================================================================
# 2. MINIMUM SPANNING TREE (MST) BACKBONE (CO2)
# =====================================================================
@app.route('/api/mst', methods=['GET'])
def get_mst():
    """
    Computes Minimum Spanning Tree over community affinity graph.
    Toggles between Kruskal's (DSU) and Prim's (Min-Heap).
    """
    algo = request.args.get("algo", "kruskal").lower()
    start_node = request.args.get("start_node", "p1")
    profiles = DATASTORE["profiles"]
    nodes = [p["id"] for p in profiles]
    mutual_dict = get_mutual_connections_dict()
    profiles_map = get_profiles_map()

    # Generate candidate edges between profiles sharing mutual ties or high trait overlap
    all_edges = []
    seen = set()
    for i in range(len(profiles)):
        for j in range(i + 1, len(profiles)):
            u, v = profiles[i], profiles[j]
            # Connect if mutual friends exist or match score > 55%
            has_mutual = len(set(u["mutual_connections"]).intersection(set(v["mutual_connections"]))) > 0
            if has_mutual or (u["gender"] != v["gender"]):
                match_res = algorithms.calculate_match_score(u, v, mutual_dict)
                cost = match_res["dissimilarity_cost"]
                all_edges.append({
                    "source": u["id"],
                    "target": v["id"],
                    "cost": cost,
                    "score": match_res["match_score"]
                })

    if algo == "prim":
        res = algorithms.run_prims_mst(nodes, all_edges, start_node=start_node)
    else:
        res = algorithms.run_kruskals_mst(nodes, all_edges)

    # Attach profile summary for visualization
    res["profiles_meta"] = [
        {"id": p["id"], "name": p["name"], "avatar": p["avatar"], "gender": p["gender"]}
        for p in profiles
    ]
    return jsonify({"status": "success", "result": res})

# =====================================================================
# 3. TOPOLOGICAL SORTING & READINESS PROGRESSION (CO2, CO3)
# =====================================================================
@app.route('/api/topological-sort', methods=['GET'])
def get_topological_sort():
    """
    Returns Kahn's topological sort of relationship readiness milestones,
    and clusters profiles by their corresponding readiness stage.
    """
    dag_edges = DATASTORE["readiness_dag"]
    stages = [
        "Icebreaker & Casual Chemistry",
        "Shared Lifestyle & Habits",
        "Emotional Vulnerability & Trust",
        "Core Values & Belief Alignment",
        "Conflict Resolution & Communication",
        "Long-Term Commitment & Life Vision"
    ]

    res = algorithms.run_kahns_readiness_sort(stages, dag_edges)

    # Group profiles by their current readiness stage
    stage_groups = {
        "Icebreaker": [],
        "Lifestyle Compatibility": [],
        "Core Values": [],
        "Long-Term Commitment": []
    }
    for p in DATASTORE["profiles"]:
        s = p.get("readiness_stage", "Icebreaker")
        if s in stage_groups:
            stage_groups[s].append({
                "id": p["id"],
                "name": p["name"],
                "age": p["age"],
                "gender": p["gender"],
                "avatar": p["avatar"],
                "bio": p["bio"]
            })

    res["stage_cohorts"] = stage_groups
    return jsonify({"status": "success", "result": res})

# =====================================================================
# 4. BENCHMARK & EVALUATION SUITE (RUBRIC #4)
# =====================================================================
@app.route('/api/benchmarks/run', methods=['POST', 'GET'])
def run_benchmarks():
    """Executes the full automated evaluation suite for CupidGraph"""
    masking_res = test_suite.run_edge_masking_evaluation()
    scalability_res = test_suite.run_scalability_benchmarks()
    matrix_res = test_suite.run_automated_test_matrix()

    return jsonify({
        "status": "success",
        "edge_masking": masking_res,
        "scalability": scalability_res,
        "test_matrix": matrix_res
    })

# =====================================================================
# 5. USER PROFILE SELECTION & DETAILS
# =====================================================================
@app.route('/api/profiles', methods=['GET'])
def list_profiles():
    """Lists all available dating profiles"""
    return jsonify({
        "status": "success",
        "profiles": DATASTORE["profiles"]
    })

@app.route('/api/reset', methods=['POST'])
def reset_session():
    """Resets likes and matches back to default state"""
    global USER_LIKES, MATCHES, DATASTORE
    USER_LIKES.clear()
    MATCHES.clear()
    DATASTORE = get_dating_dataset()
    return jsonify({"status": "success", "message": "CupidGraph session reset successfully"})

if __name__ == '__main__':
    print("=" * 70)
    print("CupidGraph: Graph-Theoretic Compatibility & Matchmaking Engine")
    print("Course: 25CS301 - Artificial Intelligence | Listening on port 5000")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)
