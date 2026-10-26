"""
CupidGraph SQLite Database Handler
Provides persistent storage for:
- Profiles & 10-D compatibility vectors
- Swipes (like, pass, superlike)
- Mutual Matches
- 1-to-1 Instant Messages
- User Posts & Photos
"""

import sqlite3
import json
import os
from dataset import INITIAL_PROFILES, READINESS_DAG_EDGES

DB_PATH = os.path.join(os.path.dirname(__file__), "cupidgraph.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

# Clean, curated list of unique real users (no duplicates)
CURATED_REAL_USERS = [
    {
        "id": "p1",
        "name": "Aarav Sharma",
        "age": 22,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "AI Researcher & coffee enthusiast. Looking for deep conversations, late-night hackathons, and weekend treks.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Gym", "Career-Driven", "Non-Smoker"],
        "interests": ["AI & Robotics", "Indie Music", "Filter Coffee", "Trekking", "Sci-Fi Movies"],
        "vector_10d": [0.8, 0.3, 0.9, 0.7, 0.9, 0.8, 0.8, 1.0, 0.7, 0.9],
        "mutual_connections": ["p2", "p3", "p5", "p8", "p12"],
        "readiness_stage": "Core Values",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=600&q=80",
        "email": "aarav.sharma@cupidgraph.ai"
    },
    {
        "id": "p2",
        "name": "Ananya Iyer",
        "age": 21,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Data Scientist by day, indie guitarist by night. Passionate about art galleries, vinyl records, and cute dogs.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Creative", "Bookworm", "Vegetarian"],
        "interests": ["Indie Music", "Filter Coffee", "AI & Robotics", "Art Galleries", "Guitar"],
        "vector_10d": [0.8, 0.5, 0.85, 0.75, 0.85, 0.6, 0.75, 0.95, 0.8, 1.0],
        "mutual_connections": ["p1", "p3", "p4", "p7", "p15"],
        "readiness_stage": "Core Values",
        "location": "Indiranagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80",
        "email": "ananya.iyer@cupidgraph.ai"
    },
    {
        "id": "p3",
        "name": "Rohan Verma",
        "age": 23,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Full-stack engineer & weekend cyclist. Let's debate whether tabs or spaces win, or find the best street tacos in town.",
        "lifestyle_traits": ["Extrovert", "Early-Bird", "Gym", "Foodie", "Social-Drinker"],
        "interests": ["Cycling", "Street Food", "Indie Music", "Startups", "Board Games"],
        "vector_10d": [0.6, 0.9, 0.6, 0.8, 0.2, 0.9, 0.8, 0.85, 0.85, 0.7],
        "mutual_connections": ["p1", "p2", "p4", "p6", "p9"],
        "readiness_stage": "Lifestyle Alignment",
        "location": "HSR Layout, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80",
        "email": "rohan.verma@cupidgraph.ai"
    },
    {
        "id": "p4",
        "name": "Sneha Kulkarni",
        "age": 22,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Cybersecurity auditor & marathon runner. I value genuine honesty, thrift store finds, and authentic street food crawls.",
        "lifestyle_traits": ["Ambivert", "Early-Bird", "Gym", "Health-Conscious", "Organized"],
        "interests": ["Marathon", "Street Food", "Cycling", "Cyber Defense", "Podcasts"],
        "vector_10d": [0.65, 0.6, 0.8, 0.7, 0.15, 0.95, 0.7, 0.8, 0.9, 0.8],
        "mutual_connections": ["p2", "p3", "p6", "p10", "p16"],
        "readiness_stage": "Lifestyle Alignment",
        "location": "Whitefield, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80",
        "email": "sneha.k@cupidgraph.ai"
    },
    {
        "id": "p5",
        "name": "Meera Joshi",
        "age": 23,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "NLP Engineer & literature lover. Seeking an intellectual partner for bookstore dates, jazz cafes, and thought-provoking debates.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Bookworm", "Mindful", "Non-Smoker"],
        "interests": ["Literature", "AI & Robotics", "Filter Coffee", "Jazz Music", "Photography"],
        "vector_10d": [0.4, 0.25, 0.95, 0.6, 0.9, 0.4, 0.6, 0.95, 0.7, 0.6],
        "mutual_connections": ["p1", "p6", "p8", "p11", "p17"],
        "readiness_stage": "Core Values",
        "location": "Jayanagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=600&q=80",
        "email": "meera.joshi@cupidgraph.ai"
    },
    {
        "id": "p6",
        "name": "Vikram Malhotra",
        "age": 25,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Senior Cloud Architect & Angel Investor. Looking for a high-chemistry, ambitious partner to build a meaningful life together.",
        "lifestyle_traits": ["Extrovert", "Early-Bird", "Gym", "Career-Driven", "Wine-Lover"],
        "interests": ["Startups", "Literature", "Fine Dining", "Marathon", "Jazz Music"],
        "vector_10d": [0.7, 0.85, 0.95, 0.75, 0.2, 0.85, 0.9, 0.9, 0.8, 0.5],
        "mutual_connections": ["p3", "p4", "p5", "p9", "p13"],
        "readiness_stage": "Commitment Readiness",
        "location": "Lavelle Road, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80",
        "email": "vikram.m@cupidgraph.ai"
    },
    {
        "id": "p7",
        "name": "Ishita Sen",
        "age": 22,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Bioinformatics scholar & pottery lover. Let's make pour-over coffee, visit art museums, and talk about genetics.",
        "lifestyle_traits": ["Ambivert", "Early-Bird", "Creative", "Mindful", "Vegetarian"],
        "interests": ["Pottery", "Filter Coffee", "Art Galleries", "Bioinformatics", "Indie Music"],
        "vector_10d": [0.5, 0.45, 0.9, 0.8, 0.3, 0.5, 0.65, 0.9, 0.85, 0.85],
        "mutual_connections": ["p2", "p5", "p8", "p14"],
        "readiness_stage": "Emotional Vulnerability & Trust",
        "location": "Sadashivanagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80",
        "email": "ishita.sen@cupidgraph.ai"
    },
    {
        "id": "p8",
        "name": "Devansh Singhal",
        "age": 23,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Product Designer & avid reader. Passionate about minimalism, vinyl audio, and finding calm neighborhood cafes.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Bookworm", "Calm", "Non-Smoker"],
        "interests": ["UI/UX Design", "Vinyl Records", "Filter Coffee", "Architecture", "Indie Rock"],
        "vector_10d": [0.5, 0.35, 0.85, 0.7, 0.8, 0.5, 0.7, 0.9, 0.8, 0.9],
        "mutual_connections": ["p1", "p4", "p14"],
        "readiness_stage": "Lifestyle Alignment",
        "location": "HSR Layout, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=600&q=80",
        "email": "devansh.s@cupidgraph.ai"
    },
    {
        "id": "p9",
        "name": "Diya Banerjee",
        "age": 21,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Film director & street photographer. I capture candid human stories and cherish soulful midnight walks.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Artistic", "Spontaneous", "Tea-Lover"],
        "interests": ["Photography", "Cinema", "Indie Music", "Documentaries", "Street Food"],
        "vector_10d": [0.75, 0.6, 0.75, 0.8, 0.9, 0.5, 0.85, 0.9, 0.75, 0.9],
        "mutual_connections": ["p2", "p3", "p7", "p11"],
        "readiness_stage": "Emotional Vulnerability & Trust",
        "location": "Indiranagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=600&q=80",
        "email": "diya.b@cupidgraph.ai"
    },
    {
        "id": "p10",
        "name": "Kabir Mathur",
        "age": 24,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Indie game developer & synthesizers musician. Seeking someone who enjoys ambient electronic jams and video game storytelling.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Creative", "Gamer", "Techie"],
        "interests": ["Gaming", "Indie Music", "Sci-Fi Movies", "AI & Robotics", "Anime"],
        "vector_10d": [0.8, 0.3, 0.75, 0.6, 0.9, 0.4, 0.5, 0.95, 0.7, 0.85],
        "mutual_connections": ["p1", "p5", "p14"],
        "readiness_stage": "Icebreaker / Quiz",
        "location": "Church Street, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=600&q=80",
        "email": "kabir.m@cupidgraph.ai"
    },
    {
        "id": "p11",
        "name": "Priya Nair",
        "age": 23,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Classical Bharatanatyam dancer & cognitive science researcher. Looking for kindness, sharp curiosity, and peaceful Sunday breakfasts.",
        "lifestyle_traits": ["Introvert", "Early-Bird", "Artistic", "Empath", "Mindful"],
        "interests": ["Classical Dance", "Cognitive Science", "Yoga", "Reading", "Chai"],
        "vector_10d": [0.35, 0.4, 0.95, 0.8, 0.2, 0.7, 0.6, 0.9, 0.9, 0.8],
        "mutual_connections": ["p4", "p7", "p9"],
        "readiness_stage": "Core Values",
        "location": "Malleswaram, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=600&q=80",
        "email": "priya.nair@cupidgraph.ai"
    },
    {
        "id": "p12",
        "name": "Aditya Hegde",
        "age": 24,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Backend distributed systems architect & amateur barista. Love discussing fault-tolerant databases and hiking peaks.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Coffee-Snob", "Fitness", "Techie"],
        "interests": ["Cloud Architecture", "Filter Coffee", "Trekking", "Podcasts", "Rock Climbing"],
        "vector_10d": [0.7, 0.5, 0.8, 0.7, 0.8, 0.85, 0.8, 0.9, 0.8, 0.7],
        "mutual_connections": ["p1", "p3", "p6"],
        "readiness_stage": "Lifestyle Alignment",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=600&q=80",
        "email": "aditya.h@cupidgraph.ai"
    },
    {
        "id": "p13",
        "name": "Riya Singhania",
        "age": 24,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Blockchain Auditor & scuba diver. Looking for an ambitious partner who values trust, loyalty, and shared world adventures.",
        "lifestyle_traits": ["Extrovert", "Early-Bird", "Adventurous", "Career-Driven", "Fitness"],
        "interests": ["Scuba Diving", "Travel", "Startups", "Wine Tasting", "Fine Dining"],
        "vector_10d": [0.65, 0.9, 0.9, 0.8, 0.25, 0.9, 0.9, 0.85, 0.85, 0.6],
        "mutual_connections": ["p6", "p10", "p12"],
        "readiness_stage": "Commitment Readiness",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80",
        "email": "riya.s@cupidgraph.ai"
    },
    {
        "id": "p14",
        "name": "Siddharth Rao",
        "age": 24,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Cloud DevOps lead & vinyl record collector. Value authentic conversations over small talk. Tell me your top 3 favorite albums.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Music-Lover", "Career-Driven", "Calm"],
        "interests": ["Vinyl Records", "Jazz Music", "Indie Music", "Podcasts", "Travel"],
        "vector_10d": [0.6, 0.55, 0.75, 0.65, 0.8, 0.6, 0.75, 0.85, 0.8, 0.75],
        "mutual_connections": ["p7", "p8", "p13"],
        "readiness_stage": "Lifestyle Alignment",
        "location": "Bellandur, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=600&q=80",
        "email": "siddharth.r@cupidgraph.ai"
    },
    {
        "id": "p15",
        "name": "Kavya Menon",
        "age": 23,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Reinforcement Learning researcher & dog shelter volunteer. Seeking kindness, sharp intellect, and shared Sunday brunches.",
        "lifestyle_traits": ["Introvert", "Early-Bird", "Animal-Lover", "Empath", "Non-Smoker"],
        "interests": ["Dogs & Pets", "AI & Robotics", "Yoga", "Filter Coffee", "Indie Music"],
        "vector_10d": [0.55, 0.4, 0.85, 0.75, 0.3, 0.7, 0.7, 0.9, 0.85, 1.0],
        "mutual_connections": ["p2", "p4", "p14"],
        "readiness_stage": "Core Values",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=600&q=80",
        "email": "kavya.m@cupidgraph.ai"
    }
]

