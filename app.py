"""
Flask REST API & Web Application Server
Course: 25CS301 - Artificial Intelligence
AI-Driven Social Network Friend Recommendation & Relationship Analysis System
"""

import os
import copy
from flask import Flask, jsonify, request, render_template, send_from_directory
import algorithms
from dataset import get_initial_dataset
import test_suite

app = Flask(__name__, static_folder='static', template_folder='templates')

# In-memory graph state initialized from dataset
DATASTORE = get_initial_dataset()

def get_users_dict():
    return {u["id"]: u for u in DATASTORE["users"]}

def get_node_list():
    return [u["id"] for u in DATASTORE["users"]]

# =====================================================================
# REST ENDPOINTS: GRAPH DATA & DYNAMIC EDITS
# =====================================================================
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/graph/state', methods=['GET'])
def get_graph_state():
    """Returns the current full graph (users, connections, and mentorships)"""
    return jsonify({
        "status": "success",
        "users": DATASTORE["users"],
        "connections": DATASTORE["connections"],
        "mentorships": DATASTORE["mentorships"],
        "stats": {
            "total_users": len(DATASTORE["users"]),
            "total_connections": len(DATASTORE["connections"]),
            "total_mentorships": len(DATASTORE["mentorships"])
        }
    })

@app.route('/api/graph/reset', methods=['POST'])
def reset_graph():
    """Resets the graph back to initial dataset state"""
    global DATASTORE
    DATASTORE = get_initial_dataset()
    return jsonify({
        "status": "success",
        "message": "Graph successfully reset to default academic state.",
        "stats": {
            "total_users": len(DATASTORE["users"]),
            "total_connections": len(DATASTORE["connections"]),
            "total_mentorships": len(DATASTORE["mentorships"])
        }
    })

@app.route('/api/graph/user/add', methods=['POST'])
def add_user():
    """Dynamically adds a new student / mentor to the network"""
    data = request.json or {}
    name = data.get("name", "").strip()
    if not name:
        return jsonify({"status": "error", "message": "User name is required"}), 400

    new_id = f"u{len(DATASTORE['users']) + 1}_{int(os.times().elapsed * 100)}"
    user_obj = {
        "id": new_id,
        "name": name,
        "department": data.get("department", "Computer Science & Eng"),
        "year": data.get("year", "Freshman (1st Year)"),
        "role": data.get("role", "Student Member"),
        "skills": [s.strip() for s in data.get("skills", ["Python", "Algorithms"]) if s.strip()],
        "interests": [i.strip() for i in data.get("interests", ["Hackathons"]) if i.strip()],
        "influence_rank": int(data.get("influence_rank", 60)),
        "avatar": f"https://api.dicebear.com/7.x/bottts/svg?seed={name}"
    }

    DATASTORE["users"].append(user_obj)
    return jsonify({"status": "success", "user": user_obj})

@app.route('/api/graph/edge/add', methods=['POST'])
def add_edge():
    """Dynamically adds an edge (Connect Now) between two users"""
    data = request.json or {}
    source = data.get("source")
    target = data.get("target")
    strength = int(data.get("strength", 8))
    label = data.get("label", "Direct Connection")

    if not source or not target or source == target:
        return jsonify({"status": "error", "message": "Invalid source or target"}), 400

    users_dict = get_users_dict()
    if source not in users_dict or target not in users_dict:
        return jsonify({"status": "error", "message": "One or both users not found"}), 404

    # Check if edge already exists
    for c in DATASTORE["connections"]:
        if (c[0] == source and c[1] == target) or (c[0] == target and c[1] == source):
            return jsonify({"status": "exists", "message": "Connection already exists"}), 200

    new_edge = (source, target, strength, label)
    DATASTORE["connections"].append(new_edge)
    return jsonify({"status": "success", "edge": new_edge})

# =====================================================================
# REST ENDPOINTS: RECOMMENDATIONS & HEURISTIC PATH (CO2, CO3, CO5)
# =====================================================================
@app.route('/api/recommendations/<user_id>', methods=['GET'])
def get_recommendations(user_id):
    """Returns Top-5 AI Friend Recommendations for selected user with Explainable AI badges"""
    top_n = int(request.args.get("top_n", 5))
    users_dict = get_users_dict()
    
    if user_id not in users_dict:
        return jsonify({"status": "error", "message": "User not found"}), 404

    recommendations = algorithms.recommend_friends_for_user(
        user_id, users_dict, DATASTORE["connections"], top_n=top_n
    )
    return jsonify({
        "status": "success",
        "user": users_dict[user_id],
        "recommendations": recommendations
    })

# =====================================================================
# REST ENDPOINTS: MST & TOPOLOGICAL SORT (CO2, CO3)
# =====================================================================
@app.route('/api/algorithms/mst', methods=['GET'])
def get_mst():
    """Runs Kruskal's or Prim's algorithm for backbone extraction"""
    algo = request.args.get("algo", "kruskal").lower()
    start_node = request.args.get("start_node", None)
    nodes = get_node_list()

    if algo == "prim":
        res = algorithms.run_prims_mst(nodes, DATASTORE["connections"], start_node=start_node)
    else:
        res = algorithms.run_kruskals_mst(nodes, DATASTORE["connections"])

    return jsonify({"status": "success", "result": res})

@app.route('/api/algorithms/topological-sort', methods=['GET'])
def get_topological_sort():
    """Runs Kahn's or DFS-based Topological Sort on mentorship relations"""
    algo = request.args.get("algo", "kahns").lower()
    nodes = get_node_list()

    if algo == "dfs":
        res = algorithms.run_dfs_topological_sort(nodes, DATASTORE["mentorships"])
    else:
        res = algorithms.run_kahns_algorithm(nodes, DATASTORE["mentorships"])

    users_dict = get_users_dict()
    # Enrich node objects with names and avatars
    enriched_order = [users_dict[nid] for nid in res["topological_order"] if nid in users_dict]
    res["topological_order_users"] = enriched_order

    return jsonify({"status": "success", "result": res})

# =====================================================================
# REST ENDPOINTS: BENCHMARKS & TEST SUITE (RUBRIC #4)
# =====================================================================
@app.route('/api/benchmarks/run', methods=['POST'])
def run_benchmarks():
    """Executes the full evaluation suite: Edge masking, Complexity, & Unit tests"""
    edge_masking_res = test_suite.run_edge_masking_evaluation(DATASTORE["users"], DATASTORE["connections"])
    scalability_res = test_suite.run_scalability_benchmarks()
    matrix_res = test_suite.run_automated_test_matrix()

    return jsonify({
        "status": "success",
        "edge_masking": edge_masking_res,
        "scalability": scalability_res,
        "test_matrix": matrix_res
    })

if __name__ == '__main__':
    print("=" * 70)
    print("AI Social Network Friend Recommendation & Relationship Analysis System")
    print("Course: 25CS301 - Artificial Intelligence | Server listening on port 5000")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)
