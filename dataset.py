"""
Dataset Generator & Pre-loaded Realistic University Social Network.
Attributes: id, name, department, year, skills, interests, connections, interaction_weight, influence_rank
"""

import random

# Curated synthetic network of 28 University Students & Tech Mentors
INITIAL_USERS = [
    {
        "id": "u1",
        "name": "Aarav Sharma",
        "department": "Computer Science & Eng",
        "year": "Senior (4th Year)",
        "role": "Lead Student Researcher / Mentor",
        "skills": ["Graph Neural Networks", "Python", "Deep Learning", "PyTorch", "Algorithms"],
        "interests": ["AI Ethics", "Hackathons", "Competitive Coding", "Research Papers"],
        "influence_rank": 95,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Aarav"
    },
    {
        "id": "u2",
        "name": "Priya Nair",
        "department": "Computer Science & Eng",
        "year": "Senior (4th Year)",
        "role": "ML Lead & Teaching Assistant",
        "skills": ["Python", "Machine Learning", "Scikit-Learn", "Data Visualization", "Algorithms"],
        "interests": ["Open Source", "Research Papers", "Women in Tech", "Hackathons"],
        "influence_rank": 92,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Priya"
    },
    {
        "id": "u3",
        "name": "Rohan Verma",
        "department": "Information Technology",
        "year": "Junior (3rd Year)",
        "role": "Full-Stack Web Architect",
        "skills": ["JavaScript", "React", "Node.js", "Flask", "Cloud Deployment"],
        "interests": ["SaaS Building", "Web3", "Hackathons", "System Design"],
        "influence_rank": 85,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Rohan"
    },
    {
        "id": "u4",
        "name": "Ananya Iyer",
        "department": "Artificial Intelligence & Data Science",
        "year": "Junior (3rd Year)",
        "role": "Data Science Associate",
        "skills": ["Python", "Data Visualization", "Machine Learning", "Pandas", "SQL"],
        "interests": ["Predictive Modeling", "Bioinformatics", "Data Journalism"],
        "influence_rank": 82,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Ananya"
    },
    {
        "id": "u5",
        "name": "Vikram Malhotra",
        "department": "Computer Science & Eng",
        "year": "Alumni / Industry Fellow",
        "role": "Senior Distributed Systems Engineer (Mentor)",
        "skills": ["Distributed Systems", "Go", "Kubernetes", "System Design", "Cloud Deployment"],
        "interests": ["Mentorship", "Startups", "Scalability", "Tech Podcasts"],
        "influence_rank": 99,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Vikram"
    },
    {
        "id": "u6",
        "name": "Sneha Kulkarni",
        "department": "Cybersecurity & Forensic",
        "year": "Junior (3rd Year)",
        "role": "SecOps Specialist",
        "skills": ["Network Security", "Ethical Hacking", "Cryptography", "Python", "Linux"],
        "interests": ["CTF Competitions", "Privacy", "Bug Bounties", "Open Source"],
        "influence_rank": 80,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Sneha"
    },
    {
        "id": "u7",
        "name": "Devansh Patel",
        "department": "Computer Science & Eng",
        "year": "Sophomore (2nd Year)",
        "role": "Algorithm Enthusiast",
        "skills": ["C++", "Algorithms", "Competitive Coding", "Data Structures"],
        "interests": ["Competitive Coding", "Math Puzzles", "Game Theory"],
        "influence_rank": 74,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Devansh"
    },
    {
        "id": "u8",
        "name": "Meera Joshi",
        "department": "Artificial Intelligence & Data Science",
        "year": "Senior (4th Year)",
        "role": "NLP Specialist & Mentor",
        "skills": ["NLP", "Transformers", "Python", "Deep Learning", "LLMs"],
        "interests": ["Computational Linguistics", "Research Papers", "AI Ethics"],
        "influence_rank": 90,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Meera"
    },
    {
        "id": "u9",
        "name": "Kabir Das",
        "department": "Information Technology",
        "year": "Sophomore (2nd Year)",
        "role": "Backend Developer",
        "skills": ["Python", "Flask", "SQL", "Docker", "Algorithms"],
        "interests": ["Hackathons", "Microservices", "Open Source"],
        "influence_rank": 70,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Kabir"
    },
    {
        "id": "u10",
        "name": "Ishita Sen",
        "department": "Electronics & Communication",
        "year": "Junior (3rd Year)",
        "role": "Embedded AI & IoT Fellow",
        "skills": ["C++", "Edge AI", "IoT", "Robotics", "Python"],
        "interests": ["Hardware Hacking", "Robotics Club", "Autonomous Systems"],
        "influence_rank": 79,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Ishita"
    },
    {
        "id": "u11",
        "name": "Arjun Reddy",
        "department": "Computer Science & Eng",
        "year": "Freshman (1st Year)",
        "role": "Aspiring AI Developer",
        "skills": ["Python", "Data Structures", "Math"],
        "interests": ["Machine Learning", "Competitive Coding", "Hackathons"],
        "influence_rank": 55,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Arjun"
    },
    {
        "id": "u12",
        "name": "Tanvi Chawla",
        "department": "Artificial Intelligence & Data Science",
        "year": "Freshman (1st Year)",
        "role": "Junior Data Analyst",
        "skills": ["Python", "Data Visualization", "SQL"],
        "interests": ["Data Journalism", "Women in Tech", "AI Ethics"],
        "influence_rank": 52,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Tanvi"
    },
    {
        "id": "u13",
        "name": "Siddharth Rao",
        "department": "Computer Science & Eng",
        "year": "Senior (4th Year)",
        "role": "Cloud DevOps Mentor",
        "skills": ["Kubernetes", "AWS", "Terraform", "System Design", "Cloud Deployment"],
        "interests": ["Cloud Architecture", "DevOps Culture", "Mentorship"],
        "influence_rank": 89,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Siddharth"
    },
    {
        "id": "u14",
        "name": "Diya Banerjee",
        "department": "Information Technology",
        "year": "Sophomore (2nd Year)",
        "role": "UI/UX & Frontend Dev",
        "skills": ["React", "JavaScript", "CSS/Tailwind", "Figma", "UI Design"],
        "interests": ["Design Systems", "Web Accessibility", "Creative Coding"],
        "influence_rank": 72,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Diya"
    },
    {
        "id": "u15",
        "name": "Aditya Hegde",
        "department": "Computer Science & Eng",
        "year": "Junior (3rd Year)",
        "role": "Computer Vision Researcher",
        "skills": ["OpenCV", "PyTorch", "Python", "Deep Learning", "Algorithms"],
        "interests": ["Medical Imaging", "Robotics Club", "Research Papers"],
        "influence_rank": 84,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Aditya"
    },
    {
        "id": "u16",
        "name": "Riya Singhania",
        "department": "Cybersecurity & Forensic",
        "year": "Senior (4th Year)",
        "role": "Blockchain Security Auditor",
        "skills": ["Solidity", "Smart Contracts", "Cryptography", "Network Security"],
        "interests": ["DeFi Security", "Bug Bounties", "Web3"],
        "influence_rank": 88,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Riya"
    },
    {
        "id": "u17",
        "name": "Kunal Ghosh",
        "department": "Electronics & Communication",
        "year": "Senior (4th Year)",
        "role": "Robotics Club President",
        "skills": ["ROS", "C++", "Robotics", "Control Systems", "Edge AI"],
        "interests": ["Autonomous Drones", "Hardware Hacking", "Competitions"],
        "influence_rank": 91,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Kunal"
    },
    {
        "id": "u18",
        "name": "Pooja Deshmukh",
        "department": "Artificial Intelligence & Data Science",
        "year": "Junior (3rd Year)",
        "role": "BI & Analytics Lead",
        "skills": ["Tableau", "PowerBI", "SQL", "Data Visualization", "Python"],
        "interests": ["Business Analytics", "FinTech", "Data Journalism"],
        "influence_rank": 77,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Pooja"
    },
    {
        "id": "u19",
        "name": "Varun Kapoor",
        "department": "Computer Science & Eng",
        "year": "Freshman (1st Year)",
        "role": "Web Dev Explorer",
        "skills": ["HTML", "CSS/Tailwind", "JavaScript", "Python"],
        "interests": ["Hackathons", "Open Source", "Design Systems"],
        "influence_rank": 50,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Varun"
    },
    {
        "id": "u20",
        "name": "Neha Bhatt",
        "department": "Information Technology",
        "year": "Junior (3rd Year)",
        "role": "Agile Scrum Master & Dev",
        "skills": ["Agile", "Jira", "React", "Python", "Cloud Deployment"],
        "interests": ["Product Management", "Tech Leadership", "Startups"],
        "influence_rank": 81,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Neha"
    },
    {
        "id": "u21",
        "name": "Nikhil Agarwal",
        "department": "Computer Science & Eng",
        "year": "Sophomore (2nd Year)",
        "role": "Systems Programmer",
        "skills": ["Rust", "C++", "Linux", "Data Structures", "Algorithms"],
        "interests": ["Kernel Dev", "Compilers", "Competitive Coding"],
        "influence_rank": 75,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Nikhil"
    },
    {
        "id": "u22",
        "name": "Kavya Menon",
        "department": "Artificial Intelligence & Data Science",
        "year": "Senior (4th Year)",
        "role": "Reinforcement Learning Fellow",
        "skills": ["Reinforcement Learning", "Python", "PyTorch", "Deep Learning", "Math"],
        "interests": ["Game AI", "Autonomous Vehicles", "Research Papers"],
        "influence_rank": 87,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Kavya"
    },
    {
        "id": "u23",
        "name": "Tarun Saxena",
        "department": "Cybersecurity & Forensic",
        "year": "Sophomore (2nd Year)",
        "role": "Penetration Tester",
        "skills": ["Ethical Hacking", "Linux", "Bash", "Python", "Network Security"],
        "interests": ["CTF Competitions", "Bug Bounties", "Cyber Defense"],
        "influence_rank": 68,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Tarun"
    },
    {
        "id": "u24",
        "name": "Deepika Nambiar",
        "department": "Computer Science & Eng",
        "year": "Junior (3rd Year)",
        "role": "Mobile App Architect",
        "skills": ["Flutter", "Dart", "Firebase", "React", "Mobile Development"],
        "interests": ["App Incubator", "UI Design", "Startups"],
        "influence_rank": 78,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Deepika"
    },
    {
        "id": "u25",
        "name": "Harsh Vardhan",
        "department": "Information Technology",
        "year": "Senior (4th Year)",
        "role": "Database Reliability Engineer",
        "skills": ["PostgreSQL", "Redis", "Distributed Systems", "SQL", "Python"],
        "interests": ["High-Performance DBs", "System Design", "Cloud Architecture"],
        "influence_rank": 86,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Harsh"
    },
    {
        "id": "u26",
        "name": "Shreya Mukherjee",
        "department": "Artificial Intelligence & Data Science",
        "year": "Sophomore (2nd Year)",
        "role": "Bio-Informatics Data Explorer",
        "skills": ["Python", "Pandas", "Scikit-Learn", "Data Visualization", "Math"],
        "interests": ["Genomics", "Predictive Modeling", "Health Tech"],
        "influence_rank": 71,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Shreya"
    },
    {
        "id": "u27",
        "name": "Gaurav Tiwari",
        "department": "Computer Science & Eng",
        "year": "Junior (3rd Year)",
        "role": "Full-Stack AI Integrator",
        "skills": ["Python", "Flask", "React", "LLMs", "LangChain"],
        "interests": ["Generative AI", "Hackathons", "SaaS Building"],
        "influence_rank": 83,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Gaurav"
    },
    {
        "id": "u28",
        "name": "Zoya Khan",
        "department": "Electronics & Communication",
        "year": "Sophomore (2nd Year)",
        "role": "IoT Smart Systems Builder",
        "skills": ["IoT", "Arduino", "C++", "Python", "MQTT"],
        "interests": ["Smart Cities", "Robotics Club", "Hardware Hacking"],
        "influence_rank": 69,
        "avatar": "https://api.dicebear.com/7.x/bottts/svg?seed=Zoya"
    }
]

