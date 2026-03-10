import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      //Get all profiles except the current user's profile
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .neq('id', _currentUserId!)
          .order('created_at');

      //Get profiles that user has liked
      final likedResponse = await Supabase.instance.client
          .from('likes')
          .select('liked_id')
          .eq('liker_id', _currentUserId!);

      //Extract liked profile IDs
      final likedIds = likedResponse.map((l) => l['liked_id']).toList();

      setState(() {
        _profiles = response
            .where((p) => !likedIds.contains(p['id']))
            .toList()
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error Loading profiles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    if (_profiles.isEmpty) return;

    final likedProfile = _profiles[_currentIndex];

    try {
      await Supabase.instance.client.from('likes').insert({
        'liker_id': _currentUserId,
        'liked_id': likedProfile['id'],
      });

      //Check if it's a match
      final matchCheck = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('liker_id', likedProfile['id'])
          .eq('liked_id', _currentUserId!)
          .maybeSingle();

      if (matchCheck != null) {
        _showMatchDialog(likedProfile);
      }

      //Move to next profile
      setState(() {
        if (_currentIndex < _profiles.length - 1) {
          _currentIndex++;
        } else {
          _profiles = [];
        }
      });
    } catch (e) {
      debugPrint('Error liking profile: $e');
    }
  }

  void _handlePass() {
    setState(() {
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex++;
      } else {
        _profiles = [];
      }
    });
  }

  void _showMatchDialog(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("It's a Match!"),
        content: Text('You and ${profile['full_name']} liked each other!'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Browsing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              //Switch to matches tab
              //You'll need to pass this up to HomeScreen
            },
            child: const Text('View Match'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No more profiles to show!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text('Check back later'),
          ],
        ),
      );
    }

    final currentProfile = _profiles[_currentIndex];
    final photos = List<String>.from(currentProfile['photos'] ?? []);
    final hasPhoto = photos.isNotEmpty;

    return Stack(
      children: [
        //Profile Card
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Photo area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.grey.shade300,
                      image: hasPhoto
                          ? const DecorationImage(
                              image: NetworkImage(
                                'https://via.placeholder.com/400',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),

                //Info area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currentProfile['full_name'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentProfile['age']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentProfile['bio'] ?? 'No bio yet',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 8),
                      if (currentProfile['interests'] != null)
                        Wrap(
                          spacing: 8,
                          children: (currentProfile['interests'] as List)
                              .map(
                                (interest) => Chip(
                                  label: Text(interest),
                                  backgroundColor: Colors.pink.shade50,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        //Action buttons
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: _handlePass,
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: Colors.red, size: 40),
              ),
              FloatingActionButton(
                onPressed: _handleLike,
                backgroundColor: Colors.pink,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        //Progress Indicator
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _profiles.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
        ),
      ],
    );
  }
}