def init_db():
    conn = get_connection()
    cur = conn.cursor()

    # Profiles table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        interested_in TEXT NOT NULL,
        bio TEXT,
        lifestyle_traits TEXT,
        interests TEXT,
        vector_10d TEXT NOT NULL,
        mutual_connections TEXT,
        readiness_stage TEXT,
        location TEXT,
        avatar TEXT,
        email TEXT,
        photos TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    # Column migrations
    try:
        cur.execute("ALTER TABLE profiles ADD COLUMN photos TEXT")
    except Exception:
        pass

    # Swipes table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS swipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        liker_id TEXT NOT NULL,
        target_id TEXT NOT NULL,
        action TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(liker_id, target_id)
    )
    """)

    # Matches table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_a TEXT NOT NULL,
        user_b TEXT NOT NULL,
        match_score REAL NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_a, user_b)
    )
    """)

    # Messages table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    # Posts table for user status/photo sharing
    cur.execute("""
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_avatar TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        likes_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    conn.commit()

    # Seed initial profiles if empty
    cur.execute("SELECT COUNT(*) as count FROM profiles")
    row = cur.fetchone()
    if row["count"] == 0:
        seed_profiles(conn)

    conn.close()

def seed_profiles(conn):
    cur = conn.cursor()
    for p in CURATED_REAL_USERS:
        photos = json.dumps([p["avatar"]])
        cur.execute("""
        INSERT OR REPLACE INTO profiles 
        (id, name, age, gender, interested_in, bio, lifestyle_traits, interests, vector_10d, mutual_connections, readiness_stage, location, avatar, email, photos)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            p["id"],
            p["name"],
            p["age"],
            p["gender"],
            json.dumps(p.get("interested_in", ["Female"])),
            p.get("bio", ""),
            json.dumps(p.get("lifestyle_traits", [])),
            json.dumps(p.get("interests", [])),
            json.dumps(p.get("vector_10d", [0.5]*10)),
            json.dumps(p.get("mutual_connections", [])),
            p.get("readiness_stage", "Core Values"),
            p.get("location", "Bengaluru, India"),
            p.get("avatar", ""),
            p.get("email", f"{p['id']}@cupidgraph.ai"),
            photos
        ))
    conn.commit()

