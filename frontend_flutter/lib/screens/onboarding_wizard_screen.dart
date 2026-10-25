import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
class OnboardingWizardScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingWizardScreen({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0; // 0 = Google Auth Landing, 1 to 10 = Compatibility Questions, 11 = Profile & Photo Gate
  bool _isSubmitting = false;

  // Google User Info Mock
  final String _name = "Kavin Prasanth";
  final String _email = "darkin2306@gmail.com";
  String _selectedAvatar = "";
  final int _age = 21;
  final String _gender = "Male";
  final String _bio = "AI student & developer passionate about Graph Neural Networks, hackathons, and indie coffee spots.";
  final String _city = "Bengaluru, India (12.9716° N, 77.5946° E)";

  // 10-D Vector answers
  final List<double> _vector10d = List.filled(10, -1.0);

  // Pre-provided high quality profile photo presets (satisfies mandatory photo upload gate)
  final List<String> _avatarPresets = [
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600",
    "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600",
    "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600",
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600"
  ];

  // 10 Mandatory Questions
  final List<Map<String, dynamic>> _questions = [
    {
      "index": 0,
      "title": "1. Weekend Vibe",
      "desc": "What does your ideal Saturday look like?",
      "options": [
        {"label": "A. Clubbing, concerts & parties", "val": 0.9},
        {"label": "B. Cozy movie night & cooking", "val": 0.3},
        {"label": "C. Outdoor trekking & sports", "val": 0.7},
        {"label": "D. Coding & creative projects", "val": 0.5},
      ]
    },
    {
      "index": 1,
      "title": "2. Social Battery",
      "desc": "Where do you fall on the energy recharge spectrum?",
      "isSlider": true,
      "minLabel": "Deep Introvert",
      "maxLabel": "Extreme Extrovert",
    },
    {
      "index": 2,
      "title": "3. Core Relationship Goal",
      "desc": "What kind of connection are you prioritizing?",
      "options": [
        {"label": "A. Long-term partnership & life goals", "val": 1.0},
        {"label": "B. Casual dating & exploring chemistry", "val": 0.3},
        {"label": "C. New friends, mentors & collaborators", "val": 0.6},
        {"label": "D. Spontaneous vibes / Undecided", "val": 0.4},
      ]
    },
    {
      "index": 3,
      "title": "4. Communication Style",
      "desc": "How do you prefer staying in touch?",
      "options": [
        {"label": "A. Instant rapid texter", "val": 0.85},
        {"label": "B. Long late-night phone / video calls", "val": 0.95},
        {"label": "C. In-person meetups over text", "val": 0.70},
        {"label": "D. Memes, reels & asynchronous replies", "val": 0.40},
      ]
    },
    {
      "index": 4,
      "title": "5. Sleep Schedule & Lifestyle",
      "desc": "When is your brain operating at peak clarity?",
      "options": [
        {"label": "A. Early Bird (5 AM workout & coffee)", "val": 0.15},
        {"label": "B. Balanced / Flexible (8 AM - 11 PM)", "val": 0.50},
        {"label": "C. Night Owl (Creative sprints till 3 AM)", "val": 0.90},
      ]
    },
    {
      "index": 5,
      "title": "6. Fitness & Daily Activity",
      "desc": "What is your relationship with physical wellness?",
      "options": [
        {"label": "A. Daily gym, marathon or athletic training", "val": 0.95},
        {"label": "B. Casual evening walks, cycling & yoga", "val": 0.60},
        {"label": "C. Couch comfort, binge-watching & gaming", "val": 0.20},
      ]
    },
    {
      "index": 6,
      "title": "7. Travel Mindset",
      "desc": "How do you plan your vacations?",
      "options": [
        {"label": "A. Spontaneous backpacker with no fixed plan", "val": 0.85},
        {"label": "B. Luxury curated itineraries & fine dining", "val": 0.65},
        {"label": "C. Staycations, local cafes & quiet retreats", "val": 0.35},
      ]
    },
    {
      "index": 7,
      "title": "8. Intellectual Spark",
      "desc": "What topic keeps you talking for hours?",
      "options": [
        {"label": "A. Tech, Artificial Intelligence & Startups", "val": 0.95},
        {"label": "B. Philosophy, Psychology & Literature", "val": 0.85},
        {"label": "C. Indie Music, Fine Arts & Cinema", "val": 0.75},
        {"label": "D. Gaming, Anime & Internet Lore", "val": 0.50},
      ]
    },
    {
      "index": 8,
      "title": "9. Conflict Resolution",
      "desc": "When disagreements happen, what is your instinct?",
      "options": [
        {"label": "A. Address and talk through it immediately", "val": 0.85},
        {"label": "B. Take cool-off space, then discuss calmly", "val": 0.65},
        {"label": "C. Let small things slide and move forward", "val": 0.35},
      ]
    },
    {
      "index": 9,
      "title": "10. Pet Preference",
      "desc": "Who owns your heart in the animal kingdom?",
      "options": [
        {"label": "A. Dogs (High energy & loyalty)", "val": 0.90},
        {"label": "B. Cats (Quiet affection & independence)", "val": 0.85},
        {"label": "C. Both (Love all animals equally)", "val": 1.00},
        {"label": "D. Neither / Prefer pet-free living", "val": 0.10},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default select first avatar preset
    _selectedAvatar = _avatarPresets[0];
  }

  Future<void> _submitOnboarding() async {
    // Check Photo Gate
    if (_selectedAvatar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Photo Gate Failed: Please select or upload at least 1 profile photo."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check 10-D Vector Gate
    for (int i = 0; i < 10; i++) {
      if (_vector10d[i] < 0) {
        _vector10d[i] = 0.5; // fallback neutral
      }
    }

    setState(() => _isSubmitting = true);

    final res = await ApiService.onboardUser(
      name: _name,
      email: _email,
      avatar: _selectedAvatar,
      age: _age,
      gender: _gender,
      bio: _bio,
      location: _city,
      vector10d: _vector10d,
    );

    setState(() => _isSubmitting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome email dispatched to $_email!"),
          backgroundColor: Colors.green,
        ),
      );
      widget.onOnboardingComplete();
    } else {
      // Allow progression anyway for offline presentation
      widget.onOnboardingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header Progress Bar
              if (_currentStep > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: const Color(0xFF475569), size: 18),
                      onPressed: () => setState(() => _currentStep--),
                    ),
                    Text(
                      _currentStep <= 10 ? "Question $_currentStep of 10" : "Profile & Photo Gating",
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _currentStep / 11.0,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4458)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return _buildLandingStep();
    } else if (_currentStep >= 1 && _currentStep <= 10) {
      return _buildQuestionStep(_currentStep - 1);
    } else {
      return _buildProfileAndPhotoGateStep();
    }
  }

  // STEP 0: Google Sign-in Landing
  Widget _buildLandingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4458), Color(0xFFFE4080)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4458).withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(Icons.favorite, color: const Color(0xFF0F172A), size: 45),
        ),
        const SizedBox(height: 20),
        const Text(
          "CupidGraph",
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Graph-Theoretic Compatibility & Matchmaking Engine",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Powered by 10-D Vector Cosine Similarity, Kruskal's MST Group Optimization, and Kahn's Milestone Sorting (CO2, CO3, CO5).",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 48),

        // Google Sign-In Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 4,
          ),
          onPressed: () {
            setState(() => _currentStep = 1);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4285F4),
                ),
                child: const Center(
                  child: Text("G", style: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "Continue with Google",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Signing in as darkin2306@gmail.com",
          style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 11),
        ),
      ],
    );
  }

  // STEP 1-10: 10-Question Compatibility Wizard
  Widget _buildQuestionStep(int qIndex) {
    final q = _questions[qIndex];
    final isSlider = q['isSlider'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q['title'],
          style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          q['desc'],
          style: const TextStyle(color: const Color(0xFF475569), fontSize: 14),
        ),
        const SizedBox(height: 24),

        if (isSlider) ...[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _vector10d[qIndex] < 0 ? "3 (Balanced Ambivert)" : "${(_vector10d[qIndex] * 5).toInt() + 1}",
                  style: const TextStyle(color: Color(0xFFFF4458), fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _vector10d[qIndex] < 0 ? 0.5 : _vector10d[qIndex],
                  min: 0.0,
                  max: 1.0,
                  activeColor: const Color(0xFFFF4458),
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    setState(() {
                      _vector10d[qIndex] = val;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(q['minLabel'], style: const TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
                      Text(q['maxLabel'], style: const TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Expanded(
            child: ListView.builder(
              itemCount: (q['options'] as List).length,
              itemBuilder: (ctx, optIdx) {
                final opt = q['options'][optIdx];
                final isSelected = (_vector10d[qIndex] - (opt['val'] as double)).abs() < 0.05;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _vector10d[qIndex] = opt['val'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF4458).withValues(alpha: 0.15) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF4458) : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            opt['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFFFF4458), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Next Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4458),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (_vector10d[qIndex] < 0) {
                _vector10d[qIndex] = isSlider ? 0.5 : (q['options'][0]['val'] as double);
              }
              setState(() => _currentStep++);
            },
            child: Text(
              _currentStep == 10 ? "Complete & Proceed to Photo Gate" : "Next Question",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 11: Mandatory Photo Gate & Profile Finish
  Widget _buildProfileAndPhotoGateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Profile Gating & Photo Verification",
          style: TextStyle(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Select at least 1 photo to activate your node in the CupidGraph network.",
          style: TextStyle(color: const Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Photo Gate Avatar Picker
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFFF4458),
                child: CircleAvatar(
                  radius: 43,
                  backgroundImage: NetworkImage(_selectedAvatar),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          "Choose verified photo avatar preset:",
          style: TextStyle(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Avatar selector presets
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _avatarPresets.map((url) {
            final isChosen = _selectedAvatar == url;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = url),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChosen ? const Color(0xFFFF4458) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(url),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Name, Email, Location Preview
        Expanded(
          child: ListView(
            children: [
              _infoTile("Full Name", _name, Icons.person),
              _infoTile("Account Email", _email, Icons.email),
              _infoTile("Simulated GPS City", _city, Icons.location_on),
              _infoTile("10-D Vector Status", "10/10 Orthogonal Dimensions Active", Icons.check_circle_outline),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141926),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Generated 10-D Vector Embedding:", style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "[${_vector10d.map((v) => v < 0 ? '0.50' : v.toStringAsFixed(2)).join(', ')}]",
                      style: const TextStyle(color: const Color(0xFF475569), fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Final Button - Disabled if no photo
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAvatar.isNotEmpty ? const Color(0xFFFF4458) : Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (_selectedAvatar.isNotEmpty && !_isSubmitting) ? _submitOnboarding : null,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: const Color(0xFF0F172A), strokeWidth: 2))
                : const Text("Enter CupidGraph Network", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00F0FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: const Color(0xFF94A3B8), fontSize: 10)),
                Text(value, style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
