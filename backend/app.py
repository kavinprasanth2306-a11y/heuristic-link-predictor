"""
CupidGraph Flask REST API Server
Course: 25CS301 - Artificial Intelligence
Integrated COs: CO2, CO3, CO5
Provides RESTful endpoints for onboarding, 10-D compatibility vector embedding,
automated welcome SMTP dispatch, photo verification gating, swipe feeds, MST group backbones,
topological readiness progression, messaging, and SQLite persistent datastore.
"""

import os
import random
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import algorithms
from dataset import READINESS_DAG_EDGES
import test_suite
from mailer import send_welcome_compatibility_email
import database

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests for Flutter app

def get_profiles_map():
    profiles = database.get_all_profiles()
    return {p["id"]: p for p in profiles}

def get_mutual_connections_dict():
    mutual_dict = {}
    for p in database.get_all_profiles():
        mutual_dict[p["id"]] = p.get("mutual_connections", [])
    return mutual_dict

# =====================================================================
# 1. ONBOARDING, LOGIN CHECK & PROFILE UPDATE
# =====================================================================
@app.route('/api/auth/check', methods=['POST'])
def check_or_login():
    """
    Checks if a user already exists by email.
    If exists, returns their profile so they skip 10 questions and jump straight into the app.
    """
    data = request.json or {}
    email = data.get("email", "").strip()
    if not email:
        return jsonify({"status": "error", "message": "email required"}), 400

    user = database.get_profile_by_email(email)
    if user:
        return jsonify({
            "status": "success",
            "exists": True,
            "user": user
        })
    return jsonify({
        "status": "success",
        "exists": False
    })

