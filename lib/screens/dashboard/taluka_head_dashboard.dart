import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class TalukaHeadDashboard extends StatefulWidget {
  final String userEmail;
  const TalukaHeadDashboard({super.key, required this.userEmail});

  @override
  State<TalukaHeadDashboard> createState() => _TalukaHeadDashboardState();
}

class _TalukaHeadDashboardState extends State<TalukaHeadDashboard> {
  int _currentIndex = 0;
  String? _talukaHeadTaluka;
  bool _isLoadingUserData = true;

  // Configuration for backend URL
  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _fetchTalukaHeadData();
  }

  Future<void> _fetchTalukaHeadData() async {
    try {
      print('Fetching taluka head data for email: ${widget.userEmail}');
      
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/users/email/${widget.userEmail}'),
      );

      print('User API response: ${userResponse.statusCode}');
      print('User API body: ${userResponse.body}');
      
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final userId = userData['data']['id'];
        print('User ID: $userId');

        // Then get taluka head data
        final talukaHeadResponse = await http.get(
          Uri.parse('$baseUrl/api/taluka-heads/user/$userId'),
        );

        print('Taluka Head API response: ${talukaHeadResponse.statusCode}');
        print('Taluka Head API body: ${talukaHeadResponse.body}');

        if (talukaHeadResponse.statusCode == 200) {
          final talukaHeadData = jsonDecode(talukaHeadResponse.body);
          setState(() {
            _talukaHeadTaluka = talukaHeadData['data']['taluka'];
            _isLoadingUserData = false;
          });
          print('Taluka set to: $_talukaHeadTaluka');
        } else {
          // Handle API error
          print('Taluka head API returned non-200 status');
          _handleLoadingError();
        }
      } else {
        // Handle API error
        print('User API returned non-200 status');
        _handleLoadingError();
      }
    } catch (error) {
      print('Error fetching taluka head data: $error');
      _handleLoadingError();
    }
  }

  void _handleLoadingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load dashboard data. Using default taluka.')),
    );
    setState(() {
      _talukaHeadTaluka = "Default Taluka";
      _isLoadingUserData = false;
    });
  }

  void _updateTaluka(String newTaluka) {
    setState(() {
      _talukaHeadTaluka = newTaluka;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoadingUserData
            ? const Text('Loading...')
            : Text('Taluka Head Dashboard - ${_talukaHeadTaluka ?? "Unknown"}'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentPage(),
      bottomNavigationBar: _isLoadingUserData
          ? null
          : BottomNavigationBar(
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

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return GroundWorkerRegistrationPage(
          talukaHeadTaluka: _talukaHeadTaluka,
          onTalukaUpdated: _updateTaluka,
        );
      case 1:
        return const PostsPage();
      case 2:
        return ProfilePage(
          userEmail: widget.userEmail,
          talukaHeadTaluka: _talukaHeadTaluka,
          onTalukaUpdated: _updateTaluka,
        );
      default:
        return const Center(child: Text('Page not found'));
    }
  }
}

// Ground Worker Registration Page
class GroundWorkerRegistrationPage extends StatefulWidget {
  final String? talukaHeadTaluka;
  final Function(String)? onTalukaUpdated;
  const GroundWorkerRegistrationPage({
    super.key,
    required this.talukaHeadTaluka,
    required this.onTalukaUpdated,
  });

  @override
  State<GroundWorkerRegistrationPage> createState() => _GroundWorkerRegistrationPageState();
}

class _GroundWorkerRegistrationPageState extends State<GroundWorkerRegistrationPage> {
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

  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _updateTalukaField();
  }

  @override
  void didUpdateWidget(covariant GroundWorkerRegistrationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTalukaField();
  }

  void _updateTalukaField() {
    if (widget.talukaHeadTaluka != null && 
        widget.talukaHeadTaluka != _talukaController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _talukaController.text = widget.talukaHeadTaluka!;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure taluka field is always synced during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.talukaHeadTaluka != null && 
          widget.talukaHeadTaluka != _talukaController.text) {
        _talukaController.text = widget.talukaHeadTaluka!;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register Ground Workers for ${_talukaController.text.isNotEmpty ? _talukaController.text : "Your Taluka"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  Text(
                    'Upload a CSV or Excel file with ground worker details for ${_talukaController.text.isNotEmpty ? _talukaController.text : "your taluka"}. The file should contain columns: name, email, phone, password, district, village, assigned_area, additional_info.',
                    style: const TextStyle(color: Colors.grey),
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
                      onPressed: _uploadBulkGroundWorkers,
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
            'Manual Registration',
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
                  decoration: InputDecoration(
                    labelText: 'Taluka *',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Taluka is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a village';
                    }
                    return null;
                  },
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
                  onPressed: _isLoading ? null : _registerGroundWorker,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register Ground Worker'),
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

  Future<void> _uploadBulkGroundWorkers() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk registration will use taluka: ${_talukaController.text}')),
    );
  }

  Future<void> _registerGroundWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/ground-workers/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
            "password": _passwordController.text.trim(),
            "registeredBy": "Taluka Head",
            "district": _districtController.text.trim(),
            "taluka": _talukaController.text.trim(),
            "village": _villageController.text.trim(),
            "assignedArea": _assignedAreaController.text.trim(),
            "additionalInfo": _additionalInfoController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ground Worker registered successfully!')),
          );
          // Clear form
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _districtController.clear();
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

// Posts Page
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