import 'package:flutter/material.dart';
import '../main.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Get all matches for current user
      final matchesResponse = await supabase
          .from('matches')
          .select('*')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId')
          .eq('is_active', true)
          .order('last_message_at', ascending: false);

      List<Map<String, dynamic>> matches = [];

      for (var match in matchesResponse) {
        // Get the other user's profile
        final otherUserId = match['user1_id'] == _currentUserId
            ? match['user2_id']
            : match['user1_id'];

        final profileResponse = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', otherUserId)
            .single();

        // Get last message
        final messagesResponse = await supabase
            .from('messages')
            .select('content, created_at')
            .eq('match_id', match['id'])
            .order('created_at', ascending: false)
            .limit(1);

        matches.add({
          'match_id': match['id'],
          'profile': profileResponse,
          'last_message': messagesResponse.isNotEmpty ? messagesResponse[0]['content'] : null,
          'last_message_at': match['last_message_at'],
        });
      }

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading matches: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 80, color: Colors.pink.shade200),
                      const SizedBox(height: 24),
                      const Text(
                        'No matches yet',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start swiping to find someone to chat with',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final profile = match['profile'] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.pink.shade100,
                          child: const Icon(Icons.person, color: Colors.pink, size: 35),
                        ),
                        title: Text(
                          profile['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          match['last_message'] ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                matchId: match['match_id'],
                                otherUserProfile: profile,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
