import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      //Get all matches for current user
      final response = await Supabase.instance.client
      .from('matches')
      .select('''
id,
user1_id,
user2_id,
created_at,
profile1:profile!user1_id(*),
profile2:profile!user2_id(*)
''')
.or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId')
.order('created_at',ascending:false);

//Format matches to show the other person
final List<Map<String, dynamic>> formattedMatches = [];

for (var match in response) {
  final otherProfile = match['user1_id'] == _currentUserId
  ?match['profile2']
  :match['profile1'];

  formattedMatches.add({
    'match_id': match['id'],
    'profile': otherProfile,
    'created_at': match['created_at'],
  });
}

setState(() {
  _matches = formattedMatches;
  _isLoading = false;
});

//Set up realtime listener for new matches
Supabase.instance.client
.from('matches')
.stream(primaryKey:['id'])
.listen((newMatches) {
  //Refresh when new match comes in
  _loadMatches();
});

    } catch (e) {
      debugPrint('Error loading matches: $e');
      setState(() =>
        _isLoading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      if(_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if(_matches.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No matches yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Keep swiping to find your match',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final profile = match['profile'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profile['photos'] != null &&
                (profile['photos'] as List).isNotEmpty ? const NetworkImage('https://via.placeholder.com/60')//Replace with actual photo
                :null,
                child: profile['photos'] == null ||
                (profile['photos'] as List).isEmpty
                ? const Icon(Icons.person, size: 30)
                :null,
              ),
              title: Text(
                profile['full_name'] ?? 'Anonymuos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                profile['bio'] ?? 'No bio',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chat, color: Colors.pink),
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    matchId: match['match_id'],
                    otherUser:profile,
                  ),
                ),
              );
        },
      ),
      );
    },
    );
}
}

                 