# --- Clean & Deduplicate helper ---

def deduplicate_profiles():
    """Cleans up duplicate user profiles by email, name, or avatar, and eliminates phantom clones"""
    conn = get_connection()
    cur = conn.cursor()
    
    # 1. Purge legacy phantom clone profiles p16 through p99
    cur.execute("""
    DELETE FROM profiles 
    WHERE id LIKE 'p%' 
      AND CAST(SUBSTR(id, 2) AS INTEGER) > 15
    """)
    cur.execute("""
    DELETE FROM swipes 
    WHERE (target_id LIKE 'p%' AND CAST(SUBSTR(target_id, 2) AS INTEGER) > 15)
       OR (liker_id LIKE 'p%' AND CAST(SUBSTR(liker_id, 2) AS INTEGER) > 15)
    """)
    cur.execute("""
    DELETE FROM matches 
    WHERE (user_a LIKE 'p%' AND CAST(SUBSTR(user_a, 2) AS INTEGER) > 15)
       OR (user_b LIKE 'p%' AND CAST(SUBSTR(user_b, 2) AS INTEGER) > 15)
    """)

    # 2. Re-seed baseline if missing
    cur.execute("SELECT id FROM profiles WHERE id = 'p1'")
    if not cur.fetchone():
        seed_profiles(conn)
    else:
        # Remove duplicate non-seed users with matching emails
        cur.execute("""
        DELETE FROM profiles WHERE id NOT IN (
            SELECT MIN(id) FROM profiles GROUP BY LOWER(TRIM(email))
        ) AND id LIKE 'user_%'
        """)
        # Remove duplicate non-seed users with matching avatars
        cur.execute("""
        DELETE FROM profiles WHERE id NOT IN (
            SELECT MIN(id) FROM profiles GROUP BY avatar
        ) AND id LIKE 'user_%'
        """)
    conn.commit()
    conn.close()

