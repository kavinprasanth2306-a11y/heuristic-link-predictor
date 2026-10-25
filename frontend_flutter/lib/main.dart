import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding_wizard_screen.dart';
import 'screens/swipe_deck_screen.dart';
import 'screens/graph_visualizer_screen.dart';
import 'screens/testing_dashboard_screen.dart';
import 'screens/viva_prep_screen.dart';

void main() {
  runApp(const CupidGraphApp());
}

class CupidGraphApp extends StatelessWidget {
  const CupidGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CupidGraph | AI Matchmaking Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFFFF4458),
        fontFamily: 'Roboto',
      ),
      home: const MainGatekeeper(),
    );
  }
}

class MainGatekeeper extends StatefulWidget {
  const MainGatekeeper({super.key});

  @override
  State<MainGatekeeper> createState() => _MainGatekeeperState();
}

class _MainGatekeeperState extends State<MainGatekeeper> {
  bool _isOnboarded = false;

  @override
  Widget build(BuildContext context) {
    if (!_isOnboarded) {
      return OnboardingWizardScreen(
        onOnboardingComplete: () {
          setState(() {
            _isOnboarded = true;
          });
        },
      );
    }
    return const MainShellScreen();
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  bool _hasCheckedUpdate = false;

  final List<Widget> _screens = const [
    SwipeDeckScreen(),
    GraphVisualizerScreen(),
    TestingDashboardScreen(),
    VivaPrepScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedUpdate) {
        _hasCheckedUpdate = true;
        _runUpdateCheck();
      }
    });
  }

  Future<void> _runUpdateCheck() async {
    final updateInfo = await ApiService.checkAppUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.system_update, color: Color(0xFFFF4458), size: 28),
            SizedBox(width: 10),
            Text(
              "Update Available",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4458).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "v${updateInfo['latestVersion']} (Build ${ApiService.currentVersionCode} ? Latest)",
                style: const TextStyle(color: Color(0xFFFF4458), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              updateInfo['releaseNotes'] ?? "Exciting new AI algorithm enhancements & stability updates.",
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              "Direct OTA Download from Flask Micro Backend.",
              style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4458),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final launched = await ApiService.openApkDownload();
              if (!launched && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Could not open browser. Please check backend connection."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text("Install Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF4458),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Swipe Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hub),
              label: 'Graph Engine',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Test Suite (4M)',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'CO & Viva (8M)',
            ),
          ],
        ),
      ),
    );
  }
}
