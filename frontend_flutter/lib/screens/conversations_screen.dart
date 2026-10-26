import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];
  List<dynamic> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getConversations();
    setState(() {
      _conversations = data['conversations'] ?? [];
      _matches = data['matches'] ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Messages & Matches",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3366)))
          : RefreshIndicator(
              color: const Color(0xFFFF3366),
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // Matches Horizontal Story Ribbon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Matches",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          "${_matches.length}",
                          style: const TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_matches.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.favorite_border, color: Color(0xFFFF3366), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Swipe right in the feed to discover mutual matches!",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 105,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _matches.length,
                        itemBuilder: (ctx, i) {
                          final match = _matches[i];
                          final partner = match['partner'] ?? {};
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => ChatScreen(
                                    partnerId: partner['id'] ?? '',
                                    partnerName: partner['name'] ?? '',
                                    partnerAvatar: partner['avatar'] ?? '',
                                  ),
                                ),
                              ).then((_) => _loadData());
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 76,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFFF3366), Color(0xFF6366F1)],
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(
                                            partner['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF3366),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.favorite, size: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    partner['name']?.split(' ')?.first ?? 'Match',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),

                  // Recent Conversations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      "Conversations",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_conversations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: const [
                          Icon(Icons.forum_outlined, size: 48, color: Color(0xFF475569)),
                          SizedBox(height: 12),
                          Text(
                            "No active conversations yet.",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Click on any match or candidate to start chatting!",
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._conversations.map((conv) {
                      final partner = conv['partner'] ?? {};
                      final lastMsg = conv['last_message'] ?? {};
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ChatScreen(
                                partnerId: partner['id'] ?? '',
                                partnerName: partner['name'] ?? '',
                                partnerAvatar: partner['avatar'] ?? '',
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(
                            partner['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
                          ),
                        ),
                        title: Text(
                          partner['name'] ?? 'User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          lastMsg['text'] ?? 'Tap to chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
