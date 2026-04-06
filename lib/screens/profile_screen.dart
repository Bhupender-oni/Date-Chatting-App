import 'package:flutter/material.dart';
import '../main.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _loadProfile();
  }

  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final response = await supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId!)
          .single();

      if (!mounted) return;

      setState(() {
        _profile = response;
        _nameController.text = _safeString(response['full_name'], '');
        _ageController.text = _safeString(response['age'], '');
        _bioController.text = _safeString(response['bio'], '');
        _locationController.text = _safeString(response['location'], '');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('user_profiles').update({
        'full_name': _nameController.text,
        'age': int.tryParse(_ageController.text),
        'bio': _bioController.text,
        'location': _locationController.text,
      }).eq('id', userId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );

      setState(() => _isEditing = false);
      _loadProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pink.shade100,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _safeString(_profile?['full_name'], 'User'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_profile?['age'] != null)
                          Text(
                            '${_profile!['age']} years old',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isEditing) ...[
                    // Edit mode
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Changes'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadProfile();
                      },
                      child: const Text('Cancel'),
                    ),
                  ] else ...[
                    // View mode
                    _buildProfileInfo('Age', _safeString(_profile?['age'], 'N/A')),
                    const SizedBox(height: 16),
                    _buildProfileInfo(
                      'Location',
                      _safeString(_profile?['location'], 'Not set'),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileInfo(
                      'Bio',
                      _safeString(_profile?['bio'], 'No bio yet'),
                    ),
                    if (_profile?['interests'] != null &&
                        (_profile!['interests'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Interests',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: (_profile!['interests'] as List)
                            .cast<String>()
                            .map(
                              (interest) => Chip(
                                label: Text(interest),
                                backgroundColor: Colors.pink.shade50,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],

                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