# Realistic initial friendship & collaboration connections with interaction strengths (1 to 10)
# Note: For MST, edge weight (cost) is defined as round(10.0 / interaction_strength, 2) or (11 - strength)
INITIAL_CONNECTIONS = [
    # Core Research / AI Group
    ("u1", "u2", 9, "Research Co-authors"),
    ("u1", "u4", 8, "Lab Collaboration"),
    ("u1", "u8", 9, "AI Thesis Cohort"),
    ("u1", "u15", 7, "Computer Vision Project"),
    ("u2", "u4", 8, "Data Science Mentorship"),
    ("u2", "u8", 8, "Paper Peer Review"),
    ("u2", "u22", 7, "RL Research Discussion"),
    ("u4", "u18", 8, "Analytics Project"),
    ("u4", "u26", 7, "Bio-Data Exploration"),
    ("u8", "u22", 8, "Deep Learning Colloquium"),
    ("u8", "u27", 7, "GenAI App Mentoring"),

    # Industry / Systems Mentor Connections (Vikram u5 & Siddharth u13 & Harsh u25)
    ("u5", "u1", 9, "Fellowship Mentorship"),
    ("u5", "u3", 8, "System Design Advising"),
    ("u5", "u13", 10, "Alumni Senior Mentoring"),
    ("u5", "u25", 8, "Distributed Storage Guidance"),
    ("u13", "u3", 7, "DevOps Cloud Setup"),
    ("u13", "u9", 6, "Docker Guidance"),
    ("u13", "u25", 8, "Cluster Management"),
    ("u25", "u9", 7, "Database Indexing Collab"),
    ("u25", "u21", 6, "Low-level I/O Systems"),

    # Web & Full-Stack Hub
    ("u3", "u9", 8, "Web App Hackathon Team"),
    ("u3", "u14", 9, "Frontend/Backend Duo"),
    ("u3", "u20", 7, "Agile Project Sprint"),
    ("u3", "u24", 7, "Cross-Platform API Sync"),
    ("u3", "u27", 8, "AI Web Integration"),
    ("u14", "u19", 8, "UI Design Mentorship"),
    ("u14", "u24", 7, "Design System Sharing"),
    ("u20", "u24", 7, "Project Management"),
    ("u27", "u9", 7, "Flask Microservice"),
    ("u27", "u19", 6, "Junior Web Advice"),

    # Algorithms & Competitive Programming Circle
    ("u7", "u1", 7, "Algorithm Peer Group"),
    ("u7", "u11", 8, "CP Problem Mentorship"),
    ("u7", "u21", 9, "Codeforces Team Partner"),
    ("u11", "u7", 8, "Freshman Tutoring"),
    ("u11", "u19", 6, "Freshman Peer Study"),
    ("u11", "u12", 7, "Batchmates in Math"),
    ("u21", "u6", 6, "Low-level Systems Security"),

    # Cybersecurity Squad
    ("u6", "u16", 9, "CTF Lead & Auditor"),
    ("u6", "u23", 8, "SecOps Peer Collaboration"),
    ("u16", "u23", 7, "Pen-testing Vulnerability"),
    ("u16", "u3", 6, "Smart Contract Web3 App"),

    # Robotics & Embedded IoT
    ("u17", "u10", 9, "Robotics Team Leads"),
    ("u17", "u15", 8, "Vision for Drones Collab"),
    ("u17", "u28", 8, "Autonomous Hardware Lab"),
    ("u10", "u28", 8, "Circuit Design Mentoring"),
    ("u10", "u15", 7, "Edge Neural Net on Robot"),

    # Junior / Freshmen Onboarding
    ("u12", "u4", 8, "Data Analysis Mentorship"),
    ("u12", "u26", 7, "Data Study Group"),
    ("u18", "u26", 6, "BI Dataset Preparation"),
    ("u19", "u14", 7, "Frontend Training")
]

