import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final String? talukaHeadTaluka;
  final Function(String)? onTalukaUpdated;
  const ProfilePage({
    super.key, 
    required this.userEmail, 
    required this.talukaHeadTaluka,
    required this.onTalukaUpdated
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _talukaController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;

  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Use the provided taluka value if available
      if (widget.talukaHeadTaluka != null) {
        _talukaController.text = widget.talukaHeadTaluka!;
      }

      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/users/email/${widget.userEmail}'),
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        
        setState(() {
          _nameController.text = userData['data']['name'];
          _emailController.text = userData['data']['email'];
          _phoneController.text = userData['data']['phone'];
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading user data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/users/email/${widget.userEmail}'),
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final userId = userData['data']['id'];

        // Update user data
        await http.put(
          Uri.parse('$baseUrl/api/users/$userId'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
          }),
        );

        // Update taluka if it was changed
        if (widget.onTalukaUpdated != null && 
            _talukaController.text != widget.talukaHeadTaluka) {
          widget.onTalukaUpdated!(_talukaController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen and remove all previous routes
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _talukaController,
            decoration: const InputDecoration(
              labelText: 'Taluka',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!_isEditing)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: const Text('Edit Profile'),
                ),
              if (_isEditing)
                ElevatedButton(
                  onPressed: () {
                    _saveProfile();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Save Changes'),
                ),
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    _loadUserData();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 30),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _talukaController.dispose();
    super.dispose();
  }
}