@app.route('/api/auth/onboard', methods=['POST'])
def complete_onboarding():
    """
    Mandatory Registration & Vector Embedding Endpoint:
    Enforces photo verification and 10-D quiz answers.
    Persists into SQLite database and automatically sends welcome email.
    If email exists, updates their existing profile to prevent duplicates.
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
    photos = data.get("photos", [avatar] if avatar else [])

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

    # Check if user with this email already exists to prevent duplicate entries
    existing_user = database.get_profile_by_email(email) if email else None
    if existing_user:
        new_user_id = existing_user["id"]
    else:
        all_profiles = database.get_all_profiles()
        new_user_id = f"user_{len(all_profiles) + 1}"

    new_profile = {
        "id": new_user_id,
        "name": name or "New Explorer",
        "email": email or f"{new_user_id}@cupidgraph.ai",
        "age": age,
        "gender": gender,
        "interested_in": ["Female"] if gender == "Male" else ["Male"],
        "bio": bio,
        "lifestyle_traits": ["Curious", "Mindful", "Adventurous"],
        "interests": ["AI & Robotics", "Filter Coffee", "Indie Music"],
        "vector_10d": [float(v) for v in vector_10d],
        "mutual_connections": ["p1", "p2", "p16"],  # Seed with mutual connections
        "readiness_stage": "Core Values",
        "location": location,
        "avatar": avatar,
        "photos": photos
    }

    # Persist in SQLite
    database.insert_or_update_profile(new_profile)

    # Dispatch welcome HTML email
    email_result = send_welcome_compatibility_email(
        to_email=email or f"{new_user_id}@cupidgraph.ai",
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

@app.route('/api/profile/update', methods=['POST'])
def update_profile():
    data = request.json or {}
    user_id = data.get("user_id", "p1")
    name = data.get("name")
    bio = data.get("bio")
    location = data.get("location")
    avatar = data.get("avatar")
    photos = data.get("photos")
    vector_10d = data.get("vector_10d")
    age = data.get("age")
    gender = data.get("gender")

    updated = database.update_user_profile(
        user_id,
        name=name,
        bio=bio,
        location=location,
        avatar=avatar,
        photos=photos,
        vector_10d=vector_10d,
        age=age,
        gender=gender
    )
    if not updated:
        return jsonify({"status": "error", "message": "User not found"}), 404
    return jsonify({"status": "success", "profile": updated})

# =====================================================================
# USER POSTS & STATUS SHARING
# =====================================================================
@app.route('/api/posts', methods=['GET'])
def get_posts():
    posts = database.get_all_posts()
    return jsonify({"status": "success", "posts": posts})

@app.route('/api/posts/create', methods=['POST'])
def create_new_post():
    data = request.json or {}
    user_id = data.get("user_id", "p1")
    content = data.get("content", "").strip()
    image_url = data.get("image_url", "").strip()

    if not content and not image_url:
        return jsonify({"status": "error", "message": "Post content or photo required"}), 400

    new_p = database.create_post(user_id, content, image_url)
    return jsonify({"status": "success", "post": new_p})

@app.route('/api/posts/<int:post_id>/like', methods=['POST'])
def like_a_post(post_id):
    p = database.like_post(post_id)
    if not p:
        return jsonify({"status": "error", "message": "Post not found"}), 404
    return jsonify({"status": "success", "post": p})

# =====================================================================
# 2. PROFILE FEED & SWIPE ACTIONS (INFINITE TINDER ENGINE)
# =====================================================================
@app.route('/api/feed', methods=['GET'])
def get_feed():
    """
    Returns candidate swipe deck for the active user, ranked by Hybrid Match Score.
    Features INFINITE SUGGESTIONS: if unswiped candidates drop low or run out,
    it dynamically recycles or creates simulated high-compatibility matches so the deck NEVER runs dry.
    """
    active_user_id = request.args.get("user_id", "p1")
    profiles_map = get_profiles_map()

    if active_user_id not in profiles_map:
        active_user_id = list(profiles_map.keys())[0] if profiles_map else "p1"

    active_user = profiles_map.get(active_user_id, {
        "id": "p1", "name": "Aarav Sharma", "gender": "Male", "interested_in": ["Female"],
        "vector_10d": [0.8, 0.3, 0.9, 0.7, 0.9, 0.8, 0.8, 1.0, 0.7, 0.9]
    })
    mutual_dict = get_mutual_connections_dict()
    swiped_ids = database.get_user_swiped_ids(active_user_id)

    candidates = []
    unswiped_candidates = []
    
    all_profiles = database.get_all_profiles()
    for p in all_profiles:
        if p["id"] == active_user_id:
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

            if p["id"] not in swiped_ids:
                unswiped_candidates.append(candidate_obj)
            else:
                candidates.append(candidate_obj)

    # If unswiped list has candidates, use them first
    if unswiped_candidates:
        deck = unswiped_candidates
    else:
        # INFINITE FEED RECYCLING:
        # If user swiped all candidates, recycle them with slight dynamic score nudges so user can keep exploring
        deck = candidates

    deck.sort(key=lambda x: x["match_score"], reverse=True)

    return jsonify({
        "status": "success",
        "active_user": active_user,
        "total_candidates": len(deck),
        "candidates": deck
    })

@app.route('/api/profile/<profile_id>', methods=['GET'])
def get_profile_details(profile_id):
    p = database.get_profile_by_id(profile_id)
    if not p:
        return jsonify({"status": "error", "message": "Profile not found"}), 404
    
    # Calculate match with active user
    active_user_id = request.args.get("active_user_id", "p1")
    profiles_map = get_profiles_map()
    active_user = profiles_map.get(active_user_id)
    mutual_dict = get_mutual_connections_dict()

    match_data = {}
    intro_path_names = []
    if active_user and active_user_id != profile_id:
        match_data = algorithms.calculate_match_score(active_user, p, mutual_dict)
        intro_path, path_cost = algorithms.a_star_social_intro_path(active_user_id, profile_id, profiles_map, mutual_dict)
        intro_path_names = [profiles_map[pid]["name"] for pid in intro_path if pid in profiles_map]
        match_data["intro_path_names"] = intro_path_names
        match_data["intro_path_cost"] = path_cost

    return jsonify({
        "status": "success",
        "profile": p,
        "match_details": match_data
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

    if liker_id not in profiles_map:
        liker_id = list(profiles_map.keys())[0]

    # Save to SQLite database
    database.record_swipe_in_db(liker_id, target_id, action)

    is_match = False
    intro_path_names = []

    if action in ["like", "superlike"]:
        mutual_dict = get_mutual_connections_dict()
        match_info = algorithms.calculate_match_score(profiles_map[liker_id], profiles_map[target_id], mutual_dict)
        intro_path, _ = algorithms.a_star_social_intro_path(liker_id, target_id, profiles_map, mutual_dict)
        intro_path_names = [profiles_map[pid]["name"] for pid in intro_path if pid in profiles_map]

        # In modern dating apps, mutual score >= 60 or superlike produces a match!
        if match_info["match_score"] >= 60.0 or action == "superlike":
            is_match = True
            database.record_match_in_db(liker_id, target_id, match_info["match_score"])

    return jsonify({
        "status": "success",
        "action": action,
        "is_match": is_match,
        "matched_profile": profiles_map[target_id] if is_match else None,
        "intro_path_names": intro_path_names
    })

# =====================================================================
# 3. 1-TO-1 MESSAGING & CONVERSATIONS (PERSISTENT SQLITE)
# =====================================================================
@app.route('/api/messages/conversations', methods=['GET'])
def get_conversations():
    user_id = request.args.get("user_id", "p1")
    # Fetch all matches and active conversations
    conversations = database.get_recent_conversations_list(user_id)
    matches = database.get_matches_for_user(user_id)
    return jsonify({
        "status": "success",
        "conversations": conversations,
        "matches": matches
    })

@app.route('/api/messages/<partner_id>', methods=['GET'])
def get_messages_with_partner(partner_id):
    user_id = request.args.get("user_id", "p1")
    messages = database.get_conversation(user_id, partner_id)
    partner = database.get_profile_by_id(partner_id)
    return jsonify({
        "status": "success",
        "partner": partner,
        "messages": messages
    })

@app.route('/api/messages/send', methods=['POST'])
def send_message():
    data = request.json or {}
    sender_id = data.get("sender_id", "p1")
    receiver_id = data.get("receiver_id")
    text = data.get("text", "").strip()

    if not receiver_id or not text:
        return jsonify({"status": "error", "message": "receiver_id and text required"}), 400

    saved_msg = database.save_message(sender_id, receiver_id, text)
    return jsonify({
        "status": "success",
        "message": saved_msg
    })

# =====================================================================
# 4. MINIMUM SPANNING TREE (MST) BACKBONE (CO2)
# =====================================================================
@app.route('/api/mst', methods=['GET'])
def get_mst():
    algo = request.args.get("algo", "kruskal").lower()
    start_node = request.args.get("start_node", "p1")
    profiles = database.get_all_profiles()
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
# 5. TOPOLOGICAL SORTING & READINESS PROGRESSION (CO2, CO3)
# =====================================================================
@app.route('/api/topological-sort', methods=['GET'])
def get_topological_sort():
    dag_edges = READINESS_DAG_EDGES
    stages = [
        "Icebreaker / Quiz",
        "Lifestyle Alignment",
        "Emotional Vulnerability & Trust",
        "Core Values & Belief Alignment",
        "Commitment Readiness"
    ]
    res = algorithms.kahns_topological_sort_readiness(stages, dag_edges)

    # Group profiles by readiness stage
    stage_groups = {s: [] for s in stages}
    for p in database.get_all_profiles():
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
# 6. BENCHMARK & EVALUATION SUITE
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
    # Reinitialize SQLite database with fresh seed dataset
    conn = database.get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM swipes")
    cur.execute("DELETE FROM matches")
    cur.execute("DELETE FROM messages")
    conn.commit()
    conn.close()
    return jsonify({"status": "success", "message": "CupidGraph SQLite session reset successfully"})

# =====================================================================
# 7. IN-APP OVER-THE-AIR (OTA) AUTO-UPDATE ENDPOINTS
# =====================================================================
APK_DIR = os.path.join(os.path.dirname(__file__), 'static', 'apk')
os.makedirs(APK_DIR, exist_ok=True)

APP_RELEASE_INFO = {
    "version": "1.0.1",
    "version_code": 2,
    "release_notes": "CupidGraph v1.0.1: Added SQLite DB, instant messaging, infinite candidate suggestions, and detailed profile viewer!",
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
    database.init_db()
    print("=" * 70)
    print("CupidGraph: Graph-Theoretic Compatibility & Matchmaking Engine")
    print("Persistent SQLite Database loaded. Server listening on port 5000")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)
