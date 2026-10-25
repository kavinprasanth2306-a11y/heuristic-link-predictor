"""
CupidGraph Flask REST API Server
Course: 25CS301 - Artificial Intelligence
Integrated COs: CO2, CO3, CO5
Provides RESTful endpoints for onboarding, 10-D compatibility vector embedding,
automated welcome SMTP dispatch, photo verification gating, swipe feeds, MST group backbones,
topological readiness progression, and automated academic benchmarks.
"""

import os
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import algorithms
from dataset import get_dating_dataset
import test_suite
from mailer import send_welcome_compatibility_email

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
# 1. ONBOARDING, 10-D QUIZ WIZARD & PHOTO GATING
# =====================================================================
@app.route('/api/auth/onboard', methods=['POST'])
def complete_onboarding():
    """
    Mandatory Registration & Vector Embedding Endpoint:
    Enforces photo verification and 10-D quiz answers.
    Automatically sends welcome email via darkin2306@gmail.com.
    """
    data = request.json or {}
    name = data.get("name", "").strip()
    email = data.get("email", "").strip()
    avatar = data.get("avatar", "").strip()
    age = int(data.get("age", 22))
    gender = data.get("gender", "Male")
    bio = data.get("bio", "CupidGraph explorer")
    location = data.get("location", "Bengaluru, India")
    vector_10d = data.get("vector_10d", [])

    # 1. Hard Photo Gating Verification
    if not avatar:
        return jsonify({
            "status": "error",
            "message": "Photo Gate Failed: You must upload or select at least 1 verified profile photo."
        }), 400

    # 2. Hard 10-Question Vector Gate
    if not vector_10d or len(vector_10d) != 10:
        return jsonify({
            "status": "error",
            "message": "Quiz Gate Failed: All 10 compatibility questions must be answered to construct your 10-D vector."
        }), 400

    # Create new profile entry
    new_user_id = f"user_{len(DATASTORE['profiles']) + 1}"
    new_profile = {
        "id": new_user_id,
        "name": name or "New Explorer",
        "email": email or "explorer@cupidgraph.ai",
        "age": age,
        "gender": gender,
        "interested_in": ["Female"] if gender == "Male" else ["Male"],
        "bio": bio,
        "lifestyle_traits": ["Curious", "Mindful", "Adventurous"],
        "interests": ["AI & Robotics", "Filter Coffee", "Indie Music"],
        "vector_10d": [float(v) for v in vector_10d],
        "mutual_connections": ["p1", "p2"],  # Seed with mutual connections
        "readiness_stage": "Icebreaker / Quiz",
        "location": location,
        "avatar": avatar
    }

    # Add to in-memory graph datastore
    DATASTORE["profiles"].insert(0, new_profile)

    # Dispatch welcome HTML email
    email_result = send_welcome_compatibility_email(
        to_email=email or "darkin2306@gmail.com",
        user_name=name or "Explorer",
        user_id=new_user_id,
        vector_10d=new_profile["vector_10d"]
    )

    return jsonify({
        "status": "success",
        "message": "Onboarding complete. 10-D compatibility vector generated & welcome email dispatched.",
        "user": new_profile,
        "email_delivery": email_result
    })

# =====================================================================
# 2. PROFILE FEED & SWIPE ACTIONS (TINDER ENGINE)
# =====================================================================
@app.route('/api/feed', methods=['GET'])
def get_feed():
    """
    Returns candidate swipe deck for the active user, ranked by Hybrid Match Score.
    Default active user is 'p1' (Aarav) or the newly registered user.
    """
    active_user_id = request.args.get("user_id", "p1")
    profiles_map = get_profiles_map()

    if active_user_id not in profiles_map:
        active_user_id = DATASTORE["profiles"][0]["id"]

    active_user = profiles_map[active_user_id]
    mutual_dict = get_mutual_connections_dict()

    candidates = []
    for p in DATASTORE["profiles"]:
        if p["id"] == active_user_id:
            continue
        if (active_user_id, p["id"]) in USER_LIKES:
            continue
        if p["gender"] in active_user.get("interested_in", ["Female", "Male"]):
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

    candidates.sort(key=lambda x: x["match_score"], reverse=True)

    return jsonify({
        "status": "success",
        "active_user": active_user,
        "total_candidates": len(candidates),
        "candidates": candidates
    })

