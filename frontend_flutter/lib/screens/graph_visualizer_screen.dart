import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dating_profile.dart';
import '../services/api_service.dart';

class GraphVisualizerScreen extends StatefulWidget {
  const GraphVisualizerScreen({super.key});

  @override
  State<GraphVisualizerScreen> createState() => _GraphVisualizerScreenState();
}

class _GraphVisualizerScreenState extends State<GraphVisualizerScreen> {
  String _activeTab = 'MST'; // 'MST' or 'TOPOLOGICAL'
  MstResult? _mstResult;
  Map<String, dynamic>? _topoResult;
  bool _isLoading = true;
  String _mstAlgorithm = 'kruskal';

  @override
  void initState() {
    super.initState();
    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    setState(() => _isLoading = true);
    if (_activeTab == 'MST') {
      final res = await ApiService.getMst(algo: _mstAlgorithm);
      setState(() {
        _mstResult = res;
        _isLoading = false;
      });
    } else {
      final res = await ApiService.getTopologicalSort();
      setState(() {
        _topoResult = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Graph Engine & Topology",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _activeTab == 'MST' ? "CO2: Minimum Spanning Tree Backbone" : "CO2/CO3: Milestone Topological DAG",
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _tabButton("MST Backbone", 'MST'),
                        _tabButton("Readiness DAG", 'TOPOLOGICAL'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content based on tab
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4458)))
                    : (_activeTab == 'MST' ? _buildMstView() : _buildTopologicalView()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        if (_activeTab != tabKey) {
          setState(() => _activeTab = tabKey);
          _loadGraphData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4458) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMstView() {
    if (_mstResult == null) {
      return const Center(child: Text("Failed to load MST data", style: TextStyle(color: Colors.white60)));
    }

    final res = _mstResult!;

    return Column(
      children: [
        // Metric Cards Row
        Row(
          children: [
            _metricCard("Friction Cost", res.totalCost.toStringAsFixed(2), Colors.cyanAccent),
            const SizedBox(width: 8),
            _metricCard("Edges Pruned", "${res.edgesPruned} (${res.prunePercentage}%)", Colors.greenAccent),
            const SizedBox(width: 8),
            _metricCard("Runtime", "${res.executionTimeMs} ms", Colors.amberAccent),
          ],
        ),
        const SizedBox(height: 12),

        // Algorithm Selector & Step counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Kruskal's (DSU)"),
                  selected: _mstAlgorithm == 'kruskal',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _mstAlgorithm = 'kruskal');
                      _loadGraphData();
                    }
                  },
                  selectedColor: const Color(0xFFFF4458),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Prim's (Min-Heap)"),
                  selected: _mstAlgorithm == 'prim',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _mstAlgorithm = 'prim');
                      _loadGraphData();
                    }
                  },
                  selectedColor: const Color(0xFFFF4458),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
            Text(
              "${res.steps.length} Steps Logged",
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Custom Canvas Graphic
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: MstGraphPainter(mstEdges: res.mstEdges),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(width: 12, height: 3, color: const Color(0xFF00F0FF)),
                          const SizedBox(width: 6),
                          const Text("Core Compatibility Backbone", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Algorithmic execution log
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141926),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STEP TRACE & CYCLE PRUNING LOG",
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: min(res.steps.length, 25),
                    itemBuilder: (ctx, idx) {
                      final step = res.steps[idx];
                      final isAdded = step['action'] == 'ADDED';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAdded ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "#${step['step']} ${step['edge'] ?? step['node']}",
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              step['action'] ?? '',
                              style: TextStyle(
                                color: isAdded ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopologicalView() {
    if (_topoResult == null) {
      return const Center(child: Text("Failed to load Topological data", style: TextStyle(color: Colors.white60)));
    }

    final order = List<String>.from(_topoResult!['topological_order'] ?? []);
    final cohorts = _topoResult!['stage_cohorts'] as Map<String, dynamic>? ?? {};

    return ListView(
      children: [
        // DAG Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141926),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.greenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Valid Directed Acyclic Graph (DAG)",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      "Kahn's BFS In-degree sort resolved milestone prerequisites with 0 cycles.",
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          "STRATIFIED RELATIONSHIP PROGRESSION TIERS:",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 10),

        // Stepper-style milestone badges
        ...order.asMap().entries.map((entry) {
          final idx = entry.key;
          final stage = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFF4458),
                  child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(stage, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),
        const Text(
          "PROFILE COHORTS BY ALIGNED STAGE:",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 10),

        ...cohorts.entries.map((c) {
          final stageName = c.key;
          final List list = c.value as List;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141926),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stageName, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("${list.length} Profiles", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map((p) {
                    return Chip(
                      avatar: CircleAvatar(backgroundImage: NetworkImage(p['avatar'])),
                      label: Text("${p['name']}, ${p['age']}", style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: const Color(0xFF1E293B),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141926),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for 2D Spanning Graph
class MstGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> mstEdges;

  MstGraphPainter({required this.mstEdges});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.42;

    // Fixed synthetic positions in circle
    const int totalNodes = 14;
    final Map<String, Offset> nodePositions = {};
    for (int i = 0; i < totalNodes; i++) {
      final angle = (2 * pi * i) / totalNodes;
      final pos = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      nodePositions["p${i + 1}"] = pos;
    }

    final edgePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw MST Edges
    for (var edge in mstEdges) {
      final u = edge['source'];
      final v = edge['target'];
      if (nodePositions.containsKey(u) && nodePositions.containsKey(v)) {
        canvas.drawLine(nodePositions[u]!, nodePositions[v]!, edgePaint);
      }
    }

    // Draw Nodes
    final nodePaint = Paint()
      ..color = const Color(0xFFFF4458)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    nodePositions.forEach((id, pos) {
      canvas.drawCircle(pos, 8, nodePaint);
      canvas.drawCircle(pos, 8, borderPaint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