# Directed Mentorship & Dependency relations for DAG (Topological Sort)
# Format: (Mentor / Source, Mentee / Target, Skill/Field)
INITIAL_MENTORSHIPS = [
    # Top Level Mentors (Vikram, Siddharth, Aarav, Priya, Kunal)
    ("u5", "u13", "Distributed Architecture"),
    ("u5", "u3", "Enterprise Scale"),
    ("u5", "u1", "AI Research Foundations"),
    ("u1", "u7", "Graph Algorithms"),
    ("u1", "u8", "Deep Learning Research"),
    ("u1", "u15", "Computer Vision Theory"),
    ("u2", "u4", "Applied Machine Learning"),
    ("u2", "u12", "Python & Data Science"),
    ("u8", "u27", "LLM Prompting & Fine-Tuning"),
    ("u8", "u22", "Reinforcement Learning"),
    ("u13", "u9", "Docker & Kubernetes"),
    ("u13", "u25", "Cloud SRE Best Practices"),
    ("u3", "u14", "Component Architecture"),
    ("u3", "u19", "Full-Stack Development"),
    ("u3", "u24", "State Management & REST"),
    ("u7", "u11", "Competitive Programming & DSA"),
    ("u7", "u21", "Advanced Dynamic Programming"),
    ("u6", "u23", "Network Exploitation Defense"),
    ("u16", "u6", "Cryptographic Security Proofs"),
    ("u17", "u10", "Robotics Operating System (ROS)"),
    ("u17", "u28", "Sensor Fusion & Actuators"),
    ("u4", "u18", "Statistical Analysis"),
    ("u4", "u26", "Bio-Data Processing"),
    ("u14", "u19", "UI/UX & CSS Mastery")
]

def get_initial_dataset():
    """Returns deep copies of users, connections, and mentorships"""
    import copy
    return {
        "users": copy.deepcopy(INITIAL_USERS),
        "connections": copy.deepcopy(INITIAL_CONNECTIONS),
        "mentorships": copy.deepcopy(INITIAL_MENTORSHIPS)
    }