@app.route('/api/swipe', methods=['POST'])
def record_swipe():
    data = request.json or {}
    liker_id = data.get("liker_id", "p1")
    target_id = data.get("target_id")
    action = data.get("action", "like")

    if not target_id:
        return jsonify({"status": "error", "message": "target_id required"}), 400

    profiles_map = get_profiles_map()
    if target_id not in profiles_map:
        return jsonify({"status": "error", "message": "Target profile not found"}), 404

    USER_LIKES.add((liker_id, target_id))

    is_match = False
    intro_path_names = []

    if action in ["like", "superlike"]:
        mutual_dict = get_mutual_connections_dict()
        match_info = algorithms.calculate_match_score(profiles_map[liker_id], profiles_map[target_id], mutual_dict)
        intro_path, _ = algorithms.a_star_social_intro_path(liker_id, target_id, profiles_map, mutual_dict)
        intro_path_names = [profiles_map[pid]["name"] for pid in intro_path if pid in profiles_map]

        if match_info["match_score"] >= 65.0 or action == "superlike":
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
# 3. MINIMUM SPANNING TREE (MST) BACKBONE (CO2)
# =====================================================================
@app.route('/api/mst', methods=['GET'])
def get_mst():
    algo = request.args.get("algo", "kruskal").lower()
    start_node = request.args.get("start_node", "p1")
    profiles = DATASTORE["profiles"]
    nodes = [p["id"] for p in profiles]
    mutual_dict = get_mutual_connections_dict()

    all_edges = []
    for i in range(len(profiles)):
        for j in range(i + 1, len(profiles)):
            u, v = profiles[i], profiles[j]
            has_mutual = len(set(u["mutual_connections"]).intersection(set(v["mutual_connections"]))) > 0
            if has_mutual or (u.get("gender") != v.get("gender")):
                match_res = algorithms.calculate_match_score(u, v, mutual_dict)
                all_edges.append({
                    "source": u["id"],
                    "target": v["id"],
                    "cost": match_res["dissimilarity_cost"],
                    "score": match_res["match_score"]
                })

    if algo == "prim":
        res = algorithms.run_prims_mst(nodes, all_edges, start_node=start_node)
    else:
        res = algorithms.run_kruskals_mst(nodes, all_edges)

    res["profiles_meta"] = [
        {"id": p["id"], "name": p["name"], "avatar": p["avatar"], "gender": p["gender"]}
        for p in profiles
    ]
    return jsonify({"status": "success", "result": res})

# =====================================================================
# 4. TOPOLOGICAL SORTING & READINESS PROGRESSION (CO2, CO3)
# =====================================================================
@app.route('/api/topological-sort', methods=['GET'])
def get_topological_sort():
    dag_edges = DATASTORE["readiness_dag"]
    stages = [
        "Icebreaker / Quiz",
        "Lifestyle Alignment",
        "Emotional Vulnerability & Trust",
        "Core Values & Belief Alignment",
        "Commitment Readiness"
    ]

    res = algorithms.run_kahns_readiness_sort(stages, dag_edges)

    stage_groups = {
        "Icebreaker / Quiz": [],
        "Lifestyle Alignment": [],
        "Core Values": [],
        "Long-Term Commitment": []
    }
    for p in DATASTORE["profiles"]:
        s = p.get("readiness_stage", "Icebreaker / Quiz")
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
# 5. BENCHMARK & EVALUATION SUITE (RUBRIC #4)
# =====================================================================
@app.route('/api/benchmarks/run', methods=['POST', 'GET'])
def run_benchmarks():
    masking_res = test_suite.run_edge_masking_evaluation()
    scalability_res = test_suite.run_scalability_benchmarks()
    matrix_res = test_suite.run_automated_test_matrix()

    return jsonify({
        "status": "success",
        "edge_masking": masking_res,
        "scalability": scalability_res,
        "test_matrix": matrix_res
    })

@app.route('/api/reset', methods=['POST'])
def reset_session():
    global USER_LIKES, MATCHES, DATASTORE
    USER_LIKES.clear()
    MATCHES.clear()
    DATASTORE = get_dating_dataset()
    return jsonify({"status": "success", "message": "CupidGraph session reset successfully"})

# =====================================================================
# 6. IN-APP OVER-THE-AIR (OTA) AUTO-UPDATE ENDPOINTS
# =====================================================================
APK_DIR = os.path.join(os.path.dirname(__file__), 'static', 'apk')
os.makedirs(APK_DIR, exist_ok=True)

APP_RELEASE_INFO = {
    "version": "1.0.1",
    "version_code": 2,
    "release_notes": "CupidGraph v1.0.1: Added in-app OTA updates, smooth Tinder swipe gestures, and real-time compatibility graphs!",
    "download_url": "/api/app/download",
    "min_supported_version": 1
}

@app.route('/api/app/version', methods=['GET'])
def get_latest_app_version():
    apk_file = "cupidgraph-latest.apk"
    apk_path = os.path.join(APK_DIR, apk_file)
    has_apk = os.path.exists(apk_path)
    file_size_bytes = os.path.getsize(apk_path) if has_apk else 0

    return jsonify({
        "status": "success",
        "has_update": True,
        "latest_version": APP_RELEASE_INFO["version"],
        "latest_version_code": APP_RELEASE_INFO["version_code"],
        "release_notes": APP_RELEASE_INFO["release_notes"],
        "download_url": APP_RELEASE_INFO["download_url"],
        "file_size_bytes": file_size_bytes,
        "is_apk_available": has_apk
    })

@app.route('/api/app/download', methods=['GET'])
def download_latest_apk():
    apk_file = "cupidgraph-latest.apk"
    apk_path = os.path.join(APK_DIR, apk_file)
    if not os.path.exists(apk_path):
        return jsonify({
            "status": "error",
            "message": "No APK build found on server. Please build and place cupidgraph-latest.apk in backend/static/apk/"
        }), 404
        
    return send_from_directory(
        APK_DIR, 
        apk_file, 
        as_attachment=True,
        download_name="cupidgraph-latest.apk",
        mimetype="application/vnd.android.package-archive"
    )

if __name__ == '__main__':
    print("=" * 70)
    print("CupidGraph: Graph-Theoretic Compatibility & Matchmaking Engine")
    print("Course: 25CS301 - Artificial Intelligence | Server listening on port 5000")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)
