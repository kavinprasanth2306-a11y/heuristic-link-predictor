import 'package:flutter/material.dart';
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
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SwipeDeckScreen(),
    GraphVisualizerScreen(),
    TestingDashboardScreen(),
    VivaPrepScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
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
