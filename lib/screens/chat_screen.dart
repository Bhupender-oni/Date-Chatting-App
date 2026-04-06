import 'package:flutter/material.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> otherUserProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _loadMessages();
    _setupRealtimeListener();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('match_id', widget.matchId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _messages = response.cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      // Mark messages as read
      await supabase
          .from('messages')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('match_id', widget.matchId)
          .neq('sender_id', _currentUserId!);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListener() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', widget.matchId)
        .listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages.cast<Map<String, dynamic>>();
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await supabase.from('messages').insert({
        'match_id': widget.matchId,
        'sender_id': _currentUserId,
        'content': content,
        'is_read': false,
      });

      // Update match last_message_at
      await supabase
          .from('matches')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', widget.matchId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserProfile['full_name'] ?? 'Chat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (widget.otherUserProfile['age'] != null)
              Text(
                '${widget.otherUserProfile['age']} years old',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[_messages.length - 1 - index];
                          final isMe = message['sender_id'] == _currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.pink : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (isMe && message['is_read'])
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Read',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    backgroundColor: Colors.pink,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
