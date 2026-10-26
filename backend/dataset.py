"""
CupidGraph Realistic Dating & Compatibility Dataset
30 Curated Student & Young Professional Dating Profiles with True 10-D Orthogonal Feature Vectors
Attributes: id, name, age, gender, interested_in, bio, lifestyle_traits, interests,
vector_10d, mutual_connections, readiness_stage, location, avatar
"""

import copy


INITIAL_PROFILES = [
    {
        "id": "p1",
        "name": "Aarav Sharma",
        "age": 22,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "AI Researcher & coffee enthusiast. Looking for someone who gets excited about deep conversations, late-night hackathons, and weekend treks.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Gym", "Career-Driven", "Non-Smoker"],
        "interests": ["AI & Robotics", "Indie Music", "Filter Coffee", "Trekking", "Sci-Fi Movies"],
        "vector_10d": [0.8, 0.3, 0.9, 0.7, 0.9, 0.8, 0.8, 1.0, 0.7, 0.9],
        "mutual_connections": ["p2", "p3", "p5", "p8", "p12"],
        "readiness_stage": "Core Values",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=600&q=80"
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
        "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p3",
        "name": "Rohan Verma",
        "age": 23,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Full-stack engineer & weekend cyclist. Let's debate whether tabs or spaces win, or just find the best street tacos in town.",
        "lifestyle_traits": ["Extrovert", "Early-Bird", "Gym", "Foodie", "Social-Drinker"],
        "interests": ["Cycling", "Street Food", "Indie Music", "Startups", "Board Games"],
        "vector_10d": [0.6, 0.9, 0.6, 0.8, 0.2, 0.9, 0.8, 0.85, 0.85, 0.7],
        "mutual_connections": ["p1", "p2", "p4", "p6", "p9"],
        "readiness_stage": "Lifestyle Compatibility",
        "location": "HSR Layout, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80"
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
        "readiness_stage": "Lifestyle Compatibility",
        "location": "Whitefield, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80"
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
        "readiness_stage": "Long-Term Commitment",
        "location": "Jayanagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=600&q=80"
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
        "readiness_stage": "Long-Term Commitment",
        "location": "Lavelle Road, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p7",
        "name": "Ishita Sen",
        "age": 21,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Robotics student & anime binge-watcher. Teach me your favorite board game or show me your favorite stargazing spot.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Creative", "Gamer", "Pet-Lover"],
        "interests": ["Anime", "Board Games", "Robotics", "Stargazing", "Indie Music"],
        "vector_10d": [0.85, 0.55, 0.5, 0.8, 0.95, 0.45, 0.7, 0.85, 0.65, 0.95],
        "mutual_connections": ["p2", "p8", "p10", "p14", "p18"],
        "readiness_stage": "Icebreaker",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p8",
        "name": "Devansh Patel",
        "age": 21,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Competitive programmer & anime fan. Looking for cozy vibes, spontaneous movie nights, and someone to laugh at bad math jokes with.",
        "lifestyle_traits": ["Introvert", "Night-Owl", "Gamer", "Analytical", "Non-Smoker"],
        "interests": ["Anime", "Board Games", "Algorithms", "Sci-Fi Movies", "Stargazing"],
        "vector_10d": [0.85, 0.25, 0.6, 0.65, 0.95, 0.4, 0.6, 0.9, 0.6, 0.7],
        "mutual_connections": ["p1", "p5", "p7", "p11", "p19"],
        "readiness_stage": "Icebreaker",
        "location": "BTM Layout, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p9",
        "name": "Diya Banerjee",
        "age": 22,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "UI/UX Designer & ceramics hobbyist. I fall for good typography, aesthetic cafe corners, and deep soulful playlists.",
        "lifestyle_traits": ["Extrovert", "Night-Owl", "Creative", "Social-Drinker", "Foodie"],
        "interests": ["UI Design", "Filter Coffee", "Indie Music", "Art Galleries", "Ceramics"],
        "vector_10d": [0.75, 0.8, 0.7, 0.85, 0.8, 0.5, 0.8, 0.75, 0.75, 0.85],
        "mutual_connections": ["p3", "p6", "p10", "p12", "p20"],
        "readiness_stage": "Lifestyle Compatibility",
        "location": "Indiranagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p10",
        "name": "Kabir Das",
        "age": 22,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Backend wizard & amateur chef. If you love fresh sourdough, Italian pasta, and indie gigs, we are going to get along great.",
        "lifestyle_traits": ["Ambivert", "Night-Owl", "Foodie", "Creative", "Spontaneous"],
        "interests": ["Cooking", "Indie Music", "Filter Coffee", "Ceramics", "Street Food"],
        "vector_10d": [0.7, 0.6, 0.75, 0.7, 0.8, 0.65, 0.75, 0.7, 0.8, 0.9],
        "mutual_connections": ["p4", "p7", "p9", "p13", "p21"],
        "readiness_stage": "Lifestyle Compatibility",
        "location": "HSR Layout, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p11",
        "name": "Priya Nair",
        "age": 23,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Machine Learning engineer & classical dancer. Looking for emotional maturity, reciprocal effort, and genuine compatibility.",
        "lifestyle_traits": ["Introvert", "Early-Bird", "Disciplined", "Mindful", "Vegetarian"],
        "interests": ["Classical Dance", "AI & Robotics", "Filter Coffee", "Yoga", "Literature"],
        "vector_10d": [0.5, 0.35, 0.9, 0.6, 0.2, 0.75, 0.6, 0.9, 0.85, 0.75],
        "mutual_connections": ["p1", "p5", "p8", "p12", "p22"],
        "readiness_stage": "Core Values",
        "location": "Malleswaram, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p12",
        "name": "Aditya Hegde",
        "age": 23,
        "gender": "Male",
        "interested_in": ["Female"],
        "bio": "Computer Vision specialist & travel photographer. Let's explore scenic misty viewpoints and discover hidden local dessert spots.",
        "lifestyle_traits": ["Ambivert", "Early-Bird", "Adventurous", "Gym", "Non-Smoker"],
        "interests": ["Photography", "Trekking", "Travel", "Filter Coffee", "AI & Robotics"],
        "vector_10d": [0.8, 0.65, 0.8, 0.7, 0.3, 0.85, 0.95, 0.85, 0.75, 0.8],
        "mutual_connections": ["p1", "p9", "p11", "p13", "p23"],
        "readiness_stage": "Core Values",
        "location": "Sadashivanagar, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=600&q=80"
    },
    {
        "id": "p13",
        "name": "Riya Singhania",
        "age": 24,
        "gender": "Female",
        "interested_in": ["Male"],
        "bio": "Blockchain Auditor & scuba diver. Looking for an ambitious partner who values trust, deep loyalty, and shared world adventures.",
        "lifestyle_traits": ["Extrovert", "Early-Bird", "Adventurous", "Career-Driven", "Fitness"],
        "interests": ["Scuba Diving", "Travel", "Startups", "Wine Tasting", "Fine Dining"],
        "vector_10d": [0.65, 0.9, 0.9, 0.8, 0.25, 0.9, 0.9, 0.85, 0.85, 0.6],
        "mutual_connections": ["p6", "p10", "p12", "p14", "p24"],
        "readiness_stage": "Long-Term Commitment",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80"
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
        "mutual_connections": ["p7", "p13", "p15", "p17", "p25"],
        "readiness_stage": "Lifestyle Compatibility",
        "location": "Bellandur, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=600&q=80"
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
        "mutual_connections": ["p2", "p14", "p16", "p18", "p26"],
        "readiness_stage": "Core Values",
        "location": "Koramangala, Bengaluru",
        "avatar": "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=600&q=80"
    }
]

# Directed Relationship Readiness & Value Progression DAG edges
READINESS_DAG_EDGES = [
    ("Icebreaker / Quiz", "Lifestyle Alignment", "Communication & Habits"),
    ("Lifestyle Alignment", "Emotional Vulnerability & Trust", "Mutual Reciprocity"),
    ("Emotional Vulnerability & Trust", "Core Values & Belief Alignment", "Value Compatibility"),
    ("Core Values & Belief Alignment", "Commitment Readiness", "Life Vision & Long-Term")
]

def get_dating_dataset():
    """Returns deep copies of CupidGraph profiles and readiness DAG"""
    return {
        "profiles": copy.deepcopy(INITIAL_PROFILES),
        "readiness_dag": copy.deepcopy(READINESS_DAG_EDGES)
    }