# --- Public API helpers ---

def get_all_profiles():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM profiles ORDER BY created_at ASC")
    rows = cur.fetchall()
    conn.close()

    profiles = []
    for r in rows:
        photos_val = r["photos"] if "photos" in r.keys() and r["photos"] else "[]"
        try:
            photos_list = json.loads(photos_val)
        except Exception:
            photos_list = []
        if not photos_list and r["avatar"]:
            photos_list = [r["avatar"]]

        profiles.append({
            "id": r["id"],
            "name": r["name"],
            "age": r["age"],
            "gender": r["gender"],
            "interested_in": json.loads(r["interested_in"]) if r["interested_in"] else ["Female"],
            "bio": r["bio"] or "",
            "lifestyle_traits": json.loads(r["lifestyle_traits"]) if r["lifestyle_traits"] else [],
            "interests": json.loads(r["interests"]) if r["interests"] else [],
            "vector_10d": json.loads(r["vector_10d"]) if r["vector_10d"] else [0.5]*10,
            "mutual_connections": json.loads(r["mutual_connections"]) if r["mutual_connections"] else [],
            "readiness_stage": r["readiness_stage"] or "Core Values",
            "location": r["location"] or "Bengaluru, India",
            "avatar": r["avatar"] or "",
            "email": r["email"] or "",
            "photos": photos_list
        })
    return profiles

