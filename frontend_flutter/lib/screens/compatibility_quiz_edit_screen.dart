import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CompatibilityQuizEditScreen extends StatefulWidget {
  final List<double> currentVector;

  const CompatibilityQuizEditScreen({super.key, required this.currentVector});

  @override
  State<CompatibilityQuizEditScreen> createState() => _CompatibilityQuizEditScreenState();
}

class _CompatibilityQuizEditScreenState extends State<CompatibilityQuizEditScreen> {
  late List<double> _vector10d;
  bool _isSaving = false;

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
    _vector10d = List<double>.from(widget.currentVector);
    while (_vector10d.length < 10) {
      _vector10d.add(0.5);
    }
  }

  Future<void> _handleSaveQuiz() async {
    setState(() => _isSaving = true);
    final ok = await ApiService.updateProfile(vector10d: _vector10d);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("10-D Compatibility Vector Updated! Matching algorithm recalibrated."),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, _vector10d);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update vector. Check backend connection."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Edit Compatibility Questions",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _handleSaveQuiz,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3366)))
                  : const Icon(Icons.check, color: Color(0xFFFF3366)),
              label: const Text("Save", style: TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (ctx, i) {
          final q = _questions[i];
          final isSlider = q['isSlider'] == true;
          final currentVal = _vector10d[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        q['title'],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${(currentVal * 100).toInt()}%",
                        style: const TextStyle(color: Color(0xFFFF3366), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  q['desc'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),

                if (isSlider) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(q['minLabel'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text(q['maxLabel'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                  Slider(
                    value: currentVal.clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFFFF3366),
                    inactiveColor: const Color(0xFFF1F5F9),
                    onChanged: (val) {
                      setState(() {
                        _vector10d[i] = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                ] else ...[
                  Column(
                    children: (q['options'] as List).map<Widget>((opt) {
                      final double optVal = opt['val'];
                      final isSelected = (currentVal - optVal).abs() < 0.08;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _vector10d[i] = optVal;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF3366) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 18,
                                color: isSelected ? const Color(0xFFFF3366) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  opt['label'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
