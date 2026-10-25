import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isCheckingUpdate = false;
  bool _isResetting = false;

  final List<String> _lifestyleTraits = [
    'Coffee Enthusiast',
    'AI Researcher',
    'Weekend Trekker',
    'Mindful',
    'Late Night Coder'
  ];

  final List<String> _compatibilityTraits = [
    'Openness: 88%',
    'Neuroticism: Low',
    'Conscientiousness: 92%',
    'Extraversion: 74%',
    'Agreeableness: 85%'
  ];

  Future<void> _triggerManualUpdateCheck() async {
    setState(() => _isCheckingUpdate = true);
    final updateInfo = await ApiService.checkAppUpdate();
    setState(() => _isCheckingUpdate = false);

    if (!mounted) return;

    if (updateInfo != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.system_update, color: Color(0xFFFF3366), size: 28),
              SizedBox(width: 10),
              Text('Update Available', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version: v' + (updateInfo['latestVersion'] ?? '1.0.1').toString(),
                style: const TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                updateInfo['releaseNotes'] ?? 'Latest performance improvements and bug fixes.',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ApiService.openApkDownload();
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download APK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your CupidGraph app is up to date! (v1.0.1)'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleResetDatastore() async {
    setState(() => _isResetting = true);
    final success = await ApiService.resetSession();
    setState(() => _isResetting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Datastore & Graph reset successfully!' : 'Reset failed. Check connection.'),
        backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ApiService.activeUserAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.person, size: 80, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.85),
                          const Color(0xFFF8FAFC),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFFF3366),
                          child: CircleAvatar(
                            radius: 37,
                            backgroundImage: NetworkImage(ApiService.activeUserAvatar),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ApiService.activeUserName,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: Color(0xFF0284C7), size: 20),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ID: ' + ApiService.activeUserId + ' ? Bengaluru, IN',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vector & Gating Status Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.hub, color: Color(0xFFFF3366), size: 22),
                            SizedBox(width: 8),
                            Text(
                              '10-D Vector Status: Embedded',
                              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Spacer(),
                            Chip(
                              label: Text('CO2 ? CO3', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                              backgroundColor: Color(0xFFF1F5F9),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _compatibilityTraits.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.2)),
                              ),
                              child: Text(t, style: const TextStyle(color: Color(0xFFBE123C), fontSize: 11, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lifestyle & Passions
                  const Text('Lifestyle & Passions', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _lifestyleTraits.map((t) {
                      return Chip(
                        label: Text(t, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        avatar: const Icon(Icons.tag, size: 14, color: Color(0xFFFF3366)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // System & Backend Controls
                  const Text('App & Backend System', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cloud_sync, color: Color(0xFF0284C7)),
                          title: const Text('Backend Server URL', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(ApiService.baseUrl, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          trailing: const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListTile(
                          leading: const Icon(Icons.system_update_alt, color: Color(0xFFFF3366)),
                          title: const Text('Check for OTA Updates', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Current: v1.0.1 (Build 2)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          trailing: _isCheckingUpdate
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3366)))
                              : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                          onTap: _isCheckingUpdate ? null : _triggerManualUpdateCheck,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListTile(
                          leading: const Icon(Icons.refresh, color: Color(0xFFD97706)),
                          title: const Text('Reset Graph Session', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Clear swipes, likes & re-initialize datastore', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          trailing: _isResetting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)))
                              : const Icon(Icons.arrow_forward_ios, color: Color(0xFF94A3B8), size: 14),
                          onTap: _isResetting ? null : _handleResetDatastore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
