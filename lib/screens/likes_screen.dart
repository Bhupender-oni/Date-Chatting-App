import 'package:flutter/material.dart';
import '../main.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  List<Map<String, dynamic>> _likes = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Get all likes where current user is liked_id
      final likesResponse = await supabase
          .from('likes')
          .select('liker_id, status, created_at')
          .eq('liked_id', _currentUserId!)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> likes = [];

      for (var like in likesResponse) {
        final profileResponse = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', like['liker_id'])
            .single();

        likes.add({
          'profile': profileResponse,
          'status': like['status'],
          'created_at': like['created_at'],
        });
      }

      if (!mounted) return;
      setState(() {
        _likes = likes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading likes: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likeBkack(String likerId) async {
    try {
      await supabase.from('likes').insert({
        'liker_id': _currentUserId,
        'liked_id': likerId,
        'status': 'liked',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liked! 💕')),
      );

      _loadLikes();
    } catch (e) {
      debugPrint('Error liking back: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _likes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.pink.shade200),
                      const SizedBox(height: 24),
                      const Text(
                        'No likes yet',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start swiping to get liked',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    final like = _likes[index];
                    final profile = like['profile'] as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Photo area
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey.shade300,
                            ),
                            child: Center(
                              child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
                            ),
                          ),

                          // Info overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${profile['full_name'] ?? 'Unknown'}, ${profile['age'] ?? '?'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _likeBkack(profile['id']),
                                          icon: const Icon(Icons.favorite, size: 16),
                                          label: const Text('Like'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Heart badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.pink.shade400,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
