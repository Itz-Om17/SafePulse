import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String authToken;
  
  const ProfileScreen({
    super.key, 
    required this.userId,
    required this.authToken,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  Map<String, dynamic> roleData = {};
  bool isLoading = true;
  String? error;
  String userRole = '';

  // Replace with your actual backend URL
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Fetch user data
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (userResponse.statusCode == 200) {
        final responseJson = json.decode(userResponse.body);
userData = responseJson['data'];

        
        // Determine user role and fetch role-specific data
        await fetchRoleSpecificData();
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchRoleSpecificData() async {
    try {
      // Try to fetch from each role table to determine user role
      final endpoints = [
        {'role': 'Associate', 'endpoint': 'associates'},
        {'role': 'Taluka Head', 'endpoint': 'taluka-heads'},
        {'role': 'Ground Worker', 'endpoint': 'ground-workers'},
      ];

      for (var roleInfo in endpoints) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/${roleInfo['endpoint']}/user/${widget.userId}'),
            headers: {
              'Authorization': 'Bearer ${widget.authToken}',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
  final responseJson = json.decode(response.body);
  roleData = responseJson['data']; // ✅ store only the "data" object
  userRole = roleInfo['role']!;
  break;
}

        } catch (e) {
          // Continue to next role if this one fails
          continue;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.put(
        Uri.parse('$baseUrl/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        fetchUserProfile(); // Refresh data
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/users/change-password'),
                  headers: {
                    'Authorization': 'Bearer ${widget.authToken}',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'currentPassword': currentPasswordController.text,
                    'newPassword': newPasswordController.text,
                  }),
                );

                Navigator.of(context).pop();

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                } else {
                  final errorData = json.decode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorData['message'] ?? 'Failed to change password')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

Future<void> logout() async {
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
          onPressed: () async {
            try {
              await http.post(
                Uri.parse('$baseUrl/auth/logout'),
                headers: {
                  'Authorization': 'Bearer ${widget.authToken}',
                  'Content-Type': 'application/json',
                },
              );
            } catch (e) {
              // Ignore logout API errors, proceed with local logout
            }

            // Navigate to login screen using named route
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}
  void showEditDialog() {
    final TextEditingController nameController = TextEditingController(text: userData['name']);
    final TextEditingController emailController = TextEditingController(text: userData['email']);
    final TextEditingController phoneController = TextEditingController(text: userData['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userData['name'] = nameController.text;
                userData['email'] = emailController.text;
                userData['phone'] = phoneController.text;
              });
              Navigator.of(context).pop();
              updateProfile();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'),
            ),
            const SizedBox(height: 16),
            Text(
              userData['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${userData['id'] ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (userRole.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  userRole,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(userData['email'] ?? 'N/A'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(userData['phone'] ?? 'N/A'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('District'),
                      subtitle: Text(roleData['district'] ?? 'N/A'),
                    ),
                    if (roleData['taluka'] != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_city),
                        title: const Text('Taluka'),
                        subtitle: Text(roleData['taluka']),
                      ),
                    ],
                    if (roleData['village'] != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.home_work),
                        title: const Text('Village'),
                        subtitle: Text(roleData['village']),
                      ),
                    ],
                    if (roleData['assigned_area'] != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.work),
                        title: const Text('Assigned Area'),
                        subtitle: Text(roleData['assigned_area']),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: showEditDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                ElevatedButton.icon(
                  onPressed: changePassword,
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                ),
                ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}