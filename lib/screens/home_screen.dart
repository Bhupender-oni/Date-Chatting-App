import 'package:flutter/material.dart';
import '../main.dart';
import 'discover_screen.dart';
import 'messages_screen.dart';
import 'likes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _unreadMessages = 0;
  int _newLikes = 0;

  late final List<Widget> _screens;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DiscoverScreen(),
      const MessagesScreen(),
      const LikesScreen(),
      const ProfileScreen(),
    ];
    _titles = ['Discover', 'Messages', 'Likes', 'Profile'];

    _loadCounts();
    _setupRealtimeListeners();
  }

  void _loadCounts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get unread messages
      final unreadMessages = await supabase
          .from('messages')
          .select('id')
          .filter('match_id', 'in',
              (await supabase
                  .from('matches')
                  .select('id')
                  .or('user1_id.eq.$userId,user2_id.eq.$userId')
                  .then((m) => m.map((x) => x['id']).toList())))
          .eq('is_read', false)
          .neq('sender_id', userId);

      // Get new likes
      final newLikes = await supabase
          .from('likes')
          .select('id')
          .eq('liked_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _unreadMessages = unreadMessages.length;
          _newLikes = newLikes.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
    }
  }

  void _setupRealtimeListeners() {
    // Listen to new messages
    supabase.from('messages').stream(primaryKey: ['id']).listen((messages) {
      _loadCounts();
    });

    // Listen to new likes
    supabase.from('likes').stream(primaryKey: ['id']).listen((likes) {
      _loadCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                // Filter options
              },
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.message_outlined),
                if (_unreadMessages > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _unreadMessages > 99 ? '99+' : _unreadMessages.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite_outline),
                if (_newLikes > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _newLikes > 99 ? '99+' : _newLikes.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Likes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
