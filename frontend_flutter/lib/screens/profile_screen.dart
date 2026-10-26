import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'compatibility_quiz_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCheckingUpdate = false;
  bool _isResetting = false;
  bool _isLoadingPosts = false;
  List<Map<String, dynamic>> _posts = [];
  List<String> _userPhotos = [];
  final TextEditingController _postTextController = TextEditingController();

  String _currentName = ApiService.activeUserName;
  String _bio = '';
  String _location = 'Bengaluru, IN';
  int _age = 18;
  List<double> _userVector = List.filled(10, 0.5);

  final List<String> _defaultPresets = [
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600",
    "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600",
    "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600",
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600",
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600"
  ];

  final List<String> _lifestyleTraits = [
    'Coffee Enthusiast',
    'AI Researcher',
    'Weekend Trekker',
    'Mindful',
    'Late Night Coder'
  ];

  List<String> get _compatibilityTraits {
    if (_userVector.length < 10) return ['Openness: 88%', 'Conscientiousness: 92%', 'Extraversion: 74%'];
    final social = (_userVector[1] * 100).toInt();
    final deepTalk = (_userVector[7] * 100).toInt();
    final spontaneous = (_userVector[5] * 100).toInt();
    final openness = (_userVector[8] * 100).toInt();
    final ambition = (_userVector[4] * 100).toInt();
    return [
      'Social Battery: $social%',
      'Deep Talks: $deepTalk%',
      'Spontaneity: $spontaneous%',
      'Openness: $openness%',
      'Ambition: $ambition%',
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentName = ApiService.activeUserName;
    _userPhotos = [ApiService.activeUserAvatar];
    _fetchProfileAndPosts();
  }

  Future<void> _fetchProfileAndPosts() async {
    setState(() => _isLoadingPosts = true);
    final profileData = await ApiService.getProfileDetails(ApiService.activeUserId);
    if (profileData != null && profileData['profile'] != null) {
      final p = profileData['profile'];
      final List photos = p['photos'] ?? [];
      if (photos.isNotEmpty) {
        _userPhotos = List<String>.from(photos);
      }
      if (p['name'] != null && p['name'].toString().trim().isNotEmpty) {
        _currentName = p['name'].toString();
      }
      if (p['bio'] != null) {
        _bio = p['bio'].toString();
      }
      if (p['location'] != null && p['location'].toString().trim().isNotEmpty) {
        _location = p['location'].toString();
      }
      if (p['age'] != null) {
        _age = (p['age'] as num).toInt();
      }
      if (p['vector_10d'] != null && p['vector_10d'] is List) {
        _userVector = (p['vector_10d'] as List).map((e) => (e as num).toDouble()).toList();
      }
    }
    final posts = await ApiService.getPosts();
    setState(() {
      _posts = posts;
      _isLoadingPosts = false;
    });
  }

  Future<void> _handleAddPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Photo to Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            const Text("Choose a curated aesthetic portrait or pick from gallery:", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _defaultPresets.length,
                itemBuilder: (c, i) {
                  final url = _defaultPresets[i];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        if (!_userPhotos.contains(url)) {
                          _userPhotos.add(url);
                        }
                      });
                      await ApiService.updateProfile(photos: _userPhotos, avatar: _userPhotos.first);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF3366)),
              title: const Text("Select from Device Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Selected: ${picked.name}. Uploaded to profile!"), backgroundColor: Colors.green),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreatePost() async {
    final text = _postTextController.text.trim();
    if (text.isEmpty) return;
    _postTextController.clear();
    Navigator.pop(context);
    final ok = await ApiService.createPost(text, imageUrl: _userPhotos.isNotEmpty ? _userPhotos.first : ApiService.activeUserAvatar);
    if (ok) {
      _fetchProfileAndPosts();
    }
  }

  void _showNewPostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Color(0xFFFF3366)),
            SizedBox(width: 8),
            Text("Create Status Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: _postTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "What are you working on or feeling excited about today?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3366), foregroundColor: Colors.white),
            onPressed: _handleCreatePost,
            child: const Text("Post"),
          )
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _currentName);
    final bioCtrl = TextEditingController(text: _bio);
    final locationCtrl = TextEditingController(text: _location);
    final ageCtrl = TextEditingController(text: _age.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.edit, color: Color(0xFFFF3366)),
            SizedBox(width: 8),
            Text("Edit Profile Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person, color: Color(0xFFFF3366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  prefixIcon: Icon(Icons.cake, color: Color(0xFFFF3366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: "Location",
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF3366)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  prefixIcon: Icon(Icons.description, color: Color(0xFFFF3366)),
                  hintText: "Tell your matches about your passions and vibe...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newBio = bioCtrl.text.trim();
              final newLocation = locationCtrl.text.trim();
              final newAge = int.tryParse(ageCtrl.text.trim()) ?? _age;

              if (newName.isEmpty) return;
              Navigator.pop(ctx);

              setState(() {
                _currentName = newName;
                _bio = newBio;
                _location = newLocation;
                _age = newAge;
              });

              final ok = await ApiService.updateProfile(
                name: newName,
                bio: newBio,
                location: newLocation,
                age: newAge,
              );

              if (ok) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', newName);
                ApiService.activeUserName = newName;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update profile. Check server."), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditQuiz() async {
    final updatedVector = await Navigator.push<List<double>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CompatibilityQuizEditScreen(currentVector: _userVector),
      ),
    );
    if (updatedVector != null && mounted) {
      setState(() {
        _userVector = updatedVector;
      });
      _fetchProfileAndPosts();
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully"), backgroundColor: Colors.grey),
      );
    }
  }

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
                'Version: v${updateInfo['latestVersion'] ?? '1.0.1'}',
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
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 290,
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
                    errorBuilder: (context, error, stackTrace) => Container(
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
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFFF3366),
                              child: CircleAvatar(
                                radius: 37,
                                backgroundImage: NetworkImage(ApiService.activeUserAvatar),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _handleAddPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF3366),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                ),
                              ),
                            )
                          ],
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
                                      '$_currentName, $_age',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Color(0xFF0284C7), size: 20),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _showEditProfileDialog,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3366).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.edit, size: 14, color: Color(0xFFFF3366)),
                                          SizedBox(width: 4),
                                          Text("Edit", style: TextStyle(color: Color(0xFFFF3366), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ApiService.activeUserEmail} • $_location',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if (_bio.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
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
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF3366),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFFFF3366),
                tabs: const [
                  Tab(icon: Icon(Icons.photo_library), text: "Photos"),
                  Tab(icon: Icon(Icons.dynamic_feed), text: "Posts & Feed"),
                  Tab(icon: Icon(Icons.settings), text: "Profile & Settings"),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: User Photos Gallery
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Profile Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      TextButton.icon(
                        onPressed: _handleAddPhoto,
                        icon: const Icon(Icons.add_photo_alternate, size: 18, color: Color(0xFFFF3366)),
                        label: const Text("Add Photo", style: TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _userPhotos.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _userPhotos.length) {
                        return GestureDetector(
                          onTap: _handleAddPhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Color(0xFFFF3366), size: 28),
                                SizedBox(height: 4),
                                Text("Add", style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_userPhotos[i], fit: BoxFit.cover),
                      );
                    },
                  ),
                ],
              ),
            ),

            // TAB 2: Community Posts & Feed
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("CupidGraph Feed & Updates", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: _showNewPostDialog,
                        icon: const Icon(Icons.post_add, size: 16),
                        label: const Text("New Post"),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingPosts)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFF3366)))
                  else if (_posts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.feed_outlined, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            const Text("No community posts yet.", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text("Share your passions or weekend vibes with matches!", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _showNewPostDialog, child: const Text("Create First Post")),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._posts.map((post) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(post['user_avatar'] ?? ApiService.activeUserAvatar),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Text("Shared to Network", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_border, color: Color(0xFFFF3366), size: 20),
                                  onPressed: () async {
                                    await ApiService.likePost(post['id']);
                                    _fetchProfileAndPosts();
                                  },
                                ),
                                Text("${post['likes_count'] ?? 0} likes", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            // TAB 3: Profile Settings & Backend
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Quick Edit & 10-D Vector Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.hub, color: Color(0xFFFF3366), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  '10-D Compatibility Vector',
                                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your vector is calculated from the 10-question compatibility quiz and dynamically drives AI graph matching:',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3366),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _handleEditQuiz,
                                icon: const Icon(Icons.quiz, size: 18),
                                label: const Text("Edit Quiz Answers (10-D)", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFF3366)),
                                foregroundColor: const Color(0xFFFF3366),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              ),
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text("Edit Details"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
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
                  const Text('App & Backend System', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Sign out of your account on this device', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
