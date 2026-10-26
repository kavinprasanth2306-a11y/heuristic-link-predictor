import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding_wizard_screen.dart';
import 'screens/swipe_deck_screen.dart';
import 'screens/graph_visualizer_screen.dart';
import 'screens/testing_dashboard_screen.dart';
import 'screens/conversations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init note: $e");
  }
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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFFFF3366),
        fontFamily: 'Roboto',
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF3366),
          secondary: Color(0xFF6366F1),
          surface: Colors.white,
          onSurface: Color(0xFF0F172A),
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A)),
          bodyMedium: TextStyle(color: Color(0xFF334155)),
          titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final savedUserId = prefs.getString('user_id');
    final savedName = prefs.getString('user_name');
    final savedEmail = prefs.getString('user_email');
    final savedAvatar = prefs.getString('user_avatar');

    if (isLoggedIn && savedUserId != null && savedUserId.isNotEmpty) {
      ApiService.activeUserId = savedUserId;
      if (savedName != null) ApiService.activeUserName = savedName;
      if (savedEmail != null) ApiService.activeUserEmail = savedEmail;
      if (savedAvatar != null) ApiService.activeUserAvatar = savedAvatar;
      setState(() {
        _isOnboarded = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isOnboarded = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3366)),
        ),
      );
    }

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
    ConversationsScreen(),
    GraphVisualizerScreen(),
    TestingDashboardScreen(),
    ProfileScreen(),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF3366),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hub),
              label: 'Graphs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Tests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
