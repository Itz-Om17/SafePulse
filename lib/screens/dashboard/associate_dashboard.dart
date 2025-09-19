import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AssociateDashboard extends StatefulWidget {
  const AssociateDashboard({super.key});

  @override
  State<AssociateDashboard> createState() => _AssociateDashboardState();
}

class _AssociateDashboardState extends State<AssociateDashboard> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const TalukaHeadRegistrationPage(),
    const PostsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associate Dashboard'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Taluka Head Registration Page
class TalukaHeadRegistrationPage extends StatefulWidget {
  const TalukaHeadRegistrationPage({super.key});

  @override
  State<TalukaHeadRegistrationPage> createState() => _TalukaHeadRegistrationPageState();
}

class _TalukaHeadRegistrationPageState extends State<TalukaHeadRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _districtController = TextEditingController();
  final _talukaController = TextEditingController();
  final _villageController = TextEditingController();
  final _assignedAreaController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  bool _isLoading = false;
  String? _selectedFile;

  // Configuration for backend URL
  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register Taluka Heads',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // CSV/Excel Upload Section
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Registration (CSV/Excel)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload a CSV or Excel file with taluka head details. The file should contain columns: name, email, phone, password, district, taluka, village, assigned_area, additional_info.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select File'),
                      ),
                      const SizedBox(width: 10),
                      if (_selectedFile != null)
                        Expanded(
                          child: Text(
                            _selectedFile!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_selectedFile != null)
                    ElevatedButton(
                      onPressed: _uploadBulkTalukaHeads,
                      child: const Text('Process File'),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          
          // Manual Registration Section
          const Text(
            'Manual Registration for Taluka Heads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Basic Information
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Basic Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                // Location Information
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Location Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _talukaController,
                  decoration: const InputDecoration(
                    labelText: 'Taluka *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a taluka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                // Additional Information
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _assignedAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Area',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Information',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerTalukaHead,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register Taluka Head'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadBulkTalukaHeads() async {
    // Implement CSV/Excel processing and bulk registration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk registration feature will be implemented here')),
    );
  }

  Future<void> _registerTalukaHead() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/taluka-heads/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
            "password": _passwordController.text.trim(),
            "registeredBy": "Associate", // You might want to use the actual user ID
            "district": _districtController.text.trim(),
            "taluka": _talukaController.text.trim(),
            "village": _villageController.text.trim(),
            "assignedArea": _assignedAreaController.text.trim(),
            "additionalInfo": _additionalInfoController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Taluka Head registered successfully!')),
          );
          // Clear form
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _districtController.clear();
          _talukaController.clear();
          _villageController.clear();
          _assignedAreaController.clear();
          _additionalInfoController.clear();
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Registration failed')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _districtController.dispose();
    _talukaController.dispose();
    _villageController.dispose();
    _assignedAreaController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}

// Posts Page (same as before)
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Posts Management',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Profile Page (same as before)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Load user data
    _loadUserData();
  }

  void _loadUserData() {
    // Mock data - replace with actual API call
    _nameController.text = 'Associate Name';
    _emailController.text = 'associate@example.com';
    _phoneController.text = '1234567890';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green,
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
                    // Save changes
                    _saveProfile();
                    setState(() {
                      _isEditing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    // Cancel editing
                    _loadUserData();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // Implement API call to update profile
    print('Saving profile: ${_nameController.text}, ${_emailController.text}, ${_phoneController.text}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}