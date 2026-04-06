import 'package:flutter/material.dart';
import '../main.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _currentUserId;
  final RangeValues _ageRange = const RangeValues(18, 50);

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Get all active profiles except current user and blocked users
      final response = await supabase
          .from('user_profiles')
          .select('*')
          .eq('is_active', true)
          .neq('id', _currentUserId!)
          .gte('age', _ageRange.start.toInt())
          .lte('age', _ageRange.end.toInt())
          .order('created_at', ascending: false);

      // Get liked/rejected profiles
      final likedResponse = await supabase
          .from('likes')
          .select('liked_id')
          .eq('liker_id', _currentUserId!);

      final likedIds = likedResponse.map((l) => l['liked_id']).toList();

      // Filter out already swiped profiles
      final filteredProfiles = (response as List)
          .where((p) => !likedIds.contains(p['id']))
          .toList();

      if (!mounted) return;
      setState(() {
        _profiles = filteredProfiles.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike(bool isSuper) async {
    if (_profiles.isEmpty) return;

    final likedProfile = _profiles[_currentIndex];

    try {
      // Insert like
      await supabase.from('likes').insert({
        'liker_id': _currentUserId,
        'liked_id': likedProfile['id'],
        'status': isSuper ? 'super_liked' : 'liked',
      });

      // Move to next profile
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _profiles.length - 1) {
          _currentIndex++;
        } else {
          _profiles = [];
        }
      });
    } catch (e) {
      debugPrint('Error liking profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handlePass() async {
    if (_profiles.isEmpty) return;

    try {
      final passedProfile = _profiles[_currentIndex];

      // Record rejection
      await supabase.from('likes').insert({
        'liker_id': _currentUserId,
        'liked_id': passedProfile['id'],
        'status': 'rejected',
      });

      // Move to next profile
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _profiles.length - 1) {
          _currentIndex++;
        } else {
          _profiles = [];
        }
      });
    } catch (e) {
      debugPrint('Error passing profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.pink.shade200),
                      const SizedBox(height: 24),
                      const Text(
                        'No more profiles',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Check back later for more matches',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _loadProfiles,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : _buildProfileCard(),
    );
  }

  Widget _buildProfileCard() {
    final profile = _profiles[_currentIndex];

    return Stack(
      children: [
        // Card
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.grey.shade300,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),

                // Info area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${profile['full_name'] ?? 'Unknown'}, ${profile['age'] ?? '?'}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (profile['location'] != null)
                        Text(
                          profile['location'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (profile['bio'] != null && profile['bio'].isNotEmpty)
                        Text(
                          profile['bio'],
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      if (profile['interests'] != null &&
                          (profile['interests'] as List).isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: (profile['interests'] as List)
                              .cast<String>()
                              .take(5)
                              .map(
                                (interest) => Chip(
                                  label: Text(interest),
                                  backgroundColor: Colors.pink.shade50,
                                  labelStyle: const TextStyle(color: Colors.pink),
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

        // Action buttons
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
                elevation: 4,
                child: const Icon(Icons.close, color: Colors.red, size: 32),
              ),
              FloatingActionButton(
                onPressed: () => _handleLike(true),
                backgroundColor: Colors.orange,
                elevation: 4,
                child: const Icon(Icons.star, color: Colors.white, size: 32),
              ),
              FloatingActionButton(
                onPressed: () => _handleLike(false),
                backgroundColor: Colors.pink,
                elevation: 4,
                child: const Icon(Icons.favorite, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),

        // Progress indicator
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _profiles.length,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          ),
        ),
      ],
    );
  }
}
