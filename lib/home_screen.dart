import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'browse_screen.dart';
import 'matches_screen.dart';

final supabase = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadMatches = 0;

  late final List<Widget> _screens;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = [
      const BrowseScreen(),
      const MatchesScreen(),
      const EditProfileScreen(),
    ];
    _titles = ['Discover', 'Matches', 'Profile'];

    _loadUserProfile();
    _checkUnreadMatches();
    _setupRealtimeListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await _loadUserProfile();
    await _checkUnreadMatches();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _userProfile = response;
        _isLoading = false;
      });

      if (response == null) {
        await _createInitialProfile(user);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createInitialProfile(User user) async {
    try {
      final String username =
          user.email?.split('@').first ?? 'user_${user.id.substring(0, 6)}';
      await supabase.from('profiles').insert({
        'id': user.id,
        'username': username,
        'full_name': '',
        'age': null,
        'bio': '',
        'interests': [],
        'photos': [],
      });
      debugPrint('Initial profile created for ${user.id}');
    } catch (e) {
      debugPrint('Error creating profile$e');
    }
  }

  Future<void> _checkUnreadMatches() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('matches')
          .select('id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}');

      setState(() {
        _unreadMatches = response.length;
      });
    } catch (e) {
      debugPrint('Error checking matches: $e');
    }
  }

  void _setupRealtimeListeners() {
    supabase.from('matches').stream(primaryKey: ['id']).listen((matches) {
      if (mounted) {
        setState(() {
          _unreadMatches = matches.length;
        });
      }
    });
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await supabase.auth.signOut();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.pink),
              SizedBox(height: 16),
              Text('Loading your profile...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _signOut, child: const Text('Sign Out')),
              ],
            ),
          ),
        ),
      );
    }

    final bool isProfileComplete =
        _userProfile != null &&
        _userProfile!['full_name'] != null &&
        _userProfile!['full_name'].isNotEmpty;

    if (!isProfileComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Complete Your Profile'),
          automaticallyImplyLeading: false,
        ),
        body: EditProfileScreen(forceCompletion: true),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_titles[_selectedIndex]),
            if (_selectedIndex == 1 && _unreadMatches > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _unreadMatches.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        actions: [
          if (_userProfile != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, color: Colors.pink, size: 20),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  setState(() => _selectedIndex = 2);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(_userProfile!['full_name'] ?? 'Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
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
                const Icon(Icons.favorite_outline),
                if (_unreadMatches > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadMatches > 9 ? '9+' : _unreadMatches.toString(),
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
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite),
                if (_unreadMatches > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadMatches > 9 ? '9+' : _unreadMatches.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Matches',
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