def get_profile_by_id(profile_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM profiles WHERE id = ?", (profile_id,))
    r = cur.fetchone()
    conn.close()
    if not r:
        return None
    photos_val = r["photos"] if "photos" in r.keys() and r["photos"] else "[]"
    try:
        photos_list = json.loads(photos_val)
    except Exception:
        photos_list = []
    if not photos_list and r["avatar"]:
        photos_list = [r["avatar"]]

    return {
        "id": r["id"],
        "name": r["name"],
        "age": r["age"],
        "gender": r["gender"],
        "interested_in": json.loads(r["interested_in"]) if r["interested_in"] else ["Female"],
        "bio": r["bio"] or "",
        "lifestyle_traits": json.loads(r["lifestyle_traits"]) if r["lifestyle_traits"] else [],
        "interests": json.loads(r["interests"]) if r["interests"] else [],
        "vector_10d": json.loads(r["vector_10d"]) if r["vector_10d"] else [0.5]*10,
        "mutual_connections": json.loads(r["mutual_connections"]) if r["mutual_connections"] else [],
        "readiness_stage": r["readiness_stage"] or "Core Values",
        "location": r["location"] or "Bengaluru, India",
        "avatar": r["avatar"] or "",
        "email": r["email"] or "",
        "photos": photos_list
    }

def get_profile_by_email(email):
    if not email:
        return None
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM profiles WHERE LOWER(TRIM(email)) = LOWER(TRIM(?)) ORDER BY created_at ASC LIMIT 1", (email,))
    r = cur.fetchone()
    conn.close()
    if not r:
        return None
    return get_profile_by_id(r["id"])

def insert_or_update_profile(profile):
    conn = get_connection()
    cur = conn.cursor()
    photos = json.dumps(profile.get("photos", [profile.get("avatar", "")]))
    cur.execute("""
    INSERT OR REPLACE INTO profiles 
    (id, name, age, gender, interested_in, bio, lifestyle_traits, interests, vector_10d, mutual_connections, readiness_stage, location, avatar, email, photos)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        profile["id"],
        profile["name"],
        profile["age"],
        profile["gender"],
        json.dumps(profile.get("interested_in", ["Female"])),
        profile.get("bio", ""),
        json.dumps(profile.get("lifestyle_traits", [])),
        json.dumps(profile.get("interests", [])),
        json.dumps(profile.get("vector_10d", [0.5]*10)),
        json.dumps(profile.get("mutual_connections", [])),
        profile.get("readiness_stage", "Core Values"),
        profile.get("location", "Bengaluru, India"),
        profile.get("avatar", ""),
        profile.get("email", ""),
        photos
    ))
    conn.commit()
    conn.close()

def update_user_profile(user_id, name=None, bio=None, location=None, avatar=None, photos=None, vector_10d=None, age=None, gender=None):
    profile = get_profile_by_id(user_id)
    if not profile:
        return None
    if name is not None:
        profile["name"] = name
    if bio is not None:
        profile["bio"] = bio
    if location is not None:
        profile["location"] = location
    if avatar is not None:
        profile["avatar"] = avatar
    if photos is not None:
        profile["photos"] = photos
        if photos and not profile.get("avatar"):
            profile["avatar"] = photos[0]
    if vector_10d is not None and len(vector_10d) == 10:
        profile["vector_10d"] = [float(v) for v in vector_10d]
    if age is not None:
        profile["age"] = int(age)
    if gender is not None:
        profile["gender"] = gender
    insert_or_update_profile(profile)
    return get_profile_by_id(user_id)

def record_swipe_in_db(liker_id, target_id, action):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    INSERT OR REPLACE INTO swipes (liker_id, target_id, action)
    VALUES (?, ?, ?)
    """, (liker_id, target_id, action))
    conn.commit()
    conn.close()

def get_user_swiped_ids(liker_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT target_id FROM swipes WHERE liker_id = ?", (liker_id,))
    rows = cur.fetchall()
    conn.close()
    return {r["target_id"] for r in rows}

def record_match_in_db(user_a, user_b, match_score):
    conn = get_connection()
    cur = conn.cursor()
    u1, u2 = (user_a, user_b) if user_a < user_b else (user_b, user_a)
    cur.execute("""
    INSERT OR IGNORE INTO matches (user_a, user_b, match_score)
    VALUES (?, ?, ?)
    """, (u1, u2, match_score))
    conn.commit()
    conn.close()

def get_matches_for_user(user_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    SELECT * FROM matches WHERE user_a = ? OR user_b = ?
    ORDER BY created_at DESC
    """, (user_id, user_id))
    rows = cur.fetchall()
    conn.close()
    
    matches = []
    for r in rows:
        other_id = r["user_b"] if r["user_a"] == user_id else r["user_a"]
        other_profile = get_profile_by_id(other_id)
        if other_profile:
            matches.append({
                "match_id": r["id"],
                "partner": other_profile,
                "match_score": r["match_score"],
                "created_at": r["created_at"]
            })
    return matches

def save_message(sender_id, receiver_id, text):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    INSERT INTO messages (sender_id, receiver_id, text)
    VALUES (?, ?, ?)
    """, (sender_id, receiver_id, text))
    conn.commit()
    msg_id = cur.lastrowid
    cur.execute("SELECT * FROM messages WHERE id = ?", (msg_id,))
    msg = dict(cur.fetchone())
    conn.close()
    return msg

def get_conversation(user_1, user_2):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    SELECT * FROM messages 
    WHERE (sender_id = ? AND receiver_id = ?) 
       OR (sender_id = ? AND receiver_id = ?)
    ORDER BY created_at ASC
    """, (user_1, user_2, user_2, user_1))
    rows = cur.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def get_recent_conversations_list(user_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    SELECT DISTINCT
        CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END as partner_id
    FROM messages
    WHERE sender_id = ? OR receiver_id = ?
    """, (user_id, user_id, user_id))
    partners = cur.fetchall()
    
    result = []
    for p in partners:
        pid = p["partner_id"]
        partner_profile = get_profile_by_id(pid)
        if not partner_profile:
            continue
        cur.execute("""
        SELECT * FROM messages 
        WHERE (sender_id = ? AND receiver_id = ?) 
           OR (sender_id = ? AND receiver_id = ?)
        ORDER BY created_at DESC LIMIT 1
        """, (user_id, pid, pid, user_id))
        last_msg = cur.fetchone()
        result.append({
            "partner": partner_profile,
            "last_message": dict(last_msg) if last_msg else None
        })
    conn.close()
    return result

# --- Posts helpers ---

def create_post(user_id, content, image_url=""):
    user = get_profile_by_id(user_id)
    user_name = user["name"] if user else "Explorer"
    user_avatar = user["avatar"] if user else ""
    
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
    INSERT INTO posts (user_id, user_name, user_avatar, content, image_url)
    VALUES (?, ?, ?, ?, ?)
    """, (user_id, user_name, user_avatar, content, image_url))
    conn.commit()
    post_id = cur.lastrowid
    cur.execute("SELECT * FROM posts WHERE id = ?", (post_id,))
    post = dict(cur.fetchone())
    conn.close()
    return post

def get_all_posts():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM posts ORDER BY created_at DESC")
    rows = cur.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def like_post(post_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?", (post_id,))
    conn.commit()
    cur.execute("SELECT * FROM posts WHERE id = ?", (post_id,))
    r = cur.fetchone()
    conn.close()
    return dict(r) if r else None

# Initialize tables immediately
init_db()
deduplicate_profiles